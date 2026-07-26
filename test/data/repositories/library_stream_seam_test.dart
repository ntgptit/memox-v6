import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_language_pair_repository.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/delete_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/move_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/rename_deck_usecase.dart';

/// WBS 5.2.4A — the Library's reads are reactive, and every mutation is what
/// makes them re-emit.
///
/// `WatchLibraryUseCase` promises "creates/renames/moves re-emit through the
/// repository stream". A mutation that writes correctly but does not wake the
/// stream leaves the Library showing yesterday's list, and looks exactly like
/// one that works — the same silent-no-op shape as `int-24`. The unit tests
/// exercise each mutation and the Library viewmodel separately; this drives
/// them into a live subscription.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftDeckRepository decks;
  late CreateDeckUseCase create;

  final now = DateTime.utc(2026, 7, 27, 9);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    decks = DriftDeckRepository(database, _FixedClock(now));
    create = CreateDeckUseCase(
      decks: decks,
      pairs: DriftLanguagePairRepository(database),
      idGenerator: _SeqIds('deck'),
      clock: _FixedClock(now),
    );
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
  });

  tearDown(() => database.close());

  /// A live subscription that records what the Library would render.
  ///
  /// Deliberately not `stream.first` per step: that cancels its listener and
  /// the next call re-subscribes, which makes drift re-run the query — so the
  /// test would pass even if the mutation never woke the stream, which is the
  /// only thing worth proving here. One listener stays open for the whole
  /// test and the emissions are counted.
  _Recorder<List<DeckSummary>> record(Stream<List<DeckSummary>> stream) {
    final recorder = _Recorder<List<DeckSummary>>(stream);
    addTearDown(recorder.dispose);
    return recorder;
  }

  test('creating a deck reaches the live root list', () async {
    final roots = record(decks.watchRootSummaries('lp1'));
    expect(await roots.next(), isEmpty);

    await create(name: 'Grammar', languagePairId: 'lp1');

    expect((await roots.next()).single.deck.name, 'Grammar');
  });

  test('renaming a deck re-emits the new name', () async {
    final deck = await create(name: 'Grammer', languagePairId: 'lp1');
    final roots = record(decks.watchRootSummaries('lp1'));
    expect((await roots.next()).single.deck.name, 'Grammer');

    await RenameDeckUseCase(
      decks: decks,
      clock: _FixedClock(now),
    ).call(deckId: deck.id, name: 'Grammar');

    expect((await roots.next()).single.deck.name, 'Grammar');
  });

  // A move changes two lists at once: the deck leaves the root and appears
  // under its new parent. Both are separate queries, and both have to wake.
  test('moving a deck re-emits both lists', () async {
    final parent = await create(name: 'Korean', languagePairId: 'lp1');
    final child = await create(name: 'Grammar', languagePairId: 'lp1');
    final roots = record(decks.watchRootSummaries('lp1'));
    final children = record(decks.watchChildSummaries(parent.id));
    expect(await roots.next(), hasLength(2));
    expect(await children.next(), isEmpty);

    await MoveDeckUseCase(
      decks: decks,
      clock: _FixedClock(now),
    ).call(deckId: child.id, newParentId: parent.id);

    expect((await roots.next()).single.deck.id, parent.id);
    expect((await children.next()).single.deck.id, child.id);
  });

  test('deleting a deck re-emits without it', () async {
    final keep = await create(name: 'Keep', languagePairId: 'lp1');
    final drop = await create(name: 'Drop', languagePairId: 'lp1');
    final roots = record(decks.watchRootSummaries('lp1'));
    expect(await roots.next(), hasLength(2));

    await DeleteDeckUseCase(decks: decks).call(drop.id);

    expect((await roots.next()).single.deck.id, keep.id);
  });

  // The row counters are direct cards only — a documented decision, and one
  // the reactive read has to honour as well as the one-shot query does.
  test('a card added to a child does not inflate the parent row', () async {
    final parent = await create(name: 'Korean', languagePairId: 'lp1');
    final child = await create(
      name: 'Grammar',
      languagePairId: 'lp1',
      parentId: parent.id,
    );
    await database.flashcardDao.insertFlashcard(
      'c1',
      child.id,
      'one',
      'one',
      'một',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p-c1',
      'c1',
      0,
      null,
      0,
      0,
    );

    final roots = await decks.watchRootSummaries('lp1').first;
    final children = await decks.watchChildSummaries(parent.id).first;

    expect(roots.single.cardCount, 0, reason: 'the parent holds no cards');
    expect(children.single.cardCount, 1);
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  _SeqIds(this._prefix);
  final String _prefix;
  int _n = 0;
  @override
  String newId() => '$_prefix-${_n++}';
}

/// Keeps one subscription open and hands out emissions in order, so a test
/// asserting the second value is asserting that the stream emitted twice.
class _Recorder<T> {
  _Recorder(Stream<T> stream) {
    _subscription = stream.listen(_emissions.add);
  }

  final List<T> _emissions = <T>[];
  late final StreamSubscription<T> _subscription;
  int _taken = 0;

  /// The next emission after the ones already taken, waiting for the store to
  /// push it. Fails rather than hanging when nothing arrives.
  Future<T> next() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (_emissions.length > _taken) return _emissions[_taken++];
      await pumpEventQueue(times: 5);
    }
    fail('the stream did not emit again (had ${_emissions.length})');
  }

  Future<void> dispose() => _subscription.cancel();
}

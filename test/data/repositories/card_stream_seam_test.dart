import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/usecases/flashcard/create_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/delete_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/edit_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/hide_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/move_flashcard_usecase.dart';

/// WBS 5.3 — the card list inside a deck is reactive, and every card mutation
/// is what makes it re-emit.
///
/// The deck-level lists were covered by `int-28`; this is the level below.
/// Same failure shape: a mutation that writes correctly but does not wake the
/// stream leaves the open deck showing the list from before the edit, and is
/// indistinguishable from one that works.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftFlashcardRepository cards;
  late DriftDeckRepository decks;
  late CreateFlashcardUseCase create;

  final now = DateTime.utc(2026, 7, 27, 9);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    cards = DriftFlashcardRepository(database);
    decks = DriftDeckRepository(database, _FixedClock(now));
    create = CreateFlashcardUseCase(
      cards: cards,
      decks: decks,
      idGenerator: _SeqIds('card'),
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
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D1', 'd1', 0, 0);
    await database.deckDao.insertDeck('d2', 'lp1', null, 'D2', 'd2', 0, 0);
  });

  tearDown(() => database.close());

  /// One listener for the whole test, so asserting the second emission
  /// asserts that the stream emitted twice. Re-reading per step would pass
  /// even if nothing woke — the mistake `int-28` records.
  _Recorder<List<Flashcard>> record(String deckId) {
    final recorder = _Recorder<List<Flashcard>>(cards.watchByDeck(deckId));
    addTearDown(recorder.dispose);
    return recorder;
  }

  /// Creates a card and returns it, failing loudly if the create path took
  /// its duplicate branch instead.
  Future<Flashcard> newCard(String deckId, String term, String meaning) async {
    final result = await create(
      deckId: deckId,
      term: term,
      primaryMeaning: meaning,
    );
    return (result as FlashcardCreated).card;
  }

  test('creating a card reaches the live list', () async {
    final list = record('d1');
    expect(await list.next(), isEmpty);

    await create(deckId: 'd1', term: 'hello', primaryMeaning: 'xin chào');

    expect((await list.next()).single.term, 'hello');
  });

  test('editing a card re-emits the new text', () async {
    final created = await newCard('d1', 'helo', 'xin chào');
    final list = record('d1');
    expect((await list.next()).single.term, 'helo');

    await EditFlashcardUseCase(
      cards: cards,
      decks: decks,
      clock: _FixedClock(now),
    ).call(
      cardId: created.id,
      term: 'hello',
      primaryMeaning: 'xin chào',
      // The optimistic-concurrency guard: the edit is written against the
      // version the list showed.
      expectedContentVersion: created.contentVersion,
    );

    expect((await list.next()).single.term, 'hello');
  });

  // A move changes two lists at once, like the deck move in `int-28`.
  test('moving a card re-emits both decks', () async {
    final created = await newCard('d1', 'hello', 'xin chào');
    final from = record('d1');
    final to = record('d2');
    expect(await from.next(), hasLength(1));
    expect(await to.next(), isEmpty);

    await MoveFlashcardUseCase(
      cards: cards,
      decks: decks,
      clock: _FixedClock(now),
    ).call(cardId: created.id, targetDeckId: 'd2');

    expect(await from.next(), isEmpty);
    expect((await to.next()).single.id, created.id);
  });

  // Hiding keeps the card in the deck — it leaves the study queues, not the
  // list the learner manages it from.
  test('hiding a card re-emits it as hidden, still listed', () async {
    final created = await newCard('d1', 'hello', 'xin chào');
    final list = record('d1');
    expect((await list.next()).single.isHidden, isFalse);

    await HideFlashcardUseCase(
      cards: cards,
      clock: _FixedClock(now),
    ).setHidden(created.id, hidden: true);

    final rows = await list.next();
    expect(rows, hasLength(1));
    expect(rows.single.isHidden, isTrue);
  });

  test('deleting a card re-emits without it', () async {
    final keep = await newCard('d1', 'hello', 'xin chào');
    final drop = await newCard('d1', 'goodbye', 'tạm biệt');
    final list = record('d1');
    expect(await list.next(), hasLength(2));

    await DeleteFlashcardUseCase(
      cards: cards,
      clock: _FixedClock(now),
    ).deleteCard(drop.id);

    expect((await list.next()).single.id, keep.id);
  });
}

/// Keeps one subscription open and hands out emissions in order.
class _Recorder<T> {
  _Recorder(Stream<T> stream) {
    _subscription = stream.listen(_emissions.add);
  }

  final List<T> _emissions = <T>[];
  late final StreamSubscription<T> _subscription;
  int _taken = 0;

  Future<T> next() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (_emissions.length > _taken) return _emissions[_taken++];
      await pumpEventQueue(times: 5);
    }
    fail('the stream did not emit again (had ${_emissions.length})');
  }

  Future<void> dispose() => _subscription.cancel();
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

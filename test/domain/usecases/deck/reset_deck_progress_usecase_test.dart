import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/domain/usecases/deck/reset_deck_progress_usecase.dart';

/// WBS 6.1 — resetting a deck's progress returns every subtree card to Box 0 in
/// one transaction, touching no content (reset-deck-progress.md).
void main() {
  final now = DateTime.utc(2026, 7, 24, 15);
  late db.AppDatabase database;
  late DriftLearningProgressRepository progress;

  ResetDeckProgressUseCase useCase() => ResetDeckProgressUseCase(
    progress: progress,
    idGenerator: _SeqIds(),
    clock: _FixedClock(now),
  );

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    progress = DriftLearningProgressRepository(database);
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    // root(d1) ─┬─ leaf(d2, card c1)
    //           └─ leaf(d3, card c2)  — a parent holds no direct cards (4.3).
    await database.deckDao.insertDeck('d1', 'lp1', null, 'Root', 'root', 0, 0);
    await database.deckDao.insertDeck(
      'd2',
      'lp1',
      'd1',
      'Leaf 2',
      'leaf 2',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'd3',
      'lp1',
      'd1',
      'Leaf 3',
      'leaf 3',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd2',
      't1',
      't1',
      'm1',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c2',
      'd3',
      't2',
      't2',
      'm2',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p1',
      'c1',
      5,
      9999,
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p2',
      'c2',
      3,
      8888,
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<int?> boxOf(String cardId) async {
    final progressRow = await progress.findByCard(cardId);
    return progressRow?.box;
  }

  test('resetting the root returns every subtree card to Box 0', () async {
    final count = await useCase().call('d1');
    expect(count, 2);
    expect(await boxOf('c1'), 0);
    expect(await boxOf('c2'), 0);
    // No due date once reset to New.
    expect((await progress.findByCard('c1'))?.dueAt, isNull);
  });

  test('resetting a leaf only resets its own cards', () async {
    final count = await useCase().call('d2');
    expect(count, 1);
    expect(await boxOf('c1'), 0);
    // The sibling leaf under the root is untouched.
    expect(await boxOf('c2'), 3);
  });

  test('an empty deck resets nothing', () async {
    await database.deckDao.insertDeck(
      'empty',
      'lp1',
      null,
      'Empty',
      'empty',
      0,
      0,
    );
    expect(await useCase().call('empty'), 0);
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'reset-${_n++}';
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/usecases/deck/load_reset_progress_availability_usecase.dart';
import 'package:memox_v6/domain/deck/reset_progress_result.dart';
import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/reset_deck_progress_usecase.dart';

/// WBS 6.1 — resetting a deck's progress returns every subtree card to Box 0 in
/// one transaction, touching no content (reset-deck-progress.md).
void main() {
  final now = DateTime.utc(2026, 7, 24, 15);
  late db.AppDatabase database;
  late DriftLearningProgressRepository progress;

  ResetDeckProgressUseCase useCase() => ResetDeckProgressUseCase(
    progress: progress,
    availability: LoadResetProgressAvailabilityUseCase(
      decks: DriftDeckRepository(database, _FixedClock(now)),
      sessions: DriftStudySessionRepository(database),
    ),
    impact: LoadDeckDeletionImpactUseCase(
      decks: DriftDeckRepository(database, _FixedClock(now)),
      sessions: DriftStudySessionRepository(database),
    ),
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

  /// The affected count the confirm showed, resolved the same way the dialog
  /// resolves it, so the expectation passed in is the one a learner saw.
  Future<int> affected(String deckId) async {
    final impact = await LoadDeckDeletionImpactUseCase(
      decks: DriftDeckRepository(database, _FixedClock(now)),
      sessions: DriftStudySessionRepository(database),
    )(deckId);
    return impact.studiedCardCount;
  }

  Future<ResetProgressResult> reset(String deckId, {int? expected}) async {
    return useCase().call(
      deckId,
      expectedAffectedCount: expected ?? await affected(deckId),
    );
  }

  test('resetting the root returns every subtree card to Box 0', () async {
    final result = await reset('d1');
    expect((result as ProgressReset).cardCount, 2);
    expect(await boxOf('c1'), 0);
    expect(await boxOf('c2'), 0);
    // No due date once reset to New.
    expect((await progress.findByCard('c1'))?.dueAt, isNull);
  });

  test('resetting a leaf only resets its own cards', () async {
    final result = await reset('d2');
    expect((result as ProgressReset).cardCount, 1);
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
    expect((await reset('empty') as ProgressReset).cardCount, 0);
  });

  // §5: "Counts refresh trước submit; impact đổi yêu cầu confirm lại", and §11
  // gives "Impact changed" its own row. A confirm is a promise about a number,
  // and the dialog can sit open while cards are added, deleted or studied — so
  // the store re-reads instead of trusting the number it was handed
  // (`int-103`).
  test('a moved affected count is re-confirmed, not reset', () async {
    // What the learner confirmed, before a third card was studied.
    final result = await reset('d1', expected: 1);

    expect(result, isA<ResetImpactChanged>());
    expect((result as ResetImpactChanged).affectedCardCount, 2);
    expect(
      await boxOf('c1'),
      isNot(0),
      reason: 'nothing is reset while the impact is being re-confirmed',
    );
  });

  test('re-confirming over the new count resets', () async {
    expect(await reset('d1', expected: 1), isA<ResetImpactChanged>());

    final result = await reset('d1');

    expect((result as ProgressReset).cardCount, 2);
    expect(await boxOf('c1'), 0);
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

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';

/// WBS 5.4.4 — Attempt/schedule transaction. The use case wires the pure
/// [Srs8BoxPolicy] into the atomic `applyScheduledOutcome` op, deriving box,
/// due and counters (SRS Policy v1 §§3,5–8; SRS8-001, 003, 020, 011, 028).
/// Exactly-once replay and stale-revision conflict at the data layer are
/// covered in `test/data/repositories/progress_repositories_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftLearningProgressRepository repo;
  late ApplyTerminalOutcomeUseCase useCase;

  final now = DateTime.utc(2026, 7, 23, 9);

  StudyAttempt terminal(
    String id, {
    String key = 'k1',
    String outcome = 'correct',
  }) => StudyAttempt(
    id: id,
    idempotencyKey: key,
    cardId: 'c1',
    sessionId: null,
    modeId: 'guess',
    outcome: outcome,
    evidenceJson: '{}',
    isTerminal: true,
    createdAt: now,
  );

  Future<void> seedProgress({required int box, int? dueAt}) =>
      database.learningProgressDao.insertProgress('p1', 'c1', box, dueAt, 0, 0);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftLearningProgressRepository(database);
    useCase = ApplyTerminalOutcomeUseCase(repository: repo);
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D', 'd', 0, 0);
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd1',
      't',
      't',
      'm',
      0,
      0,
    );
  });

  tearDown(() => database.close());

  test(
    'SRS8-001: activate promotes Box 0 → Box 1 without touching counters',
    () async {
      await seedProgress(box: 0);

      await useCase.activate(attempt: terminal('a1'), nowUtc: now);

      final p = await repo.findByCard('c1');
      expect(p?.box, 1);
      expect(p?.dueAt, now.add(const Duration(days: 1)));
      expect(
        p?.repetitionCount,
        0,
        reason: 'activation is not a graded repetition',
      );
      expect(p?.lapseCount, 0);
      expect(p?.revision, 1);
      expect(p?.lastTerminalAttemptId, 'a1');
    },
  );

  test(
    'SRS8-003: a correct grade promotes one box and counts a repetition',
    () async {
      await seedProgress(box: 1, dueAt: now.millisecondsSinceEpoch);

      await useCase.applyGrade(
        attempt: terminal('a1'),
        grade: SrsGrade.correct,
        nowUtc: now,
      );

      final p = await repo.findByCard('c1');
      expect(p?.box, 2);
      expect(p?.dueAt, now.add(const Duration(days: 3)));
      expect(p?.repetitionCount, 1);
      expect(p?.lapseCount, 0);
    },
  );

  test('SRS8-020: a wrong grade demotes one box and counts a lapse', () async {
    await seedProgress(box: 3, dueAt: now.millisecondsSinceEpoch);

    await useCase.applyGrade(
      attempt: terminal('a1'),
      grade: SrsGrade.wrong,
      nowUtc: now,
    );

    final p = await repo.findByCard('c1');
    expect(p?.box, 2);
    expect(p?.dueAt, now.add(const Duration(days: 3)));
    expect(p?.repetitionCount, 1);
    expect(p?.lapseCount, 1, reason: 'a terminal wrong records one lapse');
  });

  test(
    'SRS8-011: replaying the same idempotency key does not transition twice',
    () async {
      await seedProgress(box: 1, dueAt: now.millisecondsSinceEpoch);

      await useCase.applyGrade(
        attempt: terminal('a1', key: 'once'),
        grade: SrsGrade.correct,
        nowUtc: now,
      );
      // Same key, a grade that would otherwise advance again.
      await useCase.applyGrade(
        attempt: terminal('a2', key: 'once'),
        grade: SrsGrade.correct,
        nowUtc: now,
      );

      final p = await repo.findByCard('c1');
      expect(p?.box, 2, reason: 'the replay is a no-op');
      expect(p?.revision, 1);
    },
  );

  test(
    'SRS8-028: an unknown policy id is a typed failure, nothing persists',
    () async {
      await seedProgress(box: 2, dueAt: now.millisecondsSinceEpoch);
      await database.customStatement(
        "UPDATE learning_progress SET policy_id = 'some-future-policy' WHERE card_id = 'c1'",
      );

      await expectLater(
        useCase.applyGrade(
          attempt: terminal('a1'),
          grade: SrsGrade.correct,
          nowUtc: now,
        ),
        throwsA(
          isA<ValidationFailure>().having((f) => f.field, 'field', 'policyId'),
        ),
      );

      final p = await repo.findByCard('c1');
      expect(p?.box, 2, reason: 'a rejected policy persists no transition');
      expect(p?.revision, 0);
    },
  );

  test(
    'a grade on a pre-SRS Box 0 card is rejected before any write',
    () async {
      await seedProgress(box: 0);

      await expectLater(
        useCase.applyGrade(
          attempt: terminal('a1'),
          grade: SrsGrade.correct,
          nowUtc: now,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.code,
            'code',
            'not-activated',
          ),
        ),
      );
      expect((await repo.findByCard('c1'))?.box, 0);
    },
  );
}

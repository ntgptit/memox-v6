import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/data/repositories/drift_streak_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_goal_repository.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftLearningProgressRepository progress;
  late DriftPreferenceRepository preferences;
  late DriftStudyGoalRepository goals;
  late DriftStreakRepository streaks;

  final epoch = DateTime.utc(2026, 7, 19);

  StudyAttempt attempt(String id, {String key = 'k1'}) => StudyAttempt(
    id: id,
    idempotencyKey: key,
    cardId: 'c1',
    sessionId: null,
    modeId: 'guess',
    outcome: 'correct',
    evidenceJson: '{}',
    isTerminal: true,
    createdAt: epoch,
  );

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    progress = DriftLearningProgressRepository(database);
    preferences = DriftPreferenceRepository(database);
    goals = DriftStudyGoalRepository(database);
    streaks = DriftStreakRepository(database);

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Travel',
      'travel',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd1',
      't',
      't',
      'm',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p1',
      'c1',
      0,
      null,
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('applyScheduledOutcome (atomic operation 4)', () {
    test('persists evidence and schedule exactly once', () async {
      await progress.applyScheduledOutcome(
        attempt: attempt('a1'),
        newBox: 1,
        newDueAt: epoch.add(const Duration(days: 1)),
        repetitionCount: 1,
        lapseCount: 0,
        expectedRevision: 0,
        updatedAt: epoch,
      );

      final updated = await progress.findByCard('c1');
      expect(updated?.box, 1);
      expect(updated?.revision, 1);
      expect(updated?.lastTerminalAttemptId, 'a1');

      // Replay with the same idempotency key: success, no reapply.
      await progress.applyScheduledOutcome(
        attempt: attempt('a2'),
        newBox: 2,
        newDueAt: epoch.add(const Duration(days: 2)),
        repetitionCount: 2,
        lapseCount: 0,
        expectedRevision: 1,
        updatedAt: epoch,
      );

      final afterReplay = await progress.findByCard('c1');
      expect(afterReplay?.box, 1);
      expect(afterReplay?.revision, 1);
    });

    // SRS8-012: a different outcome on a stale progress revision is a typed
    // conflict, not a silent last-write-wins.
    test('a stale revision conflicts and persists nothing', () async {
      await expectLater(
        progress.applyScheduledOutcome(
          attempt: attempt('a1'),
          newBox: 1,
          newDueAt: epoch.add(const Duration(days: 1)),
          repetitionCount: 1,
          lapseCount: 0,
          expectedRevision: 9,
          updatedAt: epoch,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'revision',
          ),
        ),
      );

      final evidence = await database.studyAttemptDao
          .findAttemptByIdempotencyKey('k1')
          .getSingleOrNull();
      expect(evidence, isNull);

      final untouched = await progress.findByCard('c1');
      expect(untouched?.box, 0);
    });

    // SRS8-016: Reset returns any box to Box 0 with a null due date.
    test('reset returns a card to Box 0 without touching content', () async {
      await progress.applyScheduledOutcome(
        attempt: attempt('a1'),
        newBox: 3,
        newDueAt: epoch.add(const Duration(days: 3)),
        repetitionCount: 3,
        lapseCount: 1,
        expectedRevision: 0,
        updatedAt: epoch,
      );

      await progress.resetCard('c1', newProgressId: 'p2', at: epoch);

      final reset = await progress.findByCard('c1');
      expect(reset?.box, 0);
      expect(reset?.dueAt, isNull);
      expect(reset?.repetitionCount, 0);
      expect(reset?.lapseCount, 0);

      final card = await database.flashcardDao
          .findFlashcardById('c1')
          .getSingle();
      expect(card.term, 't');
    });

    test('due paging flows through the repository', () async {
      await progress.applyScheduledOutcome(
        attempt: attempt('a1'),
        newBox: 1,
        newDueAt: epoch,
        repetitionCount: 1,
        lapseCount: 0,
        expectedRevision: 0,
        updatedAt: epoch,
      );

      final due = await progress.pageDue(
        epoch.add(const Duration(minutes: 1)),
        limit: 10,
        offset: 0,
      );
      expect(due.single.cardId, 'c1');
      expect(await progress.countDue(epoch.add(const Duration(minutes: 1))), 1);
    });
  });

  group('PreferenceRepository', () {
    test('round-trips values and falls back to null on corruption', () async {
      await preferences.save(
        'appearance',
        value: {'mode': 'dark'},
        schemaVersion: 1,
        updatedAt: epoch,
      );

      final entry = await preferences.read('appearance');
      expect(entry?.value, {'mode': 'dark'});

      await database.preferenceDao.upsertPreference(
        'appearance',
        '{broken',
        1,
        0,
      );
      expect(await preferences.read('appearance'), isNull);
    });
  });

  group('StudyGoalRepository and StreakRepository', () {
    test('goal buckets and streak days record through the ports', () async {
      await goals.createGoal(
        DailyGoal(
          id: 'g1',
          isEnabled: true,
          targetCardCount: 10,
          effectiveFromLocalDate: '2026-07-19',
          timezoneId: 'Asia/Ho_Chi_Minh',
          createdAt: epoch,
          updatedAt: epoch,
        ),
      );
      await goals.recordDayProgress(
        GoalDayProgress(
          id: 'b1',
          localDate: '2026-07-19',
          timezoneId: 'Asia/Ho_Chi_Minh',
          goalId: 'g1',
          qualifiedCardCount: 10,
          targetSnapshot: 10,
          isMet: true,
          updatedAt: epoch,
        ),
      );

      final bucket = await goals.dayProgress('2026-07-19');
      expect(bucket?.isMet, isTrue);
      expect((await goals.latestGoal())?.id, 'g1');

      const day = StreakDay(
        id: 's1',
        localDate: '2026-07-19',
        timezoneId: 'Asia/Ho_Chi_Minh',
        qualifiedSource: 'metrics-v1',
        sourceVersion: 1,
      );
      await streaks.recordDay(day, recordedAt: epoch);
      await streaks.recordDay(day, recordedAt: epoch);

      expect(await streaks.countDays(), 1);
      final range = await streaks.daysBetween('2026-07-19', '2026-07-19');
      expect(range.single.qualifiedSource, 'metrics-v1');
    });
  });
}

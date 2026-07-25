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
        srsActivatedAt: epoch,
        lastReviewedAt: epoch,
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
        srsActivatedAt: epoch,
        lastReviewedAt: epoch,
        expectedRevision: 1,
        updatedAt: epoch,
      );

      final afterReplay = await progress.findByCard('c1');
      expect(afterReplay?.box, 1);
      expect(afterReplay?.revision, 1);
    });

    // Schema v2 (WBS 5.4.4). Both instants used to be computed by the policy
    // and dropped on the way to the store; this is the round trip that says
    // they arrive.
    test('stores both SRS timestamps and reads them back', () async {
      final activated = epoch.add(const Duration(days: 3));
      final reviewed = epoch.add(const Duration(days: 10));

      await progress.applyScheduledOutcome(
        attempt: attempt('a1'),
        newBox: 2,
        newDueAt: reviewed.add(const Duration(days: 3)),
        repetitionCount: 1,
        lapseCount: 0,
        srsActivatedAt: activated,
        lastReviewedAt: reviewed,
        expectedRevision: 0,
        updatedAt: reviewed,
      );

      final stored = await progress.findByCard('c1');
      expect(stored?.srsActivatedAt, activated);
      expect(stored?.lastReviewedAt, reviewed);
    });

    // The activation instant is fixed at Box 1 and never moves, so a later
    // grade must not overwrite it with its own `now`.
    test('a later grade advances the review but not the activation', () async {
      final activated = epoch.add(const Duration(days: 3));
      final firstReview = epoch.add(const Duration(days: 3));
      final secondReview = epoch.add(const Duration(days: 20));

      await progress.applyScheduledOutcome(
        attempt: attempt('a1'),
        newBox: 1,
        newDueAt: firstReview.add(const Duration(days: 1)),
        repetitionCount: 1,
        lapseCount: 0,
        srsActivatedAt: activated,
        lastReviewedAt: firstReview,
        expectedRevision: 0,
        updatedAt: firstReview,
      );
      await progress.applyScheduledOutcome(
        // A distinct idempotency key: this is a second grade, not a replay of
        // the first. Sharing `k1` would be deduped, which is the contract.
        attempt: attempt('a2', key: 'k2'),
        newBox: 2,
        newDueAt: secondReview.add(const Duration(days: 3)),
        repetitionCount: 2,
        lapseCount: 0,
        srsActivatedAt: activated,
        lastReviewedAt: secondReview,
        expectedRevision: 1,
        updatedAt: secondReview,
      );

      final stored = await progress.findByCard('c1');
      expect(stored?.box, 2);
      expect(stored?.srsActivatedAt, activated);
      expect(stored?.lastReviewedAt, secondReview);
    });

    // SRS8-012, child B. The test below feeds an impossible revision (9)
    // straight in, which proves the guard rejects a bad argument but not that
    // the guard fires in the situation it exists for. Here both writers read
    // the card's real revision first, exactly as two devices or two tabs
    // would, and race on it — the staleness is produced rather than asserted.
    test(
      'two writers on the same revision: one commits, one conflicts',
      () async {
        final before = await progress.findByCard('c1');
        final sharedRevision = before!.revision;

        Future<String> outcomeOf(Future<void> write) async {
          try {
            await write;
            return 'committed';
          } on ConflictFailure {
            return 'conflict';
          }
        }

        // Both start from the same observed revision. Whichever transaction
        // commits first advances it, and the other's guard no longer matches.
        final results = await Future.wait(<Future<String>>[
          outcomeOf(
            progress.applyScheduledOutcome(
              attempt: attempt('a1', key: 'k1'),
              newBox: 1,
              newDueAt: epoch.add(const Duration(days: 1)),
              repetitionCount: 1,
              lapseCount: 0,
              srsActivatedAt: epoch,
              lastReviewedAt: epoch,
              expectedRevision: sharedRevision,
              updatedAt: epoch,
            ),
          ),
          outcomeOf(
            progress.applyScheduledOutcome(
              attempt: attempt('a2', key: 'k2'),
              newBox: 5,
              newDueAt: epoch.add(const Duration(days: 30)),
              repetitionCount: 1,
              lapseCount: 0,
              srsActivatedAt: epoch,
              lastReviewedAt: epoch,
              expectedRevision: sharedRevision,
              updatedAt: epoch,
            ),
          ),
        ]);

        // Exactly one of them wins. Which one is not the contract — that
        // neither is silently dropped, and neither half-applies, is.
        expect(results, containsAll(<String>['committed', 'conflict']));

        final after = await progress.findByCard('c1');
        expect(after?.revision, sharedRevision + 1);

        // The loser left nothing behind: its evidence row is absent, so a
        // retry can re-run the whole operation cleanly.
        final stored = await database.studyAttemptDao
            .pageAttemptsForCard('c1', 10, 0)
            .get();
        expect(stored, hasLength(1));
        expect(after?.lastTerminalAttemptId, stored.single.id);
      },
    );

    // The idempotency column is globally unique, so a key minted for one card
    // and reused for another would be read as a replay and the second card's
    // grade would vanish — no write, no error. Current callers scope their
    // keys by card, so this is unreachable; the point is that if that ever
    // changes the failure is loud instead of a lost review.
    test('a key already used by another card fails instead of no-op', () async {
      await database.flashcardDao.insertFlashcard(
        'c2',
        'd1',
        't2',
        't2',
        'm2',
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p2',
        'c2',
        0,
        null,
        0,
        0,
      );

      await progress.applyScheduledOutcome(
        attempt: attempt('a1', key: 'shared'),
        newBox: 1,
        newDueAt: epoch.add(const Duration(days: 1)),
        repetitionCount: 1,
        lapseCount: 0,
        srsActivatedAt: epoch,
        lastReviewedAt: epoch,
        expectedRevision: 0,
        updatedAt: epoch,
      );

      await expectLater(
        progress.applyScheduledOutcome(
          attempt: StudyAttempt(
            id: 'a2',
            idempotencyKey: 'shared',
            cardId: 'c2',
            sessionId: null,
            modeId: 'guess',
            outcome: 'correct',
            evidenceJson: '{}',
            isTerminal: true,
            createdAt: epoch,
          ),
          newBox: 1,
          newDueAt: epoch.add(const Duration(days: 1)),
          repetitionCount: 1,
          lapseCount: 0,
          srsActivatedAt: epoch,
          lastReviewedAt: epoch,
          expectedRevision: 0,
          updatedAt: epoch,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.code,
            'code',
            'card-mismatch',
          ),
        ),
      );

      // The second card is untouched rather than quietly skipped.
      final other = await progress.findByCard('c2');
      expect(other?.box, 0);
      expect(other?.revision, 0);
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
          srsActivatedAt: epoch,
          lastReviewedAt: epoch,
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
        srsActivatedAt: epoch,
        lastReviewedAt: epoch,
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
        srsActivatedAt: epoch,
        lastReviewedAt: epoch,
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

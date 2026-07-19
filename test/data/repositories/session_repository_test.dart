import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_relearn_item.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;

  final epoch = DateTime.utc(2026, 7, 19);

  StudySession session(String id, {SessionState state = SessionState.active}) {
    return StudySession(
      id: id,
      type: SessionType.newLearning,
      deckId: 'd1',
      scope: SessionScope.leaf,
      state: state,
      revision: 0,
      snapshotVersion: 1,
      scheduleSrs: true,
      startedAt: epoch,
      finalizedAt: null,
      createdAt: epoch,
      updatedAt: epoch,
    );
  }

  SessionCardSnapshot snapshot(String id, {int order = 0}) {
    return SessionCardSnapshot(
      id: id,
      sessionId: 's1',
      cardId: 'c1',
      displayOrder: order,
      term: 't',
      meaning: 'm',
      contentVersion: 1,
      progressBox: 0,
      progressRevision: 0,
    );
  }

  SessionRoundOrder order(String id) => SessionRoundOrder(
    id: id,
    sessionId: 's1',
    roundIndex: 0,
    seed: 42,
    cardIds: const ['c1'],
  );

  SessionCheckpoint checkpoint({int position = 0}) => SessionCheckpoint(
    id: 'cp1',
    sessionId: 's1',
    stageIndex: 0,
    roundIndex: 0,
    cardPosition: position,
    failedCardIds: const [],
    timerStateJson: '{}',
    stateVersion: 1,
    updatedAt: epoch,
  );

  StudyAttempt attempt(String id, {String key = 'k1'}) => StudyAttempt(
    id: id,
    idempotencyKey: key,
    cardId: 'c1',
    sessionId: 's1',
    modeId: 'guess',
    outcome: 'correct',
    evidenceJson: '{}',
    isTerminal: true,
    createdAt: epoch,
  );

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);

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
  });

  tearDown(() async {
    await database.close();
  });

  group('startSession (atomic operation 2)', () {
    test(
      'commits session, snapshots and order together, idempotently',
      () async {
        await sessions.startSession(
          session: session('s1'),
          cardSnapshots: [snapshot('sc1')],
          initialOrder: order('ro1'),
        );
        await sessions.startSession(
          session: session('s1'),
          cardSnapshots: [snapshot('sc-dup')],
          initialOrder: order('ro-dup'),
        );

        final snapshots = await sessions.cardSnapshots('s1');
        expect(snapshots.single.id, 'sc1');

        final stored = await sessions.roundOrder('s1', 0);
        expect(stored?.cardIds, ['c1']);

        final active = await sessions.watchActive().first;
        expect(active?.id, 's1');
      },
    );

    test('a competing active session rolls back completely', () async {
      await sessions.startSession(
        session: session('s1'),
        cardSnapshots: [snapshot('sc1')],
        initialOrder: order('ro1'),
      );

      final competing = StudySession(
        id: 's2',
        type: SessionType.practice,
        deckId: 'd1',
        scope: SessionScope.leaf,
        state: SessionState.active,
        revision: 0,
        snapshotVersion: 1,
        scheduleSrs: false,
        startedAt: epoch,
        finalizedAt: null,
        createdAt: epoch,
        updatedAt: epoch,
      );

      await expectLater(
        sessions.startSession(
          session: competing,
          cardSnapshots: const [],
          initialOrder: SessionRoundOrder(
            id: 'ro2',
            sessionId: 's2',
            roundIndex: 0,
            seed: 1,
            cardIds: const [],
          ),
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'duplicate',
          ),
        ),
      );

      expect(await sessions.findById('s2'), isNull);
    });
  });

  group('saveAttemptWithCheckpoint (atomic operation 3)', () {
    test('persists both and absorbs replays without overwriting', () async {
      await sessions.startSession(
        session: session('s1'),
        cardSnapshots: [snapshot('sc1')],
        initialOrder: order('ro1'),
      );

      await sessions.saveAttemptWithCheckpoint(
        attempt: attempt('a1'),
        checkpoint: checkpoint(position: 1),
      );
      await sessions.saveAttemptWithCheckpoint(
        attempt: attempt('a2'),
        checkpoint: checkpoint(position: 9),
      );

      final stored = await sessions.checkpoint('s1');
      expect(stored?.cardPosition, 1);

      final evidence = await database.studyAttemptDao
          .listAttemptsForSession('s1')
          .get();
      expect(evidence.single.id, 'a1');
    });
  });

  group('finalizeSession (atomic operation 5)', () {
    GoalDayProgress contribution() => GoalDayProgress(
      id: 'b1',
      localDate: '2026-07-19',
      timezoneId: 'Asia/Ho_Chi_Minh',
      goalId: 'g1',
      qualifiedCardCount: 1,
      targetSnapshot: 10,
      isMet: false,
      updatedAt: epoch,
    );

    setUp(() async {
      await database.studyGoalDao.insertGoal(
        'g1',
        1,
        10,
        '2026-07-19',
        'Asia/Ho_Chi_Minh',
        0,
        0,
      );
      await sessions.startSession(
        session: session('s1'),
        cardSnapshots: [snapshot('sc1')],
        initialOrder: order('ro1'),
      );
    });

    test('applies state and contributions exactly once', () async {
      await sessions.finalizeSession(
        sessionId: 's1',
        expectedRevision: 0,
        terminalState: SessionState.completed,
        finalizedAt: epoch,
        goalContribution: contribution(),
        streakContribution: const StreakDay(
          id: 'st1',
          localDate: '2026-07-19',
          timezoneId: 'Asia/Ho_Chi_Minh',
          qualifiedSource: 'metrics-v1',
          sourceVersion: 1,
        ),
      );

      final finalized = await sessions.findById('s1');
      expect(finalized?.state, SessionState.completed);
      expect(await sessions.watchActive().first, isNull);

      // Replay after the transition: success without reapplying.
      await sessions.finalizeSession(
        sessionId: 's1',
        expectedRevision: 0,
        terminalState: SessionState.completed,
        finalizedAt: epoch,
        goalContribution: contribution(),
      );

      final bucket = await database.studyGoalDao
          .findDayProgress('2026-07-19')
          .getSingle();
      expect(bucket.qualifiedCardCount, 1);
      expect(await database.streakDao.countStreakDays().getSingle(), 1);
    });

    test('a stale revision toward a different state conflicts', () async {
      await sessions.finalizeSession(
        sessionId: 's1',
        expectedRevision: 0,
        terminalState: SessionState.completed,
        finalizedAt: epoch,
      );

      await expectLater(
        sessions.finalizeSession(
          sessionId: 's1',
          expectedRevision: 5,
          terminalState: SessionState.abandoned,
          finalizedAt: epoch,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'revision',
          ),
        ),
      );
    });
  });

  group('relearn queue', () {
    test('records and lists deduplicated items', () async {
      await sessions.startSession(
        session: session('s1'),
        cardSnapshots: [snapshot('sc1')],
        initialOrder: order('ro1'),
      );

      const item = SessionRelearnItem(
        id: 'r1',
        sessionId: 's1',
        cardId: 'c1',
        retryCount: 0,
      );
      await sessions.addRelearnItem(item, recordedAt: epoch);
      await sessions.addRelearnItem(
        const SessionRelearnItem(
          id: 'r2',
          sessionId: 's1',
          cardId: 'c1',
          retryCount: 0,
        ),
        recordedAt: epoch,
      );

      final items = await sessions.relearnItems('s1');
      expect(items.single.id, 'r1');
    });
  });
}

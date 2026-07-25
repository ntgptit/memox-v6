import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_advance_policy.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_streak/record_streak_day_usecase.dart';
import 'package:memox_v6/domain/study_streak/streak_repository.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/usecases/study_goal/track_daily_goal_usecase.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';

/// WBS 5.6.13 — the finalize orchestration (`finalize-study-session.md`,
/// `srs-8-box-v1.md`): aggregate terminal grades, schedule SRS exactly once and
/// commit completion.
void main() {
  final now = DateTime.utc(2026, 7, 24, 9);

  StudySession session({
    SessionType type = SessionType.newLearning,
    bool scheduleSrs = true,
    int revision = 3,
  }) => StudySession(
    id: 's1',
    type: type,
    deckId: 'd1',
    scope: SessionScope.subtree,
    state: SessionState.active,
    revision: revision,
    snapshotVersion: 1,
    scheduleSrs: scheduleSrs,
    startedAt: now,
    finalizedAt: null,
    createdAt: now,
    updatedAt: now,
  );

  StudyRuntimeState completed(StudySession s) => StudyRuntimeState(
    session: s,
    stages: const <StudyModeType>[StudyModeType.guess],
    position: const SessionPosition(
      stageIndex: 0,
      roundIndex: 1,
      roundCardIds: <String>['c1'],
      cardPosition: 0,
      failedCardIds: <String>[],
      phase: SessionPhase.sessionComplete,
    ),
    cardsById: const {},
  );

  FinalizeStudySessionUseCase build(
    _FakeSessions sessions,
    _FakeProgress progress,
  ) => FinalizeStudySessionUseCase(
    sessions: sessions,
    progress: progress,
    applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
    clock: _FixedClock(now),
    idGenerator: _SeqIds(),
  );

  // `record-streak-day.md` §1: "Ghi streak không được rollback Study Session
  // đã thành công." The session is already durable by the time the streak is
  // offered the event, so a storage failure there must cost a streak day —
  // which reconciliation can rebuild from session history — and never the
  // finished session, which nothing can rebuild.
  test('a failing streak write does not fail the finalized session', () async {
    final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
    final progress = _FakeProgress({'c1': _progressAt(box: 0)});

    final usecase = FinalizeStudySessionUseCase(
      sessions: sessions,
      progress: progress,
      applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
      clock: _FixedClock(now),
      idGenerator: _SeqIds(),
      recordStreakDay: RecordStreakDayUseCase(
        streaks: _ExplodingStreaks(),
        timeZone: const FixedOffsetTimeZone(id: 'UTC', offset: Duration.zero),
        idGenerator: _SeqIds(),
      ),
    );

    final summary = await usecase(completed(session()));

    expect(summary.reviewedCount, 1);
    expect(sessions.finalized, hasLength(1));
    expect(sessions.finalized.single.state, SessionState.completed);
  });

  // `int-8`: the result screen's streak card had never been fed by anything —
  // `StudyResultGoalStatus` was built only in the `MX-VIS-054` parity override.
  // This is the read-back that finally puts real values on the summary.
  test('the summary reports the streak this session extended', () async {
    final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
    final progress = _FakeProgress({'c1': _progressAt(box: 0)});
    final streaks = _RecordingStreaks(<String>['2026-07-22', '2026-07-23']);
    final goals = _FakeGoals(target: 5);
    const zone = FixedOffsetTimeZone(id: 'UTC', offset: Duration.zero);

    final summary = await FinalizeStudySessionUseCase(
      sessions: sessions,
      progress: progress,
      applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
      clock: _FixedClock(now),
      idGenerator: _SeqIds(),
      recordStreakDay: RecordStreakDayUseCase(
        streaks: streaks,
        timeZone: zone,
        idGenerator: _SeqIds(),
      ),
      trackDailyGoal: TrackDailyGoalUseCase(
        goals: goals,
        timeZone: zone,
        idGenerator: _SeqIds(),
      ),
      streaks: streaks,
      timeZone: zone,
    )(completed(session()));

    final status = summary.goalStatus;
    expect(status, isNotNull);
    // The 22nd and 23rd were already qualified; finalizing on the 24th (the
    // fixed test clock) makes three consecutive days.
    expect(status!.streakDays, 3);
    expect(status.goalDoneCards, 1);
    expect(status.goalTargetCards, 5);
  });

  test('no configured goal leaves the summary without a streak card', () async {
    final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
    final progress = _FakeProgress({'c1': _progressAt(box: 0)});
    final streaks = _RecordingStreaks(const <String>[]);
    const zone = FixedOffsetTimeZone(id: 'UTC', offset: Duration.zero);

    final summary = await FinalizeStudySessionUseCase(
      sessions: sessions,
      progress: progress,
      applyTerminalOutcome: ApplyTerminalOutcomeUseCase(repository: progress),
      clock: _FixedClock(now),
      idGenerator: _SeqIds(),
      trackDailyGoal: TrackDailyGoalUseCase(
        goals: _FakeGoals(target: null),
        timeZone: zone,
        idGenerator: _SeqIds(),
      ),
      streaks: streaks,
      timeZone: zone,
    )(completed(session()));

    // The card shows today's target; with no goal there is nothing to show.
    expect(summary.goalStatus, isNull);
    expect(summary.reviewedCount, 1);
  });

  test('a new card finishing the pipeline activates to Box 1 once', () async {
    final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
    final progress = _FakeProgress({'c1': _progressAt(box: 0)});

    final summary = await build(sessions, progress).call(completed(session()));

    expect(progress.boxOf('c1'), 1);
    expect(progress.appliedKeys, <String>{'terminal:s1:c1'});
    expect(sessions.finalized, hasLength(1));
    expect(sessions.finalized.single.state, SessionState.completed);
    expect(sessions.finalized.single.expectedRevision, 3);
    expect(summary.reviewedCount, 1);
    expect(summary.correctCount, 1);
  });

  test(
    'SRS8-010: a sticky-lapse activated card demotes exactly one box',
    () async {
      final sessions = _FakeSessions(
        // Failed then mastered in a retry round → sticky wrong.
        attempts: [_attempt('c1', 'wrong'), _attempt('c1', 'correct')],
      );
      final progress = _FakeProgress({'c1': _progressAt(box: 2)});

      await build(
        sessions,
        progress,
      ).call(completed(session(type: SessionType.dueReview)));

      expect(progress.boxOf('c1'), 1, reason: 'Box 2 wrong → Box 1 (SRS8-018)');
      expect(progress.lapsesOf('c1'), 1);
    },
  );

  test('an activated card answered correct promotes one box', () async {
    final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
    final progress = _FakeProgress({'c1': _progressAt(box: 2)});

    await build(
      sessions,
      progress,
    ).call(completed(session(type: SessionType.dueReview)));

    expect(progress.boxOf('c1'), 3, reason: 'Box 2 correct → Box 3 (SRS8-017)');
  });

  test(
    'a finalize retry schedules each card exactly once (idempotent)',
    () async {
      final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
      final progress = _FakeProgress({'c1': _progressAt(box: 0)});
      final useCase = build(sessions, progress);

      await useCase.call(completed(session()));
      await useCase.call(completed(session()));

      // The terminal idempotency key made the second apply a no-op: the card
      // activated to Box 1 and did not advance again.
      expect(progress.boxOf('c1'), 1);
      expect(progress.applyCount, 1);
    },
  );

  test(
    'SRS8-027: a practice session schedules no SRS but still finalizes',
    () async {
      final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
      final progress = _FakeProgress({'c1': _progressAt(box: 2)});

      await build(sessions, progress).call(
        completed(session(type: SessionType.practice, scheduleSrs: false)),
      );

      expect(progress.applyCount, 0, reason: 'no SRS scheduling for practice');
      expect(progress.boxOf('c1'), 2);
      expect(sessions.finalized, hasLength(1));
    },
  );

  test(
    'SRS8-002: an incomplete pipeline does not activate (rejected)',
    () async {
      final sessions = _FakeSessions(attempts: const []);
      final progress = _FakeProgress(const {});
      final incomplete = StudyRuntimeState(
        session: session(),
        stages: const <StudyModeType>[StudyModeType.guess],
        position: const SessionPosition(
          stageIndex: 0,
          roundIndex: 1,
          roundCardIds: <String>['c1'],
          cardPosition: 0,
          failedCardIds: <String>[],
        ),
        cardsById: const {},
      );
      expect(build(sessions, progress).call(incomplete), throwsA(anything));
    },
  );

  test(
    'SRS8-012: a stale progress version surfaces a typed conflict',
    () async {
      final sessions = _FakeSessions(attempts: [_attempt('c1', 'correct')]);
      final progress = _FakeProgress({'c1': _progressAt(box: 2)})
        ..failWithConflict = true;

      // Finalize must not swallow a revision conflict — it stays recoverable
      // (finalize-study-session.md §6), never a silent last-write-wins.
      await expectLater(
        build(
          sessions,
          progress,
        ).call(completed(session(type: SessionType.dueReview))),
        throwsA(isA<ConflictFailure>()),
      );
    },
  );
}

StudyAttempt _attempt(String cardId, String outcome) => StudyAttempt(
  id: 'a-$cardId-$outcome',
  idempotencyKey: 'k-$cardId-$outcome',
  cardId: cardId,
  sessionId: 's1',
  modeId: 'guess',
  outcome: outcome,
  evidenceJson: '{}',
  isTerminal: false,
  createdAt: DateTime.utc(2026, 7, 24, 8),
);

LearningProgress _progressAt({required int box, DateTime? srsActivatedAt}) =>
    LearningProgress(
      id: 'p',
      cardId: 'c1',
      box: box,
      dueAt: box == 0 ? null : DateTime.utc(2026, 7, 24),
      policyId: leitner8BoxPolicyId,
      policyVersion: 1,
      revision: 0,
      repetitionCount: 0,
      lapseCount: 0,
      lastTerminalAttemptId: null,
      srsActivatedAt: srsActivatedAt,
      lastReviewedAt: null,
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );

class _FixedClock implements AppClock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${_n++}';
}

class _FakeSessions implements StudySessionRepository {
  _FakeSessions({required List<StudyAttempt> attempts}) : _attempts = attempts;
  final List<StudyAttempt> _attempts;
  final List<({SessionState state, int expectedRevision})> finalized = [];

  @override
  Future<List<StudyAttempt>> attempts(String sessionId) async => _attempts;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #finalizeSession) {
      finalized.add((
        state: invocation.namedArguments[#terminalState] as SessionState,
        expectedRevision: invocation.namedArguments[#expectedRevision] as int,
      ));
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeProgress implements LearningProgressRepository {
  _FakeProgress(Map<String, LearningProgress> initial)
    : _byCard = Map<String, LearningProgress>.of(initial);

  final Map<String, LearningProgress> _byCard;
  final Set<String> appliedKeys = <String>{};
  int applyCount = 0;

  /// When set, applying a schedule raises the repository's revision conflict
  /// (SRS8-012): a stale writer must surface a typed failure, not last-write-win.
  bool failWithConflict = false;

  int? boxOf(String cardId) => _byCard[cardId]?.box;
  int? lapsesOf(String cardId) => _byCard[cardId]?.lapseCount;

  @override
  Future<LearningProgress?> findByCard(String cardId) async => _byCard[cardId];

  @override
  Future<void> applyScheduledOutcome({
    required StudyAttempt attempt,
    required int newBox,
    required DateTime? newDueAt,
    required int repetitionCount,
    required int lapseCount,
    required DateTime? srsActivatedAt,
    required DateTime lastReviewedAt,
    required int expectedRevision,
    required DateTime updatedAt,
  }) async {
    if (failWithConflict) {
      throw ConflictFailure(code: 'revision', entity: 'learning_progress');
    }
    // Exactly-once by the terminal idempotency key.
    if (!appliedKeys.add(attempt.idempotencyKey)) return;
    applyCount++;
    final current = _byCard[attempt.cardId]!;
    _byCard[attempt.cardId] = LearningProgress(
      id: current.id,
      cardId: current.cardId,
      box: newBox,
      dueAt: newDueAt,
      policyId: current.policyId,
      policyVersion: current.policyVersion,
      revision: current.revision + 1,
      repetitionCount: repetitionCount,
      lapseCount: lapseCount,
      lastTerminalAttemptId: attempt.id,
      // Stored, not dropped: the fake has to round-trip what the real store
      // now keeps, or a regression that stops writing them would pass here.
      srsActivatedAt: srsActivatedAt,
      lastReviewedAt: lastReviewedAt,
      createdAt: current.createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A streak store that fails every write, for the isolation test above.
class _ExplodingStreaks implements StreakRepository {
  @override
  Future<void> recordDay(StreakDay day, {required DateTime recordedAt}) async {
    throw StateError('streak store unavailable');
  }

  @override
  Future<List<StreakDay>> daysBetween(String from, String to) async =>
      const <StreakDay>[];

  @override
  Future<int> countDays() async => 0;
}

/// A streak store seeded with prior qualified days, recording new ones.
class _RecordingStreaks implements StreakRepository {
  _RecordingStreaks(List<String> seeded)
    : days = <StreakDay>[
        for (final date in seeded)
          StreakDay(
            id: date,
            localDate: date,
            timezoneId: 'UTC',
            qualifiedSource: 'seed',
            sourceVersion: 1,
          ),
      ];

  final List<StreakDay> days;

  @override
  Future<void> recordDay(StreakDay day, {required DateTime recordedAt}) async {
    if (days.any((stored) => stored.localDate == day.localDate)) return;
    days.add(day);
  }

  @override
  Future<List<StreakDay>> daysBetween(String from, String to) async => days
      .where(
        (d) =>
            d.localDate.compareTo(from) >= 0 && d.localDate.compareTo(to) <= 0,
      )
      .toList();

  @override
  Future<int> countDays() async => days.length;
}

/// A goal store with an optional configured target.
class _FakeGoals implements StudyGoalRepository {
  _FakeGoals({required this.target});

  final int? target;
  final Map<String, GoalDayProgress> buckets = <String, GoalDayProgress>{};

  @override
  Future<DailyGoal?> latestGoal() async {
    final target = this.target;
    if (target == null) return null;
    return DailyGoal(
      id: 'g1',
      isEnabled: true,
      targetCardCount: target,
      effectiveFromLocalDate: '2026-01-01',
      timezoneId: 'UTC',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<GoalDayProgress?> dayProgress(String localDate) async =>
      buckets[localDate];

  @override
  Future<void> recordDayProgress(GoalDayProgress progress) async {
    buckets[progress.localDate] = progress;
  }

  @override
  Stream<GoalDayProgress?> watchDayProgress(String localDate) =>
      Stream<GoalDayProgress?>.value(buckets[localDate]);

  @override
  Future<void> createGoal(DailyGoal goal) async {}

  @override
  Future<void> updateGoal(
    String goalId, {
    required bool isEnabled,
    required int targetCardCount,
    required DateTime updatedAt,
  }) async {}
}

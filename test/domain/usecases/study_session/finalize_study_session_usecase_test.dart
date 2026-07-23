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

LearningProgress _progressAt({required int box}) => LearningProgress(
  id: 'p',
  cardId: 'c1',
  box: box,
  dueAt: box == 0 ? null : DateTime.utc(2026, 7, 24),
  policyId: Srs8BoxPolicy.policyId,
  policyVersion: 1,
  revision: 0,
  repetitionCount: 0,
  lapseCount: 0,
  lastTerminalAttemptId: null,
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
      createdAt: current.createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_timer_state.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// Persists the paused checkpoint a learner leaves behind
/// (`exit-study-session.md` §3 "Persist paused checkpoint", §5).
///
/// Exit is not finalize: the session stays active and resumable, and every
/// committed answer is already on disk. What is *not* on disk is the Recall
/// countdown, which §5 asks to survive the exit and resume where it stopped.
/// So this writes the position the runtime is on plus that countdown, over the
/// same session-keyed checkpoint row the answer path maintains.
class PauseStudySessionUseCase {
  const PauseStudySessionUseCase({
    required StudySessionRepository sessions,
    required AppClock clock,
  }) : _sessions = sessions,
       _clock = clock;

  final StudySessionRepository _sessions;
  final AppClock _clock;

  Future<void> call(
    StudyRuntimeState runtime, {
    SessionTimerState? timer,
  }) async {
    final position = runtime.position;
    final sessionId = runtime.session.id;
    await _sessions.saveCheckpoint(
      SessionCheckpoint(
        // The same deterministic id the answer path uses, so a pause updates
        // that row instead of racing it.
        id: 'cp-$sessionId',
        sessionId: sessionId,
        stageIndex: position.stageIndex,
        roundIndex: position.roundIndex,
        cardPosition: position.cardPosition,
        failedCardIds: position.failedCardIds,
        timerStateJson: timer?.encode() ?? '{}',
        stateVersion: position.roundIndex + position.cardPosition + 1,
        updatedAt: _clock.nowUtc(),
      ),
    );
  }
}

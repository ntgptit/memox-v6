import 'package:memox_v6/domain/study_session/session_mode_plan.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// The initial round index the start snapshot writes (5.6.2), used to find the
/// current order before any checkpoint exists.
const int _initialRoundIndex = 1;

/// Loads the active session's runtime read model (WBS 5.6.3;
/// `resume-study-session.md` §7). Presentation depends on this use case, never
/// the repository directly. It projects the committed snapshot + checkpoint +
/// current round order into a [StudyRuntimeState], or `null` when no session is
/// active. newLearning/dueReview plans are re-resolved from the type (they are
/// deterministic, so this matches the persisted plan; practice/relearn are not
/// startable yet, so an active session is always one of these).
class LoadStudyRuntimeUseCase {
  const LoadStudyRuntimeUseCase({
    required StudySessionRepository sessions,
    SessionModePlanResolver planResolver = const SessionModePlanResolver(),
  }) : _sessions = sessions,
       _planResolver = planResolver;

  final StudySessionRepository _sessions;
  final SessionModePlanResolver _planResolver;

  Future<StudyRuntimeState?> call() async {
    final session = await _sessions.watchActive().first;
    if (session == null) return null;

    final plan = _planResolver.resolve(type: session.type);
    final cardSnapshots = await _sessions.cardSnapshots(session.id);
    final checkpoint = await _sessions.checkpoint(session.id);
    final currentOrder = await _sessions.roundOrder(
      session.id,
      checkpoint?.roundIndex ?? _initialRoundIndex,
    );
    if (currentOrder == null) return null;

    return StudyRuntimeState.assemble(
      session: session,
      stages: plan.stages,
      cardSnapshots: cardSnapshots,
      currentOrder: currentOrder,
      checkpoint: checkpoint,
    );
  }
}

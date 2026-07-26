import 'package:memox_v6/domain/study_session/study_session.dart';

/// What tapping `Resume session` resolved to
/// (`continue-session-from-today.md` §2).
sealed class ContinueSessionOutcome {
  const ContinueSessionOutcome();
}

/// The session is still resumable and the learner should be handed to its
/// checkpoint (flow node D → G).
class ResumeAtCheckpoint extends ContinueSessionOutcome {
  const ResumeAtCheckpoint(this.session);

  final StudySession session;
}

/// There is no active session any more — it was finalized or abandoned
/// somewhere else while Today held a snapshot of it (flow node E).
///
/// §6: "Không tạo session mới." This is the branch that must not quietly
/// start one: the learner asked to continue something, and the honest answer
/// is that it is over.
class SessionNoLongerResumable extends ContinueSessionOutcome {
  const SessionNoLongerResumable();
}

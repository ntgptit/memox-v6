import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/today/continue_session_outcome.dart';

/// Revalidates the paused session before Today hands off to it
/// (WBS 5.7.3; `continue-session-from-today.md`).
///
/// §1: "Session được resolve lại trước navigation." The CTA was rendered from
/// a projection composed when Today loaded; between then and the tap the
/// session can be finalized on the study screen, abandoned, or completed after
/// a restart. Navigating on the stale snapshot would land on a study route
/// with nothing to resume.
///
/// It creates nothing (§6). The only two answers are "still there" and
/// "gone" — anything else would be this flow inventing a session, which is
/// the Start Session contract's job and not this one's.
class ContinueSessionFromTodayUseCase {
  const ContinueSessionFromTodayUseCase({
    required StudySessionRepository sessions,
  }) : _sessions = sessions;

  final StudySessionRepository _sessions;

  Future<ContinueSessionOutcome> call() async {
    // A → B → C: the store, not the projection. `watchActive` is the same
    // read the projection composed from, so "resumable" means exactly what it
    // meant when the CTA appeared — only fresher.
    final active = await _sessions.watchActive().first;
    if (active == null) return const SessionNoLongerResumable();
    return ResumeAtCheckpoint(active);
  }
}

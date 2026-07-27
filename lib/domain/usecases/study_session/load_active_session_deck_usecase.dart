import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// The deck a running session belongs to, for the prompt that offers to resume
/// it (`start-study-session.md` §5, "Different active session").
///
/// The decision table asks that row to *name* the deck and scope before
/// offering Resume, and the prompt could not: the start conflict says only
/// that some session exists, so a learner who left a session in one deck and
/// tapped Study in another was asked to continue "your session" with no way
/// to tell which one Resume would open.
///
/// Null when there is no active session, or when its deck cannot be resolved —
/// a deck deleted under a running session is `resume-study-session.md` §6's
/// case, and the prompt falls back to the unqualified copy rather than naming
/// something that is gone.
class LoadActiveSessionDeckUseCase {
  const LoadActiveSessionDeckUseCase({
    required StudySessionRepository sessions,
    required DeckRepository decks,
  }) : _sessions = sessions,
       _decks = decks;

  final StudySessionRepository _sessions;
  final DeckRepository _decks;

  Future<String?> deckName() async {
    final active = await _sessions.activeSession();
    if (active == null) return null;
    final deck = await _decks.findById(active.deckId);
    return deck?.name;
  }
}

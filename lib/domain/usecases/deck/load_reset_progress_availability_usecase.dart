import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/deck/reset_progress_availability.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// Whether resetting [deckId]'s progress would disturb a running session
/// (WBS 6.1; `reset-deck-progress.md` §5, §10, §12).
///
/// The reset covers the deck's whole subtree. What a session covers depends on
/// its scope: a `leaf` session reads the cards of its own deck, a `subtree`
/// session everything below it. The two overlap exactly when one deck is the
/// other's ancestor-or-self, so that is the whole test — no card ids need
/// comparing.
class LoadResetProgressAvailabilityUseCase {
  const LoadResetProgressAvailabilityUseCase({
    required DeckRepository decks,
    required StudySessionRepository sessions,
  }) : _decks = decks,
       _sessions = sessions;

  final DeckRepository _decks;
  final StudySessionRepository _sessions;

  Future<ResetProgressAvailability> call(String deckId) async {
    final session = await _sessions.activeSession();
    if (session == null) return ResetProgressAvailability.available;

    // The session's deck is inside the reset scope: its cards are being reset
    // whatever the session's own scope is.
    if (await _isWithin(session.deckId, ancestor: deckId)) {
      return ResetProgressAvailability.blockedByActiveSession;
    }

    // The other direction only matters for a subtree session, which reaches
    // down into the deck being reset. A leaf session never leaves its deck.
    if (session.scope == SessionScope.subtree &&
        await _isWithin(deckId, ancestor: session.deckId)) {
      return ResetProgressAvailability.blockedByActiveSession;
    }

    return ResetProgressAvailability.available;
  }

  /// Whether [deckId] is [ancestor] itself or sits below it.
  Future<bool> _isWithin(String deckId, {required String ancestor}) async {
    if (deckId == ancestor) return true;
    final chain = await _decks.ancestors(deckId);
    return chain.any((deck) => deck.id == ancestor);
  }
}

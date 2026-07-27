import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_deletion_impact.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';

/// Loads the delete impact for a deck (WBS 6.1; `delete-deck.md`).
///
/// Read-only: it derives the Empty/Leaf/Parent state from the direct content
/// counts and totals the subtree cards + nested decks the delete would remove.
/// The confirm dialog shows this before the (irreversible) delete runs.
class LoadDeckDeletionImpactUseCase {
  const LoadDeckDeletionImpactUseCase({
    required DeckRepository decks,
    required StudySessionRepository sessions,
  }) : _decks = decks,
       _sessions = sessions;

  final DeckRepository _decks;
  final StudySessionRepository _sessions;

  Future<DeckDeletionImpact> call(String deckId) async {
    final counts = await _decks.contentCounts(deckId);
    final cardCount = await _decks.countSubtreeCards(deckId);
    final deckCount = await _decks.countSubtreeDecks(deckId);
    final studied = await _decks.countSubtreeStudiedCards(deckId);
    return DeckDeletionImpact(
      state: deriveDeckContentState(counts),
      cardCount: cardCount,
      deckCount: deckCount,
      studiedCardCount: studied,
      endsRunningSession: await _endsRunningSession(deckId),
    );
  }

  /// Whether a running session would go with the deck.
  ///
  /// Only one direction of the overlap test
  /// `LoadResetProgressAvailabilityUseCase` documents applies here: a delete
  /// removes this deck's subtree, so a session is destroyed when its *own*
  /// deck is inside it. A subtree session rooted above keeps its row and can
  /// still finish from its snapshot.
  Future<bool> _endsRunningSession(String deckId) async {
    final session = await _sessions.activeSession();
    if (session == null) return false;
    if (session.deckId == deckId) return true;
    final chain = await _decks.ancestors(session.deckId);
    return chain.any((deck) => deck.id == deckId);
  }
}

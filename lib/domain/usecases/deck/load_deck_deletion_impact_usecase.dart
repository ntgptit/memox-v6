import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_deletion_impact.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Loads the delete impact for a deck (WBS 6.1; `delete-deck.md`).
///
/// Read-only: it derives the Empty/Leaf/Parent state from the direct content
/// counts and totals the subtree cards + nested decks the delete would remove.
/// The confirm dialog shows this before the (irreversible) delete runs.
class LoadDeckDeletionImpactUseCase {
  const LoadDeckDeletionImpactUseCase({required DeckRepository decks})
    : _decks = decks;

  final DeckRepository _decks;

  Future<DeckDeletionImpact> call(String deckId) async {
    final counts = await _decks.contentCounts(deckId);
    final cardCount = await _decks.countSubtreeCards(deckId);
    final deckCount = await _decks.countSubtreeDecks(deckId);
    return DeckDeletionImpact(
      state: deriveDeckContentState(counts),
      cardCount: cardCount,
      deckCount: deckCount,
    );
  }
}

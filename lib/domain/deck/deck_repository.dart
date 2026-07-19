import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';

/// Deck repository port (WBS 4.6A).
///
/// Conflict contract: sibling-name collisions surface as
/// `ConflictFailure(code: 'duplicate')`; writes that would mix child
/// decks with cards as `code: 'deck-mixed-content'`; cyclic moves as
/// `code: 'deck-cycle'`. All writes are atomic — a rejected write
/// leaves no partial state.
abstract interface class DeckRepository {
  Future<void> createDeck(Deck deck);

  Future<Deck?> findById(String id);

  Stream<List<Deck>> watchRoots(String languagePairId);

  Stream<List<Deck>> watchChildren(String parentId);

  Future<void> rename(
    String deckId, {
    required String name,
    required String normalizedName,
    required DateTime updatedAt,
  });

  Future<void> move(
    String deckId, {
    required String? newParentId,
    required DateTime updatedAt,
  });

  Future<void> delete(String deckId);

  /// Direct child-deck and active-card counts for state derivation
  /// (`deriveDeckContentState`).
  Future<DeckContentCounts> contentCounts(String deckId);

  /// Number of decks (any depth) owned by [languagePairId]; the
  /// language-pair removal guard reads this.
  Future<int> countForLanguagePair(String languagePairId);
}

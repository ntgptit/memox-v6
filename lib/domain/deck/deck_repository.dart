import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
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

  /// Root decks with their list-surface counters (library rows).
  Stream<List<DeckSummary>> watchRootSummaries(String languagePairId);

  Stream<List<Deck>> watchChildren(String parentId);

  /// The ancestor chain for [deckId], ordered root → … → the deck itself —
  /// the nested-deck breadcrumb path (WBS 6.2). Returns a single-element list
  /// (the deck) for a root deck, or an empty list when the deck is missing.
  Future<List<Deck>> ancestors(String deckId);

  /// Decks in [languagePairId] that [movingDeckId] can be reparented under —
  /// the move-destination picker's eligible list (WBS 6.2). Excludes the
  /// moving deck's own subtree (a cycle), decks holding direct cards (4.3
  /// mixed content) and the current parent (a no-op). Library root is not a
  /// row here — the caller offers it separately.
  Future<List<Deck>> moveDestinations(
    String languagePairId, {
    required String movingDeckId,
  });

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

  /// Active cards in [deckId]'s whole subtree (the Parent summary's
  /// aggregate count in `open-deck.md` §5).
  Future<int> countSubtreeCards(String deckId);

  /// Count of nested decks below [deckId] (all descendants, excluding the deck
  /// itself) — the delete/reset impact summary (`delete-deck.md` §4).
  Future<int> countSubtreeDecks(String deckId);

  /// Number of decks (any depth) owned by [languagePairId]; the
  /// language-pair removal guard reads this.
  Future<int> countForLanguagePair(String languagePairId);
}

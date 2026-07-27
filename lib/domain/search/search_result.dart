/// The kind of Library object a search result points at (WBS 10.1).
enum SearchResultType { deck, card }

/// One ranked Library search hit (WBS 10.1; `search-library-content.md`,
/// `search-rank-v1`). Carries a stable id + type + owning deck so the caller
/// can open the exact object even when names collide; the source object is
/// never mutated by search.
class SearchResult {
  const SearchResult({
    required this.id,
    required this.type,
    required this.displayText,
    required this.deckId,
    this.isHidden = false,
  });

  final String id;
  final SearchResultType type;

  /// The matched object's display text (a card's term or a deck's name).
  final String displayText;

  /// The owning deck — the card's deck, or the deck itself — for path
  /// resolution when the caller opens the result.
  final String deckId;

  /// Whether a card hit is hidden from study (`hide-flashcard.md` §1). Always
  /// false for a deck, which has no visibility of its own. The row carries it
  /// so a hidden card reads as hidden rather than looking like any other hit —
  /// search is where a learner goes to find one back.
  final bool isHidden;
}

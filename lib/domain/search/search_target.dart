/// Why a search result can no longer be opened (`open-search-result.md` §2).
enum SearchTargetGoneReason {
  /// The object was deleted after the search ran.
  deleted,

  /// The card was hidden after the search ran, and the visibility filter the
  /// list was built with excludes hidden cards. A learner who asked to see
  /// hidden cards is not in this branch — for them the row is still valid.
  hidden,
}

/// What resolving a search result against the store right now yields
/// (`open-search-result.md` §1: "Object được revalidate ngay trước
/// navigation").
sealed class SearchTargetResolution {
  const SearchTargetResolution();
}

/// The object is still there and can be opened.
final class SearchTargetReady extends SearchTargetResolution {
  const SearchTargetReady({required this.deckId, required this.moved});

  /// The owning deck **as it is now** — §2's "Moved → Use current path", not
  /// the deck the result was indexed under.
  final String deckId;

  /// Whether that differs from the path the result carried, which §2 pairs
  /// with a notification so the learner is not silently sent elsewhere.
  final bool moved;
}

/// The object is gone from the list's point of view; §2 removes the stale
/// result and says why rather than opening a broken route.
final class SearchTargetGone extends SearchTargetResolution {
  const SearchTargetGone(this.reason);

  final SearchTargetGoneReason reason;
}

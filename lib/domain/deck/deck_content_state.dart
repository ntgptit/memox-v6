import 'package:memox_v6/core/errors/app_failure.dart';

/// Current content of one deck (WBS 5.2.1): the derivation inputs.
class DeckContentCounts {
  const DeckContentCounts({
    required this.childDeckCount,
    required this.activeCardCount,
  });

  final int childDeckCount;

  /// Direct cards excluding soft-deleted ones (hidden cards still count
  /// as content).
  final int activeCardCount;
}

/// Canonical deck content states (`deck/README.md` §0). The state is
/// always derived from current content — never stored as a mode.
enum DeckContentState {
  /// No direct cards and no child decks; the content type is unlocked.
  empty,

  /// At least one child deck, no direct cards.
  parent,

  /// At least one direct card, no child decks.
  leaf,
}

/// Derives the canonical state deterministically.
///
/// Mixed content (cards and child decks together) is never a renderable
/// or persistable state — the 4.3 triggers reject every write path that
/// would create it, so observing it means the store is corrupt.
DeckContentState deriveDeckContentState(DeckContentCounts counts) {
  final hasChildren = counts.childDeckCount > 0;
  final hasCards = counts.activeCardCount > 0;
  if (hasChildren && hasCards) {
    throw DataCorruptionFailure(
      entity: 'decks',
      field: 'content-state',
      value: 'mixed',
    );
  }
  if (hasChildren) return DeckContentState.parent;
  if (hasCards) return DeckContentState.leaf;
  return DeckContentState.empty;
}

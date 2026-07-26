import 'package:memox_v6/domain/deck/deck.dart';

/// One library list row: a deck with its list-surface counters (kit
/// deck-card meta line). Counts are direct cards only; subtree totals
/// belong to the deck-detail scope.
///
/// [dueCount] cards are scheduled at or before now; [newCount] cards have
/// never been studied. The kit card shows one status after the card count,
/// prioritising due over new, else "up to date".
class DeckSummary {
  const DeckSummary({
    required this.deck,
    required this.cardCount,
    this.dueCount = 0,
    this.newCount = 0,
    this.masteredCount = 0,
    this.studiableCount = 0,
  });

  final Deck deck;
  final int cardCount;
  final int dueCount;
  final int newCount;

  /// Cards in Box 8. `srs-8-box-policy.md` §3 makes that the mastered box —
  /// "Không xếp lịch tiếp", `dueAt = null`, outside every study queue — so
  /// mastery is read from the box rather than inferred from a review history.
  final int masteredCount;

  /// Cards that can be studied at all: not deleted, not hidden.
  ///
  /// The denominator [masteryFraction] needs, and not [cardCount], which
  /// counts hidden cards too. A deck holding one hidden card could never
  /// reach 100% if the visible ones were measured against the total.
  final int studiableCount;

  /// Mastered share of the studiable cards, `0.0`–`1.0` (kit deck-row
  /// progress bar). An empty deck is zero, not undefined.
  double get masteryFraction =>
      studiableCount == 0 ? 0 : masteredCount / studiableCount;
}

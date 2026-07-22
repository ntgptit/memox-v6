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
  });

  final Deck deck;
  final int cardCount;
  final int dueCount;
  final int newCount;
}

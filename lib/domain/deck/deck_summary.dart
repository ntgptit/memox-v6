import 'package:memox_v6/domain/deck/deck.dart';

/// One library list row: a deck with its list-surface counters (kit
/// deck-card meta line). Counts are direct cards only; subtree totals
/// belong to the deck-detail scope.
class DeckSummary {
  const DeckSummary({required this.deck, required this.cardCount});

  final Deck deck;
  final int cardCount;
}

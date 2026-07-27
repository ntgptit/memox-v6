import 'package:memox_v6/domain/deck/deck.dart';

/// Why a deck cannot receive a card (`add-content-to-deck.md` §1, §3).
enum CardTargetIneligibility {
  /// A Parent: §1 forbids direct cards beside child decks, so the learner has
  /// to choose one of its children instead.
  isParent,

  /// The card's current deck — a move to where it already is.
  sourceDeck;

  static CardTargetIneligibility? parse(String value) => switch (value) {
    'isParent' => CardTargetIneligibility.isParent,
    'sourceDeck' => CardTargetIneligibility.sourceDeck,
    _ => null,
  };
}

/// One row of the card-target picker: a deck, and whether it can take the card.
///
/// §3's ineligible branch is "Disabled · choose child" and §4 draws the Parent
/// row present but disabled. Filtering it out, as this picker did, left a
/// learner unable to tell a Parent they must drill into from a deck that is
/// not there at all — the same defect `int-89` fixed for the deck-move picker.
class CardTarget {
  const CardTarget({required this.deck, this.ineligibility});

  final Deck deck;

  /// Null when the deck can receive the card.
  final CardTargetIneligibility? ineligibility;

  bool get isEligible => ineligibility == null;
}

import 'package:memox_v6/domain/deck/deck.dart';

/// Why a deck cannot receive the deck being moved (`move-deck.md` §5).
enum MoveIneligibility {
  /// The deck being moved (§7: "A deck can't be moved inside itself.").
  self,

  /// Inside the moving deck's own subtree (§7: "Choose a destination outside
  /// this deck.").
  descendant,

  /// A Leaf: §1 forbids mixing cards and child decks (§7: "This deck contains
  /// cards and can't receive a nested deck.").
  holdsCards,

  /// Already the moving deck's parent, so choosing it would change nothing.
  alreadyThere;

  static MoveIneligibility? parse(String value) => switch (value) {
    'self' => MoveIneligibility.self,
    'descendant' => MoveIneligibility.descendant,
    'holdsCards' => MoveIneligibility.holdsCards,
    'alreadyThere' => MoveIneligibility.alreadyThere,
    _ => null,
  };
}

/// One row of the move picker: a deck, and whether it can be chosen.
///
/// `move-deck.md` §3's ineligible branch is "Disabled + helper", not "hide" —
/// §4 draws the blocked rows with their reason beside them and §11 lists
/// "leaf/self/descendant disabled" as states to render. Filtering them out of
/// the query, as this picker did, left a learner unable to tell a deck that
/// holds cards from one that was never there.
class MoveDestination {
  const MoveDestination({required this.deck, this.ineligibility});

  final Deck deck;

  /// Null when the deck can receive the move.
  final MoveIneligibility? ineligibility;

  bool get isEligible => ineligibility == null;
}

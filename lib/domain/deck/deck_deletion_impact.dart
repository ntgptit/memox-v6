import 'package:memox_v6/domain/deck/deck_content_state.dart';

/// The scope a deck delete would remove, for the confirm dialog's impact summary
/// (WBS 6.1; `delete-deck.md` §4). [cardCount]/[deckCount] are the whole subtree
/// (descendant decks exclude the deck itself); [state] picks the copy variant.
class DeckDeletionImpact {
  const DeckDeletionImpact({
    required this.state,
    required this.cardCount,
    required this.deckCount,
    this.studiedCardCount = 0,
  });

  final DeckContentState state;
  final int cardCount;
  final int deckCount;

  /// Cards in the subtree that carry study history — Box 1 and above.
  ///
  /// The third quantity §1 asks the copy to name. Counting progress *rows*
  /// would restate [cardCount]: every card gets one at creation. What the
  /// learner actually loses is the history, and Box 0 means never introduced.
  final int studiedCardCount;
}

import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

/// Open-deck reads (WBS 5.2.4B; `open-deck.md`).
///
/// The screen derives Empty/Leaf/Parent from the two reactive content
/// streams — never from a stored mode — so the §7 transitions (first
/// card → Leaf, last child gone → Empty, …) update in place.
class OpenDeckUseCase {
  const OpenDeckUseCase({
    required DeckRepository decks,
    required FlashcardRepository cards,
  }) : _decks = decks,
       _cards = cards;

  final DeckRepository _decks;
  final FlashcardRepository _cards;

  Future<Deck?> deckById(String deckId) => _decks.findById(deckId);

  Stream<List<Deck>> childrenOf(String deckId) => _decks.watchChildren(deckId);

  /// Active (non-deleted) direct cards; hidden cards still count as
  /// content per the canonical contract.
  Stream<List<Flashcard>> cardsOf(String deckId) => _cards.watchByDeck(deckId);

  /// Aggregate active-card count across the subtree (Parent summary).
  Future<int> subtreeCardCount(String deckId) =>
      _decks.countSubtreeCards(deckId);

  /// The ancestor chain (root → … → the deck), the nested-deck breadcrumb
  /// path (WBS 6.2). Empty when the deck is missing.
  Future<List<Deck>> ancestorsOf(String deckId) => _decks.ancestors(deckId);
}

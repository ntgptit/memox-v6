import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/card_target.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/card_text.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/move_flashcard_result.dart';

/// Moves a card between decks (WBS 5.3.1C; `move-flashcard.md`).
///
/// The card keeps its id, content, child content and current Progress;
/// the source deck and a Parent target are never accepted, a
/// cross-pair target requires the explicit compatibility review flow
/// (blocked here with a typed failure), and the deck-exclusivity
/// triggers keep a Parent target from ever becoming mixed content.
class MoveFlashcardUseCase {
  const MoveFlashcardUseCase({
    required FlashcardRepository cards,
    required DeckRepository decks,
    required AppClock clock,
  }) : _cards = cards,
       _decks = decks,
       _clock = clock;

  final FlashcardRepository _cards;
  final DeckRepository _decks;
  final AppClock _clock;

  /// Moves [cardId] into [targetDeckId].
  ///
  /// §1 runs the duplicate check "trong target context" and §5 requires the
  /// resolution *before* commit, so a card whose term is already in the target
  /// deck comes back as [MoveDuplicatesFound] and stays where it is. Only an
  /// explicit [allowDuplicate] retry commits past it — the same keep-both
  /// decision `create-flashcard.md` gives a new card.
  ///
  /// The pair-wide check the create flow runs would be the wrong one here: a
  /// move never changes the pair, so it can only ever collide inside the deck
  /// it lands in.
  Future<MoveFlashcardResult> call({
    required String cardId,
    required String targetDeckId,
    bool allowDuplicate = false,
  }) async {
    final card = await _cards.findById(cardId);
    if (card == null || card.isDeleted) {
      throw ValidationFailure(field: 'cardId', code: 'not-found');
    }
    if (card.deckId == targetDeckId) {
      throw ValidationFailure(field: 'targetDeckId', code: 'same-deck');
    }

    final target = await _decks.findById(targetDeckId);
    if (target == null) {
      throw ValidationFailure(field: 'targetDeckId', code: 'unknown');
    }
    final source = await _decks.findById(card.deckId);
    if (source != null && target.languagePairId != source.languagePairId) {
      throw ConflictFailure(entity: 'flashcards', code: 'cross-pair-move');
    }

    if (!allowDuplicate) {
      final candidates = await _cards.duplicatesInDeck(
        deckId: targetDeckId,
        normalizedTerm: normalizeCardTerm(card.term),
        excludeCardId: cardId,
      );
      if (candidates.isNotEmpty) return MoveDuplicatesFound(candidates);
    }

    await _cards.move(
      cardId,
      targetDeckId: targetDeckId,
      updatedAt: _clock.nowUtc(),
    );
    return const FlashcardMoved();
  }

  /// The decks [cardId] can move into (WBS 6.5 picker) — Empty/Leaf decks in
  /// the card's own language pair, excluding its current deck. Empty when the
  /// card or its deck is missing; the store still owns the write.
  Future<List<Deck>> destinationsFor(String cardId) async {
    final card = await _cards.findById(cardId);
    if (card == null || card.isDeleted) return const [];
    final deck = await _decks.findById(card.deckId);
    if (deck == null) return const [];
    return _decks.cardMoveTargets(
      deck.languagePairId,
      excludeDeckId: card.deckId,
    );
  }

  /// Every deck in the pair as a target, each carrying the reason it cannot
  /// take the card (`add-content-to-deck.md` §3 node F, §4).
  ///
  /// §3's ineligible branch is "Disabled · choose child" and §4 draws the
  /// Parent row present but disabled. [destinationsFor] returns only the
  /// eligible ones, which left a learner unable to tell a Parent they must
  /// drill into from a deck that is not there at all.
  Future<List<CardTarget>> targetCandidatesFor(String cardId) async {
    final card = await _cards.findById(cardId);
    if (card == null || card.isDeleted) return const [];
    final deck = await _decks.findById(card.deckId);
    if (deck == null) return const [];
    return _decks.cardTargetCandidates(
      deck.languagePairId,
      sourceDeckId: card.deckId,
    );
  }
}

import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

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

  Future<void> call({
    required String cardId,
    required String targetDeckId,
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

    await _cards.move(
      cardId,
      targetDeckId: targetDeckId,
      updatedAt: _clock.nowUtc(),
    );
  }
}

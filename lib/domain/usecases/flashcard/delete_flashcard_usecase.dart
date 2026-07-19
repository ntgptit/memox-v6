import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

/// Deletes a card (WBS 5.3.1C; `delete-flashcard.md`). The explicit
/// confirmation lives in the UI; this command removes child content
/// and current scheduling state and tombstones the card in one
/// transaction. Finalized session summaries are never rewritten, and
/// the last card leaving a deck turns it Leaf → Empty by derivation.
class DeleteFlashcardUseCase {
  const DeleteFlashcardUseCase({
    required FlashcardRepository cards,
    required AppClock clock,
  }) : _cards = cards,
       _clock = clock;

  final FlashcardRepository _cards;
  final AppClock _clock;

  Future<void> deleteCard(String cardId) async {
    final card = await _cards.findById(cardId);
    if (card == null) {
      throw ValidationFailure(field: 'cardId', code: 'not-found');
    }
    if (card.isDeleted) return;
    await _cards.deleteCardCascade(cardId, now: _clock.nowUtc());
  }
}

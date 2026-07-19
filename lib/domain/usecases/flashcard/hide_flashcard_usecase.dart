import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

/// Hides/unhides a card (WBS 5.3.1C; `hide-flashcard.md`): a hidden
/// card keeps its content and Progress/history and stays visible in
/// Leaf lists — only fresh candidate queues exclude it. Unhide
/// restores eligibility per the card's current state.
class HideFlashcardUseCase {
  const HideFlashcardUseCase({
    required FlashcardRepository cards,
    required AppClock clock,
  }) : _cards = cards,
       _clock = clock;

  final FlashcardRepository _cards;
  final AppClock _clock;

  Future<void> setHidden(String cardId, {required bool hidden}) async {
    final card = await _cards.findById(cardId);
    if (card == null || card.isDeleted) {
      throw ValidationFailure(field: 'cardId', code: 'not-found');
    }
    if (card.isHidden == hidden) return;
    await _cards.setHidden(
      cardId,
      isHidden: hidden,
      updatedAt: _clock.nowUtc(),
    );
  }
}

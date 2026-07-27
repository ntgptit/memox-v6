import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/card_detail.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';

/// Composes the Card Detail read projection (WBS 6.x; `view-card-detail.md`).
///
/// The spec is explicit that Card Detail "is not a new aggregate and does not
/// duplicate edit, move, hide, delete, audio, translation, tag or Progress
/// rules". This reads what those flows already store and owns none of it.
class ViewCardDetailUseCase {
  const ViewCardDetailUseCase({
    required FlashcardRepository cards,
    required DeckRepository decks,
    required LearningProgressRepository progress,
  }) : _cards = cards,
       _decks = decks,
       _progress = progress;

  final FlashcardRepository _cards;
  final DeckRepository _decks;
  final LearningProgressRepository _progress;

  /// The projection for [cardId], or null when the card is missing or
  /// tombstoned — a deleted card is unavailable in exactly the way a missing
  /// one is, and the screen's not-found state covers both.
  Future<CardDetail?> call(String cardId) async {
    final card = await _cards.findById(cardId);
    if (card == null || card.isDeleted) return null;

    final deck = await _decks.findById(card.deckId);
    return CardDetail(
      card: card,
      deckName: deck?.name,
      translations: await _cards.translationsOf(cardId),
      tags: await _cards.tagsOf(cardId),
      progress: await _progress.findByCard(cardId),
    );
  }
}

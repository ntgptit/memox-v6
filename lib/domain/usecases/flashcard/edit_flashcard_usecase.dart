import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/card_text.dart';
import 'package:memox_v6/domain/flashcard/edit_flashcard_result.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

/// Edits a card's own content (WBS 5.3.1C; `edit-flashcard.md`).
///
/// Term/meaning stay required and revalidate duplicates across the
/// pair (excluding the card itself); the commit preserves the card id,
/// Deck membership and Progress/history, and the expected content
/// version guards against a silent concurrent last-write-wins.
class EditFlashcardUseCase {
  const EditFlashcardUseCase({
    required FlashcardRepository cards,
    required DeckRepository decks,
    required AppClock clock,
  }) : _cards = cards,
       _decks = decks,
       _clock = clock;

  final FlashcardRepository _cards;
  final DeckRepository _decks;
  final AppClock _clock;

  /// Loads the card to edit with its current content version
  /// (edit-flashcard.md §3 "Load content version"); null when the card is
  /// missing or already deleted (§8 not-found).
  Future<Flashcard?> loadCard(String cardId) async {
    final card = await _cards.findById(cardId);
    if (card == null || card.isDeleted) return null;
    return card;
  }

  Future<EditFlashcardResult> call({
    required String cardId,
    required String term,
    required String primaryMeaning,
    required int expectedContentVersion,
    bool allowDuplicate = false,
  }) async {
    final displayTerm = validateCardText(term, field: 'term');
    final displayMeaning = validateCardText(
      primaryMeaning,
      field: 'primaryMeaning',
    );

    final card = await _cards.findById(cardId);
    if (card == null || card.isDeleted) {
      throw ValidationFailure(field: 'cardId', code: 'not-found');
    }

    final normalizedTerm = normalizeCardTerm(displayTerm);
    if (!allowDuplicate) {
      final deck = await _decks.findById(card.deckId);
      if (deck == null) {
        throw ValidationFailure(field: 'deckId', code: 'unknown');
      }
      final candidates = await _cards.duplicateCandidates(
        languagePairId: deck.languagePairId,
        normalizedTerm: normalizedTerm,
      );
      final others = candidates.where((c) => c.id != cardId).toList();
      if (others.isNotEmpty) {
        return EditDuplicateCandidatesFound(others);
      }
    }

    final updated = await _cards.editCardContent(
      cardId,
      term: displayTerm,
      normalizedTerm: normalizedTerm,
      primaryMeaning: displayMeaning,
      expectedContentVersion: expectedContentVersion,
      now: _clock.nowUtc(),
    );
    return FlashcardEdited(updated);
  }
}

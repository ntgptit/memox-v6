import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/flashcard/card_text.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

/// Additional-translation management (WBS 5.3.1B;
/// `manage-card-translations.md`).
///
/// The primary meaning stays a required Create/Edit field and cannot be
/// touched here. Additional entries are nonblank, unique by normalized
/// text against the primary and each other, and keep an explicit
/// contiguous order; every mutation commits with the Card
/// content-version bump.
class ManageCardTranslationsUseCase {
  const ManageCardTranslationsUseCase({required FlashcardRepository cards})
    : _cards = cards;

  final FlashcardRepository _cards;

  Future<List<CardTranslation>> translationsOf(String cardId) {
    return _cards.translationsOf(cardId);
  }

  /// Validates and appends a translation at the end of the order.
  Future<CardTranslation> addTranslation({
    required String translationId,
    required String cardId,
    required String languageCode,
    required String rawText,
    required DateTime now,
  }) async {
    final text = validateCardText(rawText, field: 'translation');
    await _rejectNormalizedDuplicate(cardId, text, exceptId: null);

    final siblings = await _cards.translationsOf(cardId);
    final translation = CardTranslation(
      id: translationId,
      cardId: cardId,
      languageCode: languageCode,
      text: text,
      displayOrder: siblings.length,
    );
    await _cards.addCardTranslation(translation, now: now);
    return translation;
  }

  /// Validates and rewrites one translation's text in place.
  Future<void> editTranslation({
    required String translationId,
    required String cardId,
    required String rawText,
    required DateTime now,
  }) async {
    final text = validateCardText(rawText, field: 'translation');
    await _rejectNormalizedDuplicate(cardId, text, exceptId: translationId);
    await _cards.editCardTranslationText(
      translationId,
      cardId: cardId,
      text: text,
      now: now,
    );
  }

  /// Removes a translation; surviving orders stay contiguous.
  Future<void> removeTranslation({
    required String translationId,
    required String cardId,
    required DateTime now,
  }) {
    return _cards.removeCardTranslation(
      translationId,
      cardId: cardId,
      now: now,
    );
  }

  /// Applies a complete permutation of the card's translations; a
  /// partial or foreign id set is a typed validation failure.
  Future<void> reorderTranslations({
    required String cardId,
    required List<String> orderedTranslationIds,
    required DateTime now,
  }) async {
    final current = await _cards.translationsOf(cardId);
    final currentIds = current.map((t) => t.id).toSet();
    final requested = orderedTranslationIds.toSet();
    if (requested.length != orderedTranslationIds.length ||
        requested.length != currentIds.length ||
        !requested.containsAll(currentIds)) {
      throw ValidationFailure(
        field: 'translationOrder',
        code: 'incomplete-order',
      );
    }
    await _cards.reorderCardTranslations(
      cardId,
      orderedTranslationIds: orderedTranslationIds,
      now: now,
    );
  }

  /// Blocks a normalized duplicate of the primary meaning or another
  /// translation (`This translation is already on the card.`).
  Future<void> _rejectNormalizedDuplicate(
    String cardId,
    String text, {
    required String? exceptId,
  }) async {
    final normalized = normalizeCardTerm(text);

    final card = await _cards.findById(cardId);
    if (card == null) {
      throw ValidationFailure(field: 'cardId', code: 'not-found');
    }
    if (normalizeCardTerm(card.primaryMeaning) == normalized) {
      throw ConflictFailure(
        entity: 'flashcard_translations',
        code: 'duplicate-translation',
      );
    }
    final siblings = await _cards.translationsOf(cardId);
    for (final sibling in siblings) {
      if (sibling.id == exceptId) continue;
      if (normalizeCardTerm(sibling.text) == normalized) {
        throw ConflictFailure(
          entity: 'flashcard_translations',
          code: 'duplicate-translation',
        );
      }
    }
  }
}

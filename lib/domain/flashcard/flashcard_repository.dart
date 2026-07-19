import 'package:memox_v6/domain/flashcard/card_audio_ref.dart';
import 'package:memox_v6/domain/flashcard/card_tag.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/new_card_content.dart';

/// Flashcard repository port (WBS 4.6A).
///
/// `createCard` is schema-v1 atomic operation 1: card + child content +
/// initial Box 0 progress commit in one transaction, or nothing
/// persists. The card id is the idempotency key — a retry that finds
/// the id already stored returns success without duplicating. Deck
/// exclusivity violations surface as
/// `ConflictFailure(code: 'deck-mixed-content')`.
abstract interface class FlashcardRepository {
  Future<void> createCard(NewCardContent content);

  /// Active cards across the pair whose normalized term matches —
  /// the duplicate-candidate set (`resolve-duplicate-flashcard.md`).
  Future<List<Flashcard>> duplicateCandidates({
    required String languagePairId,
    required String normalizedTerm,
  });

  Future<Flashcard?> findById(String id);

  Future<List<Flashcard>> pageByDeck(
    String deckId, {
    required int limit,
    required int offset,
  });

  Stream<List<Flashcard>> watchByDeck(String deckId);

  Future<void> setHidden(
    String cardId, {
    required bool isHidden,
    required DateTime updatedAt,
  });

  Future<void> softDelete(String cardId, {required DateTime deletedAt});

  Future<void> restore(String cardId, {required DateTime updatedAt});

  Future<void> move(
    String cardId, {
    required String targetDeckId,
    required DateTime updatedAt,
  });

  /// Rewrites the card's own content, guarded by the expected content
  /// version so a concurrent edit never last-write-wins silently
  /// (edit-flashcard.md); the stored version increments on success.
  Future<Flashcard> editCardContent(
    String cardId, {
    required String term,
    required String normalizedTerm,
    required String primaryMeaning,
    required int expectedContentVersion,
    required DateTime now,
  });

  /// Deletes child content and current scheduling state and tombstones
  /// the card row atomically (delete-flashcard.md); finalized session
  /// history is untouched.
  Future<void> deleteCardCascade(String cardId, {required DateTime now});

  // --- Additional translations (5.3.1B) -------------------------------
  // Every child mutation commits atomically together with the owning
  // card's content-version bump (manage-card-translations.md).

  Future<List<CardTranslation>> translationsOf(String cardId);

  Future<void> addCardTranslation(
    CardTranslation translation, {
    required DateTime now,
  });

  Future<void> editCardTranslationText(
    String translationId, {
    required String cardId,
    required String text,
    required DateTime now,
  });

  /// Removes one translation and resequences the survivors so orders
  /// stay contiguous after Save.
  Future<void> removeCardTranslation(
    String translationId, {
    required String cardId,
    required DateTime now,
  });

  /// Applies a complete permutation of the card's translations.
  Future<void> reorderCardTranslations(
    String cardId, {
    required List<String> orderedTranslationIds,
    required DateTime now,
  });

  // --- Tags (TAG-001..006) --------------------------------------------

  Future<List<CardTag>> tagsOf(String cardId);

  /// Finds the tag owning [normalizedName] or creates it with
  /// [newTagId]/[displayName]; concurrent same-label creation resolves
  /// through the unique constraint to the existing tag.
  Future<CardTag> resolveTagByLabel({
    required String displayName,
    required String normalizedName,
    required String newTagId,
    required DateTime now,
  });

  /// Attaches a tag (idempotent, TAG-004) and bumps the card version.
  Future<void> attachCardTag(
    String cardId, {
    required String tagId,
    required DateTime now,
  });

  Future<void> detachCardTag(
    String cardId, {
    required String tagId,
    required DateTime now,
  });

  /// Deletes the tag only when no associations remain (TAG-006);
  /// returns whether it was deleted.
  Future<bool> deleteTagIfUnused(String tagId);

  // --- Audio refs (asset metadata) ------------------------------------

  Future<List<CardAudioRef>> audioRefsOf(String cardId);

  Future<void> addCardAudioRef(CardAudioRef ref, {required DateTime now});

  Future<void> removeCardAudioRef(
    String refId, {
    required String cardId,
    required DateTime now,
  });
}

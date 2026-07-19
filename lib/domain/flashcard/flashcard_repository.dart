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
}

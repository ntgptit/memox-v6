import 'package:memox_v6/domain/flashcard/flashcard.dart';

/// Outcome of a move (`move-flashcard.md` §3, §5).
///
/// §5's duplicate row is "Duplicate resolution before commit", so a collision
/// in the target deck is a decision the learner makes, not an error: the move
/// pauses, names the card already there, and only an explicit keep-both retry
/// goes through. Same shape as `create-flashcard.md`'s review banner.
sealed class MoveFlashcardResult {
  const MoveFlashcardResult();
}

final class FlashcardMoved extends MoveFlashcardResult {
  const FlashcardMoved();
}

final class MoveDuplicatesFound extends MoveFlashcardResult {
  const MoveDuplicatesFound(this.candidates);

  /// The cards already in the target deck carrying this term.
  final List<Flashcard> candidates;
}

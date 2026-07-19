import 'package:memox_v6/domain/flashcard/flashcard.dart';

/// Outcome of an edit attempt (WBS 5.3.1C; `edit-flashcard.md`).
sealed class EditFlashcardResult {
  const EditFlashcardResult();
}

/// The edit committed; [card] carries the incremented content version.
final class FlashcardEdited extends EditFlashcardResult {
  const FlashcardEdited(this.card);

  final Flashcard card;
}

/// Other cards in the pair share the new normalized term; nothing was
/// committed — the caller reviews and may retry with keep-both intent.
final class EditDuplicateCandidatesFound extends EditFlashcardResult {
  const EditDuplicateCandidatesFound(this.candidates);

  final List<Flashcard> candidates;
}

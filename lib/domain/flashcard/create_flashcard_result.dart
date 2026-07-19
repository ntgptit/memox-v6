import 'package:memox_v6/domain/flashcard/flashcard.dart';

/// Outcome of a create-card attempt (WBS 5.3.1A).
///
/// Duplicate detection runs before commit and never overwrites or
/// blocks silently: candidates come back for the resolution flow, and
/// an explicit keep-both retry proceeds past them
/// (`resolve-duplicate-flashcard.md`).
sealed class CreateFlashcardResult {
  const CreateFlashcardResult();
}

final class FlashcardCreated extends CreateFlashcardResult {
  const FlashcardCreated(this.card);

  final Flashcard card;
}

final class DuplicateCandidatesFound extends CreateFlashcardResult {
  const DuplicateCandidatesFound(this.candidates);

  final List<Flashcard> candidates;
}

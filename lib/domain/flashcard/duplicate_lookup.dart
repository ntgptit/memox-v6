import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

/// Runs the duplicate lookup, tagging a *lookup* failure as its own thing.
///
/// `resolve-duplicate-flashcard.md` §6 gives it its own line — "Couldn't check
/// for duplicates. Try again." — and the distinction is real: a save that
/// failed and a check that could not run leave the learner in different
/// places, one holding content that was rejected and one holding content that
/// was never offered. Both arrived as the same generic save error.
Future<List<Flashcard>> lookupDuplicateCandidates(
  FlashcardRepository cards, {
  required String languagePairId,
  required String normalizedTerm,
}) async {
  try {
    return await cards.duplicateCandidates(
      languagePairId: languagePairId,
      normalizedTerm: normalizedTerm,
    );
  } catch (error, stackTrace) {
    throw ConflictFailure(
      entity: 'flashcards',
      code: 'duplicate-check-failed',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

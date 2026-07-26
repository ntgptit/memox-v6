import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/library_mastery.dart';
import 'package:memox_v6/domain/learning_progress/study_queue_counts.dart';

/// Reads the eligible due/new counts for a study scope (WBS 5.4.2;
/// `surface-due-cards.md` §3).
///
/// This is a selection contract, not a mutation: asking what is due
/// never marks a card studied and never moves a due instant (§1).
///
/// `nowUtc` comes from the injected clock and is compared as a UTC
/// instant. Due-at-equal-now counts as due (§7). Timezone belongs to
/// presentation and to the local-day new-card limit — it never changes
/// which instants have passed, so it is absent here on purpose.
class LoadStudyQueueCountsUseCase {
  const LoadStudyQueueCountsUseCase({
    required LearningProgressRepository progress,
    required DeckRepository decks,
    required AppClock clock,
  }) : _progress = progress,
       _decks = decks,
       _clock = clock;

  final LearningProgressRepository _progress;
  final DeckRepository _decks;
  final AppClock _clock;

  /// Counts for one deck: direct cards for a Leaf, descendant Leaves
  /// for a Parent, zero for an Empty deck.
  Future<StudyQueueCounts> forDeck(String deckId) async {
    final deck = await _decks.findById(deckId);
    if (deck == null) {
      throw ValidationFailure(field: 'deckId', code: 'unknown');
    }
    return _progress.countDeckQueues(deckId, nowUtc: _clock.nowUtc());
  }

  /// Counts across the whole library of one language pair — the
  /// Dashboard scope.
  Future<StudyQueueCounts> forLibrary(String languagePairId) {
    return _progress.countLibraryQueues(
      languagePairId,
      nowUtc: _clock.nowUtc(),
    );
  }

  /// The mastered share of the same scope, for Today's stat strip.
  ///
  /// Here rather than on its own use case because it is the same read at the
  /// same scope: Box 8 is the box the queue counts above exclude, so the two
  /// answers partition the library between them and a second owner would be a
  /// second place for that boundary to move.
  Future<LibraryMastery> masteryForLibrary(String languagePairId) {
    return _progress.countLibraryMastery(languagePairId);
  }
}

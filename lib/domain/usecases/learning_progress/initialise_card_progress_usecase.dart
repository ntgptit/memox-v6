import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/logging/app_logger.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';

/// Gives a card its initial learning state, or repairs a card that has
/// none (WBS 5.4.1; `initialise-card-progress.md` §3).
///
/// The New state is `box = 0` with no due date — Box 0 is the
/// un-activated stage in SRS Policy v1, so "new" is a box value, never
/// the absence of a row. Nothing here computes a box or an interval;
/// `5.4.3` owns that math, and this flow creates no Attempt.
///
/// Two properties carry the whole contract:
///
/// - **Idempotent by card id.** A card that already has progress gets
///   that progress back untouched — same box, due date, counters and
///   revision. Retrying an unknown outcome therefore cannot reset a
///   card the learner has already worked through.
/// - **No orphan progress.** An unknown card fails before any write, so
///   a progress row can never outlive or precede its card.
///
/// The Create Card transaction already writes New inline, atomically
/// with the card, because §1 forbids a card that saved "successfully"
/// without its progress record. This use case is therefore the repair
/// and re-entry path rather than the create path: reaching its insert
/// branch means a stored card was found with its state missing, which
/// is audited.
class InitialiseCardProgressUseCase {
  const InitialiseCardProgressUseCase({
    required FlashcardRepository cards,
    required LearningProgressRepository progress,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _cards = cards,
       _progress = progress,
       _idGenerator = idGenerator,
       _clock = clock;

  final FlashcardRepository _cards;
  final LearningProgressRepository _progress;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  Future<LearningProgress> call(String cardId) async {
    final existing = await _progress.findByCard(cardId);
    if (existing != null) return existing;

    // Guard before writing: §5 forbids creating progress for a card
    // that does not exist. The foreign key would also abort, but a
    // typed validation failure is the contract the caller reads.
    final card = await _cards.findById(cardId);
    if (card == null) {
      throw ValidationFailure(field: 'cardId', code: 'unknown');
    }

    AppLogger.warning(
      'learning progress missing for a stored card; repairing to New',
      context: {'cardId': cardId, 'wbs': '5.4.1'},
    );

    return _progress.initialiseNew(
      cardId,
      progressId: _idGenerator.newId(),
      at: _clock.nowUtc(),
    );
  }
}

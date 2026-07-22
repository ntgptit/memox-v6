import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';

/// Ensures a card has its initial learning-progress state (WBS 5.4.1;
/// `initialise-card-progress.md`).
///
/// Idempotent by card id: an existing state is returned untouched, and a
/// card missing its state (import, backup restore, data repair) is repaired
/// to a New state (Box 0, no due, policy v1). A missing card creates no
/// orphan progress. Creating a state never starts a Session or writes an
/// Attempt. The normal create path already seeds progress atomically with
/// the card (5.3.1); this is the standalone ensure/repair entry point.
class InitialiseCardProgressUseCase {
  const InitialiseCardProgressUseCase({
    required LearningProgressRepository repository,
    required AppClock clock,
  }) : _repository = repository,
       _clock = clock;

  final LearningProgressRepository _repository;
  final AppClock _clock;

  Future<LearningProgress> call(String cardId) {
    // Deterministic id mirrors the create path's `progress-<cardId>`, so a
    // repair reuses the same identity rather than minting a new one.
    return _repository.ensureInitialProgress(
      id: 'progress-$cardId',
      cardId: cardId,
      nowUtc: _clock.nowUtc(),
    );
  }
}

import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/reset_progress_availability.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/usecases/deck/load_reset_progress_availability_usecase.dart';

/// Resets the learning progress of every card in a deck's subtree (WBS 6.1;
/// `reset-deck-progress.md`).
///
/// Command only — the confirm dialog shows the affected-card impact first
/// (irreversible). The store applies the reset atomically (no partial reset,
/// §1); only SRS progress changes, never content or hierarchy, and no session
/// is started. Returns the number of cards reset (0 for an empty scope).
///
/// Refuses while a session is running over cards in scope (§5). The dialog
/// checks the same thing before offering the action; this is the authority,
/// because a session can start while the dialog is open.
class ResetDeckProgressUseCase {
  const ResetDeckProgressUseCase({
    required LearningProgressRepository progress,
    required LoadResetProgressAvailabilityUseCase availability,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _progress = progress,
       _availability = availability,
       _idGenerator = idGenerator,
       _clock = clock;

  final LearningProgressRepository _progress;
  final LoadResetProgressAvailabilityUseCase _availability;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  Future<int> call(String deckId) async {
    final availability = await _availability(deckId);
    if (availability == ResetProgressAvailability.blockedByActiveSession) {
      throw ConflictFailure(
        code: 'session-active',
        entity: 'learning_progress',
      );
    }
    return _progress.resetSubtreeProgress(
      deckId,
      idGenerator: _idGenerator,
      at: _clock.nowUtc(),
    );
  }
}

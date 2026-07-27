import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/reset_progress_availability.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/usecases/deck/load_reset_progress_availability_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';
import 'package:memox_v6/domain/deck/reset_progress_result.dart';

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
    required LoadDeckDeletionImpactUseCase impact,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _progress = progress,
       _availability = availability,
       _impact = impact,
       _idGenerator = idGenerator,
       _clock = clock;

  final LearningProgressRepository _progress;
  final LoadResetProgressAvailabilityUseCase _availability;

  /// The same impact read the dialog renders, so the two cannot disagree about
  /// how many cards are in scope.
  final LoadDeckDeletionImpactUseCase _impact;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  /// [expectedAffectedCount] is the number the confirm showed. §5 requires the
  /// counts to refresh before submit and a changed impact to be confirmed
  /// again, and §11 gives "Impact changed" its own row: the destructive action
  /// there is *Confirm lại*, not Reset. Cards can be added, deleted or studied
  /// while the dialog sits open, and a confirm is a promise about a number —
  /// resetting a different scope than the one agreed to is the defect this
  /// guards (`int-103`).
  Future<ResetProgressResult> call(
    String deckId, {
    required int expectedAffectedCount,
  }) async {
    final availability = await _availability(deckId);
    if (availability == ResetProgressAvailability.blockedByActiveSession) {
      throw ConflictFailure(
        code: 'session-active',
        entity: 'learning_progress',
      );
    }

    // Re-read rather than trust the dialog's copy. This is the authority for
    // the same reason it is the authority on the session check: a dialog can
    // sit open for as long as the learner leaves it there.
    final impact = await _impact(deckId);
    if (impact.studiedCardCount != expectedAffectedCount) {
      return ResetImpactChanged(impact.studiedCardCount);
    }

    return ProgressReset(
      await _progress.resetSubtreeProgress(
        deckId,
        idGenerator: _idGenerator,
        at: _clock.nowUtc(),
      ),
    );
  }
}

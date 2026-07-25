import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/srs_8_box_policy.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';

/// Applies a terminal study outcome to a card's SRS progress as one atomic,
/// exactly-once operation (WBS 5.4.4; SRS Policy v1 §§3,5–8; SRS8-001,
/// 003–012, 017–024, 028). The atomic Attempt+Progress write itself lives in
/// the data layer; this use case only decides the next state.
///
/// It reads the card's current progress and hands it to the pure
/// [Srs8BoxPolicy], which owns every decision: the policy-id guard
/// (SRS8-028), the box/due math, and the §8 counters (a terminal grade
/// increments repetitions, a `wrong` grade also increments lapses;
/// activation leaves both untouched). This use case then persists the
/// evidence and the returned schedule through
/// [LearningProgressRepository.applyScheduledOutcome] — whose idempotency key
/// makes a replay a no-op (SRS8-011) and whose guarded revision raises a typed
/// [ConflictFailure] on a concurrent write (SRS8-012). Nothing here computes a
/// box, a due date or a counter.
class ApplyTerminalOutcomeUseCase {
  const ApplyTerminalOutcomeUseCase({
    required LearningProgressRepository repository,
  }) : _repository = repository;

  final LearningProgressRepository _repository;

  /// Activate a completed new card: Box 0 → Box 1 (SRS8-001). Counters are
  /// untouched — activation is not a graded repetition (§3 activation result).
  ///
  /// A card that has already left Box 0 is rejected by the policy with
  /// `ValidationFailure(box, 'already-activated')`.
  Future<void> activate({
    required StudyAttempt attempt,
    required DateTime nowUtc,
  }) async {
    final current = await _load(attempt.cardId);
    await _persist(
      current,
      attempt,
      Srs8BoxPolicy.activate(current: current, nowUtc: nowUtc),
      nowUtc,
    );
  }

  /// Apply a binary terminal grade to an activated card in Box 1..8
  /// (SRS8-003–009, 017–024).
  ///
  /// A Box 0 card is rejected by the policy with
  /// `ValidationFailure(box, 'not-activated')` — activation has its own
  /// precondition and its own entry point.
  Future<void> applyGrade({
    required StudyAttempt attempt,
    required SrsGrade grade,
    required DateTime nowUtc,
  }) async {
    final current = await _load(attempt.cardId);
    await _persist(
      current,
      attempt,
      Srs8BoxPolicy.applyTerminalGrade(
        current: current,
        grade: grade,
        nowUtc: nowUtc,
      ),
      nowUtc,
    );
  }

  Future<LearningProgress> _load(String cardId) async {
    final current = await _repository.findByCard(cardId);
    if (current == null) {
      throw ValidationFailure(field: 'cardId', code: 'no-progress');
    }
    // The policy id itself is checked by the policy (SRS8-028) so that a
    // future policy's rows cannot be reinterpreted under v1 rules.
    return current;
  }

  /// `SrsSchedule.lastReviewedAt` and `srsActivatedAt` are computed by the
  /// policy but have no schema-v1 column, so they are not persisted here.
  Future<void> _persist(
    LearningProgress current,
    StudyAttempt attempt,
    SrsSchedule schedule,
    DateTime nowUtc,
  ) {
    return _repository.applyScheduledOutcome(
      attempt: attempt,
      newBox: schedule.box,
      newDueAt: schedule.dueAt,
      repetitionCount: schedule.repetitionCount,
      lapseCount: schedule.lapseCount,
      expectedRevision: current.revision,
      updatedAt: nowUtc,
    );
  }
}

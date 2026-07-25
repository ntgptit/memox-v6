import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';

/// Learning Progress repository port (WBS 4.6B).
///
/// `applyScheduledOutcome` is schema-v1 atomic operation 4: persist one
/// terminal attempt and its schedule exactly once. The attempt's
/// idempotency key dedupes replays (a replay returns success without
/// reapplying); a stale `expectedRevision` raises
/// `ConflictFailure(code: 'revision')` and nothing persists. The box,
/// due date and counters always arrive from the SRS policy — this port
/// never computes them.
///
/// `resetCard` is operation 6: progress returns to Box 0 with no due
/// date and cleared counters without touching card content.
///
/// `initialiseNew` is the WBS 5.4.1 entry point: insert-if-absent then
/// read back, in one transaction, so it always answers with the state
/// the store holds — the one it just created, or the one that was
/// already there. It never overwrites, which is what keeps a repeat
/// call from resetting a learned card.
abstract interface class LearningProgressRepository {
  /// Ensures [cardId] has a current progress row and returns it.
  ///
  /// Idempotent by card id: an existing row is returned untouched,
  /// including its box, due date, counters and revision. [progressId]
  /// is only used when this call is the one that inserts.
  Future<LearningProgress> initialiseNew(
    String cardId, {
    required String progressId,
    required DateTime at,
  });

  Future<void> applyScheduledOutcome({
    required StudyAttempt attempt,
    required int newBox,
    required DateTime? newDueAt,
    required int repetitionCount,
    required int lapseCount,
    required int expectedRevision,
    required DateTime updatedAt,
  });

  Future<void> resetCard(
    String cardId, {
    required String newProgressId,
    required DateTime at,
  });

  Future<LearningProgress?> findByCard(String cardId);

  Future<List<LearningProgress>> pageDue(
    DateTime nowUtc, {
    required int limit,
    required int offset,
  });

  Future<int> countDue(DateTime nowUtc);
}

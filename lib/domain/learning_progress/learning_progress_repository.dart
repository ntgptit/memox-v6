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
abstract interface class LearningProgressRepository {
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

  /// Idempotent New-state initialisation / safe repair (5.4.1,
  /// `initialise-card-progress.md`): returns the card's current progress, or
  /// creates a New state (Box 0, no due) when none exists. Never resets an
  /// existing state; a missing card creates no orphan (the card_id FK).
  Future<LearningProgress> ensureInitialProgress({
    required String id,
    required String cardId,
    required DateTime nowUtc,
  });

  Future<List<LearningProgress>> pageDue(
    DateTime nowUtc, {
    required int limit,
    required int offset,
  });

  Future<int> countDue(DateTime nowUtc);
}

import 'package:memox_v6/core/ids/id_generator.dart';
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
import 'package:memox_v6/domain/learning_progress/study_candidates.dart';

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

  /// Resets every card in a deck's subtree to Box 0 atomically (WBS 6.1;
  /// `reset-deck-progress.md`) — `resetCard`'s effect applied across the whole
  /// scope in one commit, so a failure leaves no partial reset. Only SRS
  /// progress changes; content and hierarchy are untouched. Returns the number
  /// of cards reset. [idGenerator] mints each fresh progress row's id.
  Future<int> resetSubtreeProgress(
    String deckId, {
    required IdGenerator idGenerator,
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

  /// Read-only due + new study queues for a deck scope (5.4.2,
  /// `surface-due-cards.md`): the recursive subtree of [scopeDeckId], each
  /// eligible card classified once (New = Box 0/no due; Due = Box 1..7 with
  /// `dueAt <= nowUtc`), hidden/deleted and Box 8 excluded, due ordered
  /// soonest-first. Never mutates progress.
  Future<StudyCandidates> studyCandidatesInScope({
    required String scopeDeckId,
    required DateTime nowUtc,
  });

  Future<List<LearningProgress>> pageDue(
    DateTime nowUtc, {
    required int limit,
    required int offset,
  });

  Future<int> countDue(DateTime nowUtc);
}

import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';
import 'package:memox_v6/domain/learning_progress/library_mastery.dart';
import 'package:memox_v6/domain/learning_progress/study_candidates.dart';
import 'package:memox_v6/domain/learning_progress/study_queue_counts.dart';
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
    // Both come from the policy's `SrsSchedule`, like the box and due date.
    // [srsActivatedAt] is the card's existing activation instant unchanged
    // after Box 1, so passing it back is a no-op write; a pre-v2 row passes
    // NULL through and keeps NULL.
    required DateTime? srsActivatedAt,
    required DateTime lastReviewedAt,
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

  /// Read-only due + new study queues for a deck scope (5.4.2,
  /// `surface-due-cards.md`): the recursive subtree of [scopeDeckId], each
  /// eligible card classified once (New = Box 0/no due; Due = Box 1..7 with
  /// `dueAt <= nowUtc`), hidden/deleted and Box 8 excluded, due ordered
  /// soonest-first. Never mutates progress.
  /// Every studiable card in [scopeDeckId]'s subtree, hidden and deleted
  /// excluded (ST-TYPE-003).
  ///
  /// Separate from [studyCandidatesInScope] because it answers a different
  /// question: that one selects what is *scheduled* — new and due — while
  /// Practice draws the scope itself. Practice sets `scheduleSrs = false` and
  /// contributes no Goal or Streak, so a card's box does not decide whether it
  /// can be practised.
  Future<List<String>> studiableCardIdsInScope({required String scopeDeckId});

  Future<StudyCandidates> studyCandidatesInScope({
    required String scopeDeckId,
    required DateTime nowUtc,
  });

  /// Eligible due/new counts for a deck scope (WBS 5.4.2).
  ///
  /// A Leaf answers for its direct cards, a Parent aggregates its
  /// descendant Leaves, and an Empty deck answers zero. Hidden and
  /// soft-deleted cards are excluded. Read-only: no queue query
  /// mutates progress or a due instant.
  Future<StudyQueueCounts> countDeckQueues(
    String deckId, {
    required DateTime nowUtc,
  });

  /// The same counts across every deck of one language pair — the
  /// Dashboard scope.
  Future<StudyQueueCounts> countLibraryQueues(
    String languagePairId, {
    required DateTime nowUtc,
  });

  /// The mastered share of the same scope — Today's "library mastered" stat.
  /// Takes no instant: Box 8 is a state, not a schedule, so unlike the queue
  /// counts it does not depend on when it is asked.
  Future<LibraryMastery> countLibraryMastery(String languagePairId);

  Future<List<LearningProgress>> pageDue(
    DateTime nowUtc, {
    required int limit,
    required int offset,
  });
}

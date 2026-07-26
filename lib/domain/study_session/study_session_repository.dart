import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_relearn_item.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart';

/// Study Session repository port (WBS 4.6C) — owner of schema-v1 atomic
/// operations 2, 3 and 5.
///
/// - `startSession` (op 2): session row + card snapshots + the initial
///   round order commit atomically. The session id is the idempotency
///   key; a competing active session surfaces as
///   `ConflictFailure(code: 'duplicate')` from the single-active index
///   and nothing persists.
/// - `saveAttemptWithCheckpoint` (op 3): attempt evidence and the
///   resumable checkpoint persist together before presentation
///   advances; the attempt idempotency key absorbs replays.
/// - `finalizeSession` (op 5): the terminal state transition and its
///   goal/streak contribution events apply exactly once behind the
///   revision guard. A replay that finds the session already in the
///   requested terminal state returns success; any other stale write
///   raises `ConflictFailure(code: 'revision')`.
abstract interface class StudySessionRepository {
  Future<void> startSession({
    required StudySession session,
    required List<SessionCardSnapshot> cardSnapshots,
    required SessionRoundOrder initialOrder,
  });

  Future<StudySession?> findById(String id);

  Stream<StudySession?> watchActive();

  /// The active session right now, or null.
  ///
  /// Separate from [watchActive] because a decision wants a value, not a
  /// subscription: `watchActive().first` opens a query stream and waits for
  /// its first emission, which arrives a frame or more later. A start that
  /// asked the stream therefore did not know whether a session existed until
  /// after the caller had moved on.
  Future<StudySession?> activeSession();

  Future<List<SessionCardSnapshot>> cardSnapshots(String sessionId);

  Future<SessionRoundOrder?> roundOrder(String sessionId, int roundIndex);

  /// Op 3, extended: when a committed answer opens a new mastery round or
  /// stage, its freshly generated [newRoundOrder] persists in the *same*
  /// transaction as the attempt and checkpoint (`answer-study-stage.md` §7
  /// atomic handoff), so resume can never see a checkpoint pointing at an order
  /// that was not committed. A replay (stored idempotency key) persists none of
  /// the three again.
  Future<void> saveAttemptWithCheckpoint({
    required StudyAttempt attempt,
    required SessionCheckpoint checkpoint,
    SessionRoundOrder? newRoundOrder,
  });

  Future<SessionCheckpoint?> checkpoint(String sessionId);

  /// Persists a checkpoint on its own, outside an attempt.
  ///
  /// The answer path writes attempt + checkpoint together because they must
  /// commit as one. A pause has no attempt: `exit-study-session.md` §5 asks
  /// the Recall countdown to survive an exit, and the position it belongs to
  /// is already committed. Keyed by session, so this updates the row the
  /// answer path maintains rather than adding a second one.
  ///
  /// [newRoundOrder] rides along when the advance opened a new round, for the
  /// same reason the answer path commits its order with its attempt: a
  /// checkpoint pointing at an order that was not written is a session that
  /// cannot be resumed.
  Future<void> saveCheckpoint(
    SessionCheckpoint checkpoint, {
    SessionRoundOrder? newRoundOrder,
  });

  /// The session's committed attempts in commit order (`study_attempts` by
  /// `session_id`), for terminal-grade aggregation and the finalize summary
  /// (WBS 5.6.13).
  Future<List<StudyAttempt>> attempts(String sessionId);

  Future<void> finalizeSession({
    required String sessionId,
    required int expectedRevision,
    required SessionState terminalState,
    required DateTime finalizedAt,
    GoalDayProgress? goalContribution,
    StreakDay? streakContribution,
  });

  Future<void> addRelearnItem(
    SessionRelearnItem item, {
    required DateTime recordedAt,
  });

  Future<List<SessionRelearnItem>> relearnItems(String sessionId);
}

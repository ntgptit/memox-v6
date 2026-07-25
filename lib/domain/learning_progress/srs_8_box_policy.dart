import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';

/// The only policy identifier v1 schedules under
/// (`srs-8-box-policy.md` §1). A future policy needs a new id, an
/// explicit old→new box mapping and its own decision table — v1 history
/// is never reinterpreted in place (§11).
const String leitner8BoxPolicyId = 'leitner-8-box-v1';

/// The binary terminal grade the scheduler accepts (§4).
///
/// Study Mode never calls the scheduler; Study Session folds a card's
/// evidence for one session into exactly one of these.
enum SrsGrade { correct, wrong }

/// One committed graded interaction for a card inside a session (§4).
///
/// Only committed, graded evidence belongs here. A review-only
/// `reviewed`, an uncommitted attempt, a duplicate retry and an invalid
/// interaction all take no part in the terminal grade, so callers drop
/// them before folding rather than encoding them as a value.
enum SrsEvidence {
  /// Answered correctly.
  passed,

  /// A committed wrong answer.
  wrong,

  /// A committed "almost" — close, but not counted as a pass.
  almost,

  /// A Recall deadline elapsed before the learner answered.
  timeout,
}

/// The next scheduling state for a card, computed and never persisted
/// by this policy (`srs-8-box-policy.md` §§6, 8).
class SrsSchedule {
  const SrsSchedule({
    required this.box,
    required this.dueAt,
    required this.lastReviewedAt,
    required this.srsActivatedAt,
    required this.repetitionCount,
    required this.lapseCount,
    required this.policyId,
  });

  /// Resulting box: 1..7 scheduled, 8 mastered. An activated card never
  /// returns to Box 0 by answering wrong (§5).
  final int box;

  /// `null` at Box 8 — mastered cards are not scheduled again (§2).
  final DateTime? dueAt;

  /// The injected instant this terminal grade was applied (§8).
  final DateTime lastReviewedAt;

  /// When the card first entered Box 1; unchanged by later grades (§3).
  final DateTime? srsActivatedAt;

  /// Incremented once per committed terminal grade (§8).
  final int repetitionCount;

  /// Incremented when the terminal grade is `wrong` (§8).
  final int lapseCount;

  final String policyId;
}

/// Leitner 8 Box, SRS Policy v1 — the single source of the transition
/// math (`docs/business/learning-progress/srs-8-box-policy.md`, decision
/// table `SRS8-001..028`).
///
/// Pure by contract: no Flutter, Drift or Riverpod import, no
/// `DateTime.now()`, no persistence. Every instant arrives as an
/// injected `nowUtc`, so the same inputs always produce the same
/// schedule (§12). The data layer persists what this returns and owns
/// the transaction, idempotency and stale-writer conflict (§7) — none
/// of which live here.
abstract final class Srs8BoxPolicy {
  /// Pre-SRS state: a new card that has not finished the five-mode
  /// learning flow. Not one of the eight SRS boxes (§2).
  static const int newBox = 0;

  /// The box a card activates into (§3).
  static const int firstSrsBox = 1;

  /// Mastered: no further scheduling (§2).
  static const int masteredBox = 8;

  /// Days a card waits after entering box 1..7, in order (§2).
  ///
  /// Fixed in v1: Settings displays these, it cannot change the count or
  /// the values. A `day` here is a 24-hour duration (§6).
  static const List<int> intervalDays = <int>[1, 3, 7, 14, 30, 60, 120];

  /// The wait after entering [box].
  ///
  /// Only 1..7 are scheduled. Box 0 has no due date and Box 8 is
  /// mastered, so asking either for an interval is a caller bug rather
  /// than a state to fall back from.
  static Duration intervalForBox(int box) {
    if (box < firstSrsBox || box > intervalDays.length) {
      throw ValidationFailure(field: 'box', code: 'not-scheduled');
    }
    return Duration(days: intervalDays[box - firstSrsBox]);
  }

  /// Folds a session's committed evidence into one terminal grade (§4).
  ///
  /// Wrong is sticky within a session: one committed `wrong`, `almost`
  /// or timeout in *any* mastery round makes the terminal grade `wrong`,
  /// even when the card is later passed on a retry round (`SRS8-010`).
  /// The retry proves mastery for the session; it does not erase the
  /// lapse.
  ///
  /// Returns `null` when there is no graded evidence at all — a skipped
  /// or missing card under snapshot recovery must not be scheduled as if
  /// it had been answered correctly (§4).
  ///
  /// Stickiness is scoped to the session that produced [evidence]. A
  /// later relearn session reads the box persisted after the demotion
  /// and folds its own evidence, so a clean run there can promote again.
  static SrsGrade? terminalGrade(Iterable<SrsEvidence> evidence) {
    final graded = evidence.toList(growable: false);
    if (graded.isEmpty) return null;
    final hasLapse = graded.any(
      (item) =>
          item == SrsEvidence.wrong ||
          item == SrsEvidence.almost ||
          item == SrsEvidence.timeout,
    );
    if (hasLapse) return SrsGrade.wrong;
    return SrsGrade.correct;
  }

  /// The box a card moves to from [currentBox] on [grade] (§5).
  ///
  /// Correct promotes one box, capped at 8; wrong demotes one box,
  /// floored at 1. There is no Box 9, and wrong never sends an activated
  /// card back to Box 0 — only an explicit reset does that (§10).
  static int boxAfterFinalization(int currentBox, SrsGrade grade) {
    if (currentBox < firstSrsBox || currentBox > masteredBox) {
      throw ValidationFailure(field: 'box', code: 'not-activated');
    }
    return switch (grade) {
      SrsGrade.correct =>
        currentBox + 1 > masteredBox ? masteredBox : currentBox + 1,
      SrsGrade.wrong =>
        currentBox - 1 < firstSrsBox ? firstSrsBox : currentBox - 1,
    };
  }

  /// Activates a Box 0 card into Box 1 (`SRS8-001`).
  ///
  /// The caller is responsible for the §3 precondition: the full
  /// five-mode learning flow finished with an empty failed set and no
  /// pending attempt write. Leaving early keeps the card at Box 0
  /// (`SRS8-002`), which is simply the absence of this call — this
  /// policy is not asked to decide that.
  ///
  /// Activation is not a graded transition: it neither counts a
  /// repetition nor a lapse.
  static SrsSchedule activate({
    required LearningProgress current,
    required DateTime nowUtc,
  }) {
    _requireSupportedPolicy(current.policyId);
    if (current.box != newBox) {
      throw ValidationFailure(field: 'box', code: 'already-activated');
    }
    return SrsSchedule(
      box: firstSrsBox,
      dueAt: nowUtc.add(intervalForBox(firstSrsBox)),
      lastReviewedAt: nowUtc,
      srsActivatedAt: nowUtc,
      repetitionCount: current.repetitionCount,
      lapseCount: current.lapseCount,
      policyId: leitner8BoxPolicyId,
    );
  }

  /// Applies one terminal [grade] to an activated card (`SRS8-003..009`,
  /// `SRS8-017..024`).
  ///
  /// Box 8 lands with no due date; boxes 1..7 are due at
  /// `nowUtc + interval(box)`. A Box 0 card is rejected rather than
  /// silently activated — activation has its own precondition and its
  /// own entry point.
  static SrsSchedule applyTerminalGrade({
    required LearningProgress current,
    required SrsGrade grade,
    required DateTime nowUtc,
    DateTime? srsActivatedAt,
  }) {
    _requireSupportedPolicy(current.policyId);
    final nextBox = boxAfterFinalization(current.box, grade);
    final isMastered = nextBox == masteredBox;
    return SrsSchedule(
      box: nextBox,
      dueAt: isMastered ? null : nowUtc.add(intervalForBox(nextBox)),
      lastReviewedAt: nowUtc,
      srsActivatedAt: srsActivatedAt,
      repetitionCount: current.repetitionCount + 1,
      lapseCount: grade == SrsGrade.wrong
          ? current.lapseCount + 1
          : current.lapseCount,
      policyId: leitner8BoxPolicyId,
    );
  }

  /// `SRS8-028`: a progress row stored under another policy is not this
  /// policy's to schedule. Failing typed keeps a future policy's data
  /// from being silently reinterpreted under v1 rules (§11).
  static void _requireSupportedPolicy(String policyId) {
    if (policyId == leitner8BoxPolicyId) return;
    throw ValidationFailure(field: 'policyId', code: 'unsupported');
  }
}

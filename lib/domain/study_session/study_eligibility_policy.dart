import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart'
    show kGuessOptionCount;
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';

/// Why a study session cannot start (`start-study-session.md` §5 validation
/// table; ST-SESSION-TYPE-v1).
enum StartBlockReason {
  /// No eligible card remains in the requested scope for this session type.
  scopeEmpty,

  /// A Due Review with an empty due queue — the learner is caught up, so no
  /// empty session is created (ST-TYPE-006).
  dueCaughtUp,

  /// A Practice start with no mode selected (ST-TYPE-004).
  practiceModeNotSelected,

  /// A plan containing Guess whose candidate pool has fewer than
  /// [kGuessOptionCount] distinct normalized meanings (ST-TYPE-011).
  guessPoolInsufficient,
}

/// The eligibility verdict for a start request.
class StartEligibility {
  const StartEligibility.allowed() : blockReason = null;
  const StartEligibility.blocked(StartBlockReason reason)
    : blockReason = reason;

  /// `null` when the session may start; otherwise the blocking reason.
  final StartBlockReason? blockReason;

  bool get canStart => blockReason == null;
}

/// Pure Study start eligibility (WBS 5.6.1; `start-study-session.md` §5,
/// ST-SESSION-TYPE-v1). It decides *whether* a session may start from already
/// computed scope counts — it reads no repository and builds no snapshot. The
/// counts (eligible/due/new cards, distinct meanings) are gathered by the start
/// use case (5.6.2); Guess needs at least [kGuessOptionCount] distinct
/// normalized meanings, matching the five options every question must show.
class StudyEligibilityPolicy {
  const StudyEligibilityPolicy();

  /// Whether a Guess candidate pool is large enough (ST-TYPE-011).
  bool isGuessPoolSufficient(int distinctMeaningCount) =>
      distinctMeaningCount >= kGuessOptionCount;

  /// Resolve start eligibility for [type]. [selectedMode] is required only for
  /// Practice. Counts are the recomputed, hidden/deleted-excluded totals for the
  /// scope: [eligibleCardCount] the cards this type would study, [dueCardCount]
  /// the Box 1..7 due cards, [distinctMeaningCount] the pool's distinct
  /// normalized meanings.
  StartEligibility resolve({
    required SessionType type,
    StudyModeType? selectedMode,
    required int eligibleCardCount,
    required int dueCardCount,
    required int distinctMeaningCount,
  }) {
    switch (type) {
      case SessionType.dueReview:
        // ST-TYPE-005/006: an empty due queue is "caught up", not empty scope.
        if (dueCardCount <= 0) {
          return const StartEligibility.blocked(StartBlockReason.dueCaughtUp);
        }
        return const StartEligibility.allowed();

      case SessionType.practice:
        // ST-TYPE-004: Practice must have a selected mode.
        if (selectedMode == null) {
          return const StartEligibility.blocked(
            StartBlockReason.practiceModeNotSelected,
          );
        }
        if (eligibleCardCount <= 0) {
          return const StartEligibility.blocked(StartBlockReason.scopeEmpty);
        }
        // ST-TYPE-011: a Guess practice needs the distinct-meaning pool.
        if (selectedMode == StudyModeType.guess &&
            !isGuessPoolSufficient(distinctMeaningCount)) {
          return const StartEligibility.blocked(
            StartBlockReason.guessPoolInsufficient,
          );
        }
        return const StartEligibility.allowed();

      case SessionType.newLearning:
        // ST-TYPE-001/002: the fixed five-mode plan always contains Guess, so
        // the pool check applies and the plan never downgrades.
        if (eligibleCardCount <= 0) {
          return const StartEligibility.blocked(StartBlockReason.scopeEmpty);
        }
        if (!isGuessPoolSufficient(distinctMeaningCount)) {
          return const StartEligibility.blocked(
            StartBlockReason.guessPoolInsufficient,
          );
        }
        return const StartEligibility.allowed();

      case SessionType.relearn:
        // ST-TYPE-015/016: Relearn falls back from Guess to binary when the
        // pool is short, so a missing pool never blocks the start.
        if (eligibleCardCount <= 0) {
          return const StartEligibility.blocked(StartBlockReason.scopeEmpty);
        }
        return const StartEligibility.allowed();
    }
  }
}

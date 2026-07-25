/// The day bucket after a session contributed to it
/// (`track-daily-goal.md` §2 output: previous/current amount, target, met
/// transition).
class DailyGoalContribution {
  const DailyGoalContribution({
    required this.previousAmount,
    required this.currentAmount,
    required this.target,
    required this.wasMet,
    required this.isMet,
  });

  /// Nothing to track: no goal configured, or the goal is disabled.
  /// Disabled keeps activity history but does not count active attainment
  /// (`track-daily-goal.md` §1).
  const DailyGoalContribution.inactive()
    : previousAmount = 0,
      currentAmount = 0,
      target = 0,
      wasMet = false,
      isMet = false;

  /// Qualified cards counted for the day before this session.
  final int previousAmount;

  /// …and after it. Over-target is allowed and displayed (§1).
  final int currentAmount;

  /// The target in force for the day, snapshotted onto the bucket so a later
  /// config change cannot retroactively un-meet a met day.
  final int target;

  final bool wasMet;
  final bool isMet;

  bool get isActive => target > 0;

  /// The completion transition `complete-daily-goal.md` consumes. True only on
  /// the crossing, so "một local day/config lineage phát tối đa một completion
  /// event" holds without a separate emitted-events table: a day already met
  /// reports false however many further sessions land on it.
  bool get crossedTarget => !wasMet && isMet;
}

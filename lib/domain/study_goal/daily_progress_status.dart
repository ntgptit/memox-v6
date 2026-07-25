/// Today's streak and goal standing (`metrics-v1` Goal and streak).
///
/// One type for both surfaces that show it: the Study Result's streak card
/// after a session, and Today's Daily-goal card before one. They render
/// differently but ask the same question, and two shapes would be two chances
/// for the numbers to disagree.
class DailyProgressStatus {
  const DailyProgressStatus({
    required this.streakDays,
    required this.goalDoneCards,
    required this.goalTargetCards,
  });

  /// Nothing to show: no goal configured, or the goal is disabled. The card is
  /// a target-versus-progress display, so without a target there is no card —
  /// distinct from a goal of zero, which the schema forbids anyway
  /// (`target_card_count > 0`).
  const DailyProgressStatus.none()
    : streakDays = 0,
      goalDoneCards = 0,
      goalTargetCards = 0;

  /// Consecutive qualified days ending today, or yesterday when today has no
  /// qualifying event yet (`metrics-v1`).
  final int streakDays;

  /// Qualified cards counted toward today's goal. Cards, not minutes: v1's
  /// goal unit is qualified Cards.
  final int goalDoneCards;

  final int goalTargetCards;

  bool get hasGoal => goalTargetCards > 0;

  bool get isMet => hasGoal && goalDoneCards >= goalTargetCards;
}

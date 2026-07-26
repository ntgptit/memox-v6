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
    this.studiedToday = false,
    this.hasStreakHistory = false,
  });

  /// Nothing to show: no goal configured, or the goal is disabled. The card is
  /// a target-versus-progress display, so without a target there is no card —
  /// distinct from a goal of zero, which the schema forbids anyway
  /// (`target_card_count > 0`).
  const DailyProgressStatus.none()
    : streakDays = 0,
      goalDoneCards = 0,
      goalTargetCards = 0,
      studiedToday = false,
      hasStreakHistory = false;

  /// Consecutive qualified days ending today, or yesterday when today has no
  /// qualifying event yet (`metrics-v1`).
  final int streakDays;

  /// Qualified cards counted toward today's goal. Cards, not minutes: v1's
  /// goal unit is qualified Cards.
  final int goalDoneCards;

  final int goalTargetCards;

  /// Today is already a qualified day. Read from the streak records rather
  /// than from [goalDoneCards], which is zero for everyone who has configured
  /// no goal — `record-streak-day.md` §6 makes qualification independent of
  /// the goal, so the goal bucket cannot answer "did they study today".
  final bool studiedToday;

  /// At least one qualified day is on record, ever.
  ///
  /// What separates a streak that *broke* from one that never started. Both
  /// read [streakDays] `== 0`, and telling a first-time learner their streak
  /// reset would name a loss they never had.
  final bool hasStreakHistory;

  bool get hasGoal => goalTargetCards > 0;

  bool get isMet => hasGoal && goalDoneCards >= goalTargetCards;
}

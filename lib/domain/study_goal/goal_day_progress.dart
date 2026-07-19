/// Per-local-day goal progress bucket (WBS 4.5). The local date and
/// timezone are deliberate snapshots: day boundaries follow the user.
class GoalDayProgress {
  const GoalDayProgress({
    required this.id,
    required this.localDate,
    required this.timezoneId,
    required this.goalId,
    required this.qualifiedCardCount,
    required this.targetSnapshot,
    required this.isMet,
    required this.updatedAt,
  });

  final String id;
  final String localDate;
  final String timezoneId;
  final String goalId;
  final int qualifiedCardCount;
  final int targetSnapshot;
  final bool isMet;
  final DateTime updatedAt;
}

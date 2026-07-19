/// Daily study goal configuration (WBS 4.5).
class DailyGoal {
  const DailyGoal({
    required this.id,
    required this.isEnabled,
    required this.targetCardCount,
    required this.effectiveFromLocalDate,
    required this.timezoneId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final bool isEnabled;
  final int targetCardCount;
  final String effectiveFromLocalDate;
  final String timezoneId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

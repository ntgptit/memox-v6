/// Qualified streak day (WBS 4.5): unique per local date.
class StreakDay {
  const StreakDay({
    required this.id,
    required this.localDate,
    required this.timezoneId,
    required this.qualifiedSource,
    required this.sourceVersion,
  });

  final String id;
  final String localDate;
  final String timezoneId;
  final String qualifiedSource;
  final int sourceVersion;
}

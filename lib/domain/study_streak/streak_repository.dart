import 'package:memox_v6/domain/study_streak/streak_day.dart';

/// Study Streak repository port (WBS 4.6B).
///
/// Recording is idempotent by contract: the unique local date absorbs
/// duplicate qualified events, so replays never double-count a day.
abstract interface class StreakRepository {
  Future<void> recordDay(StreakDay day, {required DateTime recordedAt});

  Future<List<StreakDay>> daysBetween(String fromLocalDate, String toLocalDate);

  Future<int> countDays();
}

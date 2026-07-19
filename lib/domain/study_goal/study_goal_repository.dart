import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';

/// Study Goal repository port (WBS 4.6B).
///
/// Day-bucket writes are mechanical upserts keyed by the unique local
/// date; contribution idempotency rides the session-finalize
/// exactly-once contract (operation 5, owned by the session
/// repository).
abstract interface class StudyGoalRepository {
  Future<void> createGoal(DailyGoal goal);

  Future<void> updateGoal(
    String goalId, {
    required bool isEnabled,
    required int targetCardCount,
    required DateTime updatedAt,
  });

  Future<DailyGoal?> latestGoal();

  Future<void> recordDayProgress(GoalDayProgress progress);

  Future<GoalDayProgress?> dayProgress(String localDate);

  Stream<GoalDayProgress?> watchDayProgress(String localDate);
}

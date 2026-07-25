import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';

/// Reads the effective daily-goal configuration, or null when none is set
/// (`set-daily-study-goal.md` §1 — one configuration at a time).
///
/// Separate from [LoadDailyProgressUseCase], which answers "how is today
/// going" and reports nothing at all for a disabled goal. The settings form
/// needs the configuration itself, including the target a disabled goal keeps
/// so re-enabling need not ask again (§5).
class LoadDailyGoalUseCase {
  const LoadDailyGoalUseCase({required StudyGoalRepository goals})
    : _goals = goals;

  final StudyGoalRepository _goals;

  Future<DailyGoal?> call() => _goals.latestGoal();
}

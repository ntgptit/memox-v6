import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_goal/daily_progress_status.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';
import 'package:memox_v6/domain/study_streak/streak_projection_policy.dart';
import 'package:memox_v6/domain/study_streak/streak_repository.dart';

/// Reads today's streak and goal standing from the records that own them.
///
/// Extracted so the two surfaces that show this cannot drift: the Study Result
/// builds it from the session it just finalized, Today reads it cold, and both
/// go through the same projection over the same day records. Nothing caches a
/// running total, so there is no second copy to fall out of date.
class LoadDailyProgressUseCase {
  const LoadDailyProgressUseCase({
    required StreakRepository streaks,
    required StudyGoalRepository goals,
    required AppTimeZone timeZone,
    required AppClock clock,
    StreakProjectionPolicy streakPolicy = const StreakProjectionPolicy(),
  }) : _streaks = streaks,
       _goals = goals,
       _timeZone = timeZone,
       _clock = clock,
       _streakPolicy = streakPolicy;

  final StreakRepository _streaks;
  final StudyGoalRepository _goals;
  final AppTimeZone _timeZone;
  final AppClock _clock;
  final StreakProjectionPolicy _streakPolicy;

  Future<DailyProgressStatus> call() async {
    final today = _timeZone.localDayOf(_clock.nowUtc());
    final localDate = today.toString();

    // The streak is read before the goal is even looked at, because it does
    // not depend on one: `record-streak-day.md` §6 — "Không phụ thuộc Daily
    // Goal enabled/met". Returning `none()` on a missing goal used to drop the
    // streak with it, so a learner on day nine of a run who had never set a
    // target was told they had no streak.
    final days = await _streaks.daysBetween('0000-01-01', localDate);
    final projection = _streakPolicy.project(
      days: days
          .map((day) => parseLocalDay(day.localDate))
          .whereType<LocalDay>(),
      effectiveDay: today,
    );
    final streakDays = projection.current;
    final studiedToday = projection.lastQualifiedDay == today;
    final hasStreakHistory = projection.lastQualifiedDay != null;

    final goal = await _goals.latestGoal();
    if (goal == null || !goal.isEnabled) {
      // No target, so no goal figures — `hasGoal` stays false and the card
      // stays hidden. The streak still has something to say.
      return DailyProgressStatus(
        streakDays: streakDays,
        goalDoneCards: 0,
        goalTargetCards: 0,
        studiedToday: studiedToday,
        hasStreakHistory: hasStreakHistory,
      );
    }

    final bucket = await _goals.dayProgress(localDate);
    // No bucket yet means no qualifying session today — progress is zero
    // against the currently configured target, not "no goal".
    final done = bucket?.qualifiedCardCount ?? 0;
    final target = bucket?.targetSnapshot ?? goal.targetCardCount;

    return DailyProgressStatus(
      streakDays: streakDays,
      goalDoneCards: done,
      goalTargetCards: target,
      studiedToday: studiedToday,
      hasStreakHistory: hasStreakHistory,
    );
  }
}

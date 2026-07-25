import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';

/// Enables, disables or re-targets the daily study goal
/// (`set-daily-study-goal.md`).
///
/// One effective configuration at a time (§1): a first save creates it, every
/// later save updates the same row rather than stacking versions, which is
/// what makes `latestGoal()` unambiguous for the readers.
///
/// Nothing here touches attainment. Disabling keeps historical buckets (§1
/// "Disable Goal không xóa historical attainment") and re-targeting leaves the
/// current day's contribution alone — `TrackDailyGoalUseCase` re-derives `met`
/// against the target the day was opened with, so lowering a target can
/// complete today and raising one cannot un-complete it.
class SetDailyStudyGoalUseCase {
  const SetDailyStudyGoalUseCase({
    required StudyGoalRepository goals,
    required AppTimeZone timeZone,
    required AppClock clock,
    required IdGenerator idGenerator,
  }) : _goals = goals,
       _timeZone = timeZone,
       _clock = clock,
       _idGenerator = idGenerator;

  final StudyGoalRepository _goals;
  final AppTimeZone _timeZone;
  final AppClock _clock;
  final IdGenerator _idGenerator;

  /// [targetCardCount] is in qualified Cards — `metrics-v1` fixes the v1 unit,
  /// and the schema stores `target_card_count`.
  ///
  /// A disabled goal keeps its last target so re-enabling does not ask the
  /// question again (§5: "Disabled: target control disabled nhưng last target
  /// có thể giữ để re-enable").
  Future<DailyGoal> call({
    required bool isEnabled,
    required int targetCardCount,
  }) async {
    // §5: an enabled goal needs a positive target. A disabled one is not held
    // to it — there is nothing to measure against — but a non-positive value
    // must never reach the schema, whose CHECK forbids it either way.
    if (targetCardCount <= 0) {
      throw ValidationFailure(
        field: 'targetCardCount',
        code: isEnabled ? 'required' : 'invalid',
      );
    }

    final now = _clock.nowUtc();
    final existing = await _goals.latestGoal();

    if (existing != null) {
      await _goals.updateGoal(
        existing.id,
        isEnabled: isEnabled,
        targetCardCount: targetCardCount,
        updatedAt: now,
      );
      return DailyGoal(
        id: existing.id,
        isEnabled: isEnabled,
        targetCardCount: targetCardCount,
        // The effective-from date and zone are the configuration's origin, not
        // its last edit: rewriting them would move a goal that has already been
        // measured against (§1 "không rewrite completed Sessions").
        effectiveFromLocalDate: existing.effectiveFromLocalDate,
        timezoneId: existing.timezoneId,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
    }

    final goal = DailyGoal(
      id: _idGenerator.newId(),
      isEnabled: isEnabled,
      targetCardCount: targetCardCount,
      effectiveFromLocalDate: _timeZone.localDayOf(now).toString(),
      timezoneId: _timeZone.id,
      createdAt: now,
      updatedAt: now,
    );
    await _goals.createGoal(goal);
    return goal;
  }
}

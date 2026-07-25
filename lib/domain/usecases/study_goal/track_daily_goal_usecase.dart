import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import 'package:memox_v6/domain/study_goal/daily_goal_contribution.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';

/// Aggregates a finalized session's qualified cards into the current local
/// day's goal bucket (`track-daily-goal.md`).
///
/// The unit is qualified Cards, per `metrics-v1` ("Daily Goal unit v1 is
/// qualified Cards") and the schema's `target_card_count` /
/// `qualified_card_count`. The kit's study-result shot reads "14/20 min", but
/// its own `StreakGoalCard.d.ts` records those as hardcoded sample values that
/// "Flutter parameterizes" — the shot does not fix the unit.
///
/// Contribution idempotency is inherited, not re-implemented: there is no
/// contribution ledger because the day bucket rides the session-finalize
/// exactly-once contract (schema-v1 atomic operation 5), which is what stops a
/// retried finalize double-counting.
class TrackDailyGoalUseCase {
  const TrackDailyGoalUseCase({
    required StudyGoalRepository goals,
    required AppTimeZone timeZone,
    required IdGenerator idGenerator,
  }) : _goals = goals,
       _timeZone = timeZone,
       _idGenerator = idGenerator;

  final StudyGoalRepository _goals;
  final AppTimeZone _timeZone;
  final IdGenerator _idGenerator;

  Future<DailyGoalContribution> call({
    required int qualifiedCardCount,
    required DateTime finalizedAt,
  }) async {
    final goal = await _goals.latestGoal();
    if (goal == null || !goal.isEnabled) {
      return const DailyGoalContribution.inactive();
    }

    final localDate = _timeZone.localDayOf(finalizedAt).toString();
    final existing = await _goals.dayProgress(localDate);

    // The target is read from the bucket when one exists, so a goal edited
    // mid-day cannot retroactively change what today was measured against
    // (`handle-goal-day-boundary.md`); a fresh day snapshots the current one.
    final target = existing?.targetSnapshot ?? goal.targetCardCount;
    final previousAmount = existing?.qualifiedCardCount ?? 0;

    // Clamped at zero: §1 requires the current value never go negative, and a
    // caller passing a negative count is a bug rather than a subtraction.
    final contribution = qualifiedCardCount < 0 ? 0 : qualifiedCardCount;
    final currentAmount = previousAmount + contribution;

    final wasMet = existing?.isMet ?? false;
    final isMet = currentAmount >= target;

    await _goals.recordDayProgress(
      GoalDayProgress(
        id: existing?.id ?? _idGenerator.newId(),
        localDate: localDate,
        timezoneId: _timeZone.id,
        goalId: goal.id,
        qualifiedCardCount: currentAmount,
        targetSnapshot: target,
        // Never un-met: a day that crossed its target stays met even if the
        // target is later raised (§1 "Goal vượt target vẫn giữ completed
        // state").
        isMet: wasMet || isMet,
        updatedAt: finalizedAt,
      ),
    );

    return DailyGoalContribution(
      previousAmount: previousAmount,
      currentAmount: currentAmount,
      target: target,
      wasMet: wasMet,
      isMet: wasMet || isMet,
    );
  }
}

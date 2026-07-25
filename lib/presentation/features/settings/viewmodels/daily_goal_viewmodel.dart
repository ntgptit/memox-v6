import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_goal_viewmodel.g.dart';

/// The configured daily goal, or null when none is set (WBS study-goal;
/// `set-daily-study-goal.md`). One-shot read — a save invalidates it.
@riverpod
Future<DailyGoal?> dailyGoal(Ref ref) {
  return ref.watch(loadDailyGoalUseCaseProvider).call();
}

/// Saves the daily goal configuration.
///
/// Keeps the enable flag and target together in one command, because
/// `set-daily-study-goal.md` §1 has a single effective configuration: saving
/// them separately would publish a half-applied goal between the two writes.
@Riverpod(keepAlive: true)
class DailyGoalCommandViewmodel extends _$DailyGoalCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> updateGoal({
    required bool isEnabled,
    required int targetCardCount,
  }) async {
    state = const AsyncLoading<void>();
    state = await runMxAction(() async {
      await ref
          .read(setDailyStudyGoalUseCaseProvider)
          .call(isEnabled: isEnabled, targetCardCount: targetCardCount);
    });
    // The readers derive from the stored goal rather than caching it, so
    // invalidating the read is all that is needed for Today and the result
    // screen to pick the change up.
    ref.invalidate(dailyGoalProvider);
  }
}

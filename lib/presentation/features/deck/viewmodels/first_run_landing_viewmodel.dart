import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'first_run_landing_viewmodel.g.dart';

/// "Not now" command on the first-use landing (WBS 5.2.3A): persists
/// the dismissal so onboarding never auto-reopens, then the screen
/// navigates to the empty Dashboard.
@riverpod
class DismissFirstRunViewmodel extends _$DismissFirstRunViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> dismissFirstRunLanding() async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading();
    state = await runMxAction(() async {
      await ref.read(dismissFirstRunUseCaseProvider)();
    });
  }
}

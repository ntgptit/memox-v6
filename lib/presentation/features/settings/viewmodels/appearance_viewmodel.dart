import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appearance_viewmodel.g.dart';

/// The effective appearance mode (WBS 8.1; `set-appearance-preference.md`). A
/// one-shot read that the command invalidates on change so the whole app
/// re-themes; `ThemeMode.system` handles live OS-theme changes natively.
@riverpod
Future<AppearanceMode> appearanceMode(Ref ref) {
  return ref.watch(setAppearancePreferenceUseCaseProvider).current();
}

/// Persists the chosen appearance mode (WBS 8.1). Kept alive because the picker
/// only reads it. On success it invalidates [appearanceModeProvider] so the app
/// re-themes; rapid switches keep the latest value.
@Riverpod(keepAlive: true)
class AppearanceCommandViewmodel extends _$AppearanceCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> selectAppearance(AppearanceMode mode) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref.read(setAppearancePreferenceUseCaseProvider).setMode(mode);
    });
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(appearanceModeProvider);
    }
  }
}

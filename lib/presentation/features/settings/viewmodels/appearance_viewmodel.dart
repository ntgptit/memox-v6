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

  /// Which selection is current. Incremented per tap so a slower earlier
  /// write cannot decide the outcome of a faster later one.
  int _selection = 0;

  Future<void> selectAppearance(AppearanceMode mode) async {
    final selection = ++_selection;
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref.read(setAppearancePreferenceUseCaseProvider).setMode(mode);
    });
    // §4: "Rapid selection chỉ latest value thắng." The writes themselves land
    // in tap order — drift runs statements on one connection in submission
    // order — but their results come back whenever they come back. Without
    // this, a superseded tap's result would set the state and invalidate the
    // read, and the sheet would close on the wrong selection's success.
    if (selection != _selection) return;
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(appearanceModeProvider);
    }
  }
}

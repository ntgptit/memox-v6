import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/appearance_viewmodel.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/mode_preferences_viewmodel.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restore_defaults_viewmodel.g.dart';

/// Restores every managed preference to its default (WBS 8.6;
/// `restore-default-preferences.md`). Kept alive because the settings row only
/// reads it; on success it invalidates the preference reads so the app
/// re-applies the defaults.
@Riverpod(keepAlive: true)
class RestoreDefaultsCommandViewmodel
    extends _$RestoreDefaultsCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> restoreDefaults() async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref
          .read(restoreDefaultPreferencesUseCaseProvider)
          .restoreDefaults();
    });
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(appearanceModeProvider);
      ref.invalidate(modePreferencesProvider);
    }
  }
}

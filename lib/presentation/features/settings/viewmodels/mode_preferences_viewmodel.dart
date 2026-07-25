import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_modes/mode_preferences.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mode_preferences_viewmodel.g.dart';

/// The effective Practice mode preferences (WBS 8.3;
/// `configure-mode-preferences.md`) — always a valid, normalized configuration.
/// A one-shot read; the save command invalidates it.
@riverpod
Future<ModePreferences> modePreferences(Ref ref) {
  return ref.watch(setModePreferencesUseCaseProvider).current();
}

/// Persists an edited Practice mode configuration (WBS 8.3). Kept alive because
/// the settings form only reads it; on success it invalidates
/// [modePreferencesProvider] so the effective config refreshes. The use case
/// validates and rejects an invalid configuration as a typed failure.
@Riverpod(keepAlive: true)
class ModePreferencesCommandViewmodel
    extends _$ModePreferencesCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> setModePreferences(ModePreferences preferences) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref
          .read(setModePreferencesUseCaseProvider)
          .setPreferences(preferences);
    });
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(modePreferencesProvider);
    }
  }
}

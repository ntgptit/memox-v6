import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_modes/mode_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mode_preferences_viewmodel.g.dart';

/// The effective Practice mode preferences (WBS 8.3;
/// `configure-mode-preferences.md`) — always a valid, normalized configuration.
/// A one-shot read; the reorder command invalidates it on save.
@riverpod
Future<ModePreferences> modePreferences(Ref ref) {
  return ref.watch(setModePreferencesUseCaseProvider).current();
}

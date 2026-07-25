import 'package:memox_v6/domain/preferences/preference_repository.dart';
import 'package:memox_v6/domain/usecases/preferences/set_appearance_preference_usecase.dart';
import 'package:memox_v6/domain/usecases/preferences/set_mode_preferences_usecase.dart';

/// Restores the app preferences to their defaults (WBS 8.6;
/// `restore-default-preferences.md`).
///
/// It clears each managed preference key; every reader then falls back to its
/// own defined default (appearance → System, Practice modes → all selectable in
/// canonical order). Content, Progress and completed sessions are untouched.
/// New preference groups extend this as they land.
class RestoreDefaultPreferencesUseCase {
  const RestoreDefaultPreferencesUseCase({
    required PreferenceRepository preferences,
  }) : _preferences = preferences;

  final PreferenceRepository _preferences;

  Future<void> restoreDefaults() async {
    await _preferences.remove(SetAppearancePreferenceUseCase.preferenceKey);
    await _preferences.remove(SetModePreferencesUseCase.preferenceKey);
  }
}

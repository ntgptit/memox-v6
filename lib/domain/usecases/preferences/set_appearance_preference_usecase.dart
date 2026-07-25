import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';

/// Reads and persists the app-wide appearance preference (WBS 8.1;
/// `set-appearance-preference.md`).
///
/// The preference only selects a supported [AppearanceMode]; the Design System
/// owns the tokens. A stored value that fails to decode reads as [system]
/// (§1 invalid-fallback), and changing it never touches content or progress.
class SetAppearancePreferenceUseCase {
  const SetAppearancePreferenceUseCase({
    required PreferenceRepository preferences,
    required AppClock clock,
  }) : _preferences = preferences,
       _clock = clock;

  final PreferenceRepository _preferences;
  final AppClock _clock;

  static const String preferenceKey = 'appearanceMode';
  static const int _schemaVersion = 1;

  Future<AppearanceMode> current() async {
    final entry = await _preferences.read(preferenceKey);
    return AppearanceMode.fromStorage(entry?.value);
  }

  /// The effective mode, re-emitting when the stored preference changes so the
  /// whole app re-themes in place.
  Stream<AppearanceMode> watch() {
    return _preferences
        .watch(preferenceKey)
        .map((entry) => AppearanceMode.fromStorage(entry?.value));
  }

  Future<void> setMode(AppearanceMode mode) {
    return _preferences.save(
      preferenceKey,
      value: mode.storageValue,
      schemaVersion: _schemaVersion,
      updatedAt: _clock.nowUtc(),
    );
  }
}

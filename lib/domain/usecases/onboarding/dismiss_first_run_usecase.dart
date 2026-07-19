import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';

/// Persists the "Not now" decision on the first-use landing
/// (WBS 5.2.3A; `create-deck.md` §4): once dismissed, the app never
/// auto-reopens onboarding on later launches — the empty Dashboard
/// keeps its own create CTA instead.
class DismissFirstRunUseCase {
  const DismissFirstRunUseCase({
    required PreferenceRepository preferences,
    required AppClock clock,
  }) : _preferences = preferences,
       _clock = clock;

  static const String preferenceKey = 'firstRunLandingDismissed';
  static const int preferenceSchemaVersion = 1;

  final PreferenceRepository _preferences;
  final AppClock _clock;

  Future<void> call() {
    return _preferences.save(
      preferenceKey,
      value: true,
      schemaVersion: preferenceSchemaVersion,
      updatedAt: _clock.nowUtc(),
    );
  }

  /// Whether the landing was dismissed on an earlier launch.
  Future<bool> wasDismissed() async {
    final entry = await _preferences.read(preferenceKey);
    return entry?.value == true;
  }
}

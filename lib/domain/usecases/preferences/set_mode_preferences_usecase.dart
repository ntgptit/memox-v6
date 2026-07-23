import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';
import 'package:memox_v6/domain/study_modes/mode_preferences.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// Reads and persists the Practice mode preferences (WBS 8.3;
/// `configure-mode-preferences.md`).
///
/// A read runs the persisted ids through [ModePreferencesPolicy.normalizeEnabled]
/// (dropping unknown / non-selectable / duplicate modes) and repairs the default
/// into the enabled set, so `current` always returns a valid configuration —
/// an unset or corrupt value falls back to every selectable mode in canonical
/// order (§§1,4 safe-fallback). A write validates against the policy and rejects
/// an invalid configuration with a typed [ValidationFailure]; newLearning's
/// fixed five-stage plan is never affected (ST-TYPE-002).
class SetModePreferencesUseCase {
  const SetModePreferencesUseCase({
    required PreferenceRepository preferences,
    required AppClock clock,
    ModePreferencesPolicy policy = const ModePreferencesPolicy(),
  }) : _preferences = preferences,
       _clock = clock,
       _policy = policy;

  final PreferenceRepository _preferences;
  final AppClock _clock;
  final ModePreferencesPolicy _policy;

  static const String preferenceKey = 'modePreferences';
  static const int _schemaVersion = 1;

  ModePreferences get _defaults => ModePreferences(
    enabledInOrder: _policy.selectableModes,
    defaultMode: _policy.selectableModes.first,
  );

  Future<ModePreferences> current() async {
    final entry = await _preferences.read(preferenceKey);
    final value = entry?.value;
    if (value is! Map) return _defaults;

    final rawEnabled = value['enabled'];
    final enabledIds = rawEnabled is List
        ? rawEnabled.whereType<String>().toList()
        : const <String>[];
    final enabled = _policy.normalizeEnabled(enabledIds);
    if (enabled.isEmpty) return _defaults;

    final rawDefault = value['default'];
    final storedDefault = rawDefault is String
        ? StudyModeType.tryFromId(rawDefault)
        : null;
    final defaultMode = storedDefault != null && enabled.contains(storedDefault)
        ? storedDefault
        : enabled.first;

    return ModePreferences(enabledInOrder: enabled, defaultMode: defaultMode);
  }

  Future<void> setPreferences(ModePreferences preferences) async {
    final error = _policy.validate(preferences);
    if (error != null) {
      throw ValidationFailure(field: 'modePreferences', code: error.name);
    }
    await _preferences.save(
      preferenceKey,
      value: <String, Object?>{
        'enabled': preferences.enabledInOrder.map((mode) => mode.id).toList(),
        'default': preferences.defaultMode.id,
      },
      schemaVersion: _schemaVersion,
      updatedAt: _clock.nowUtc(),
    );
  }
}

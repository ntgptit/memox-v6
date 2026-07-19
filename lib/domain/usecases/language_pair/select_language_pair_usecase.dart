import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';

/// Persists the active language pair selection (WBS 5.1.1).
///
/// Selection is by stable pair id, never display label
/// (`select-language-pair.md`), stored as a versioned preference so it
/// survives restart and follows the invalid-fallback read contract.
class SelectLanguagePairUseCase {
  const SelectLanguagePairUseCase({
    required LanguagePairRepository pairs,
    required PreferenceRepository preferences,
    required AppClock clock,
  }) : _pairs = pairs,
       _preferences = preferences,
       _clock = clock;

  static const String preferenceKey = 'activeLanguagePairId';
  static const int preferenceSchemaVersion = 1;

  final LanguagePairRepository _pairs;
  final PreferenceRepository _preferences;
  final AppClock _clock;

  Future<void> call(String pairId) async {
    final pair = await _pairs.findById(pairId);
    if (pair == null) {
      throw ValidationFailure(field: 'languagePairId', code: 'unknown');
    }
    await _preferences.save(
      preferenceKey,
      value: pairId,
      schemaVersion: preferenceSchemaVersion,
      updatedAt: _clock.nowUtc(),
    );
  }

  /// The currently selected pair, or null when none is selected or the
  /// stored id no longer resolves (removed pair, corrupt preference).
  Future<LanguagePair?> activePair() async {
    final entry = await _preferences.read(preferenceKey);
    final pairId = entry?.value;
    if (pairId is! String) return null;
    return _pairs.findById(pairId);
  }
}

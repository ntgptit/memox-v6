import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/domain/study_modes/mode_preferences.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/usecases/preferences/restore_default_preferences_usecase.dart';
import 'package:memox_v6/domain/usecases/preferences/set_appearance_preference_usecase.dart';
import 'package:memox_v6/domain/usecases/preferences/set_mode_preferences_usecase.dart';

/// WBS 8.6 — restoring defaults clears the managed preference keys so each
/// reader falls back to its default (restore-default-preferences.md).
void main() {
  late db.AppDatabase database;
  late DriftPreferenceRepository preferences;
  late SetAppearancePreferenceUseCase appearance;
  late SetModePreferencesUseCase modes;
  late RestoreDefaultPreferencesUseCase restore;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    preferences = DriftPreferenceRepository(database);
    appearance = SetAppearancePreferenceUseCase(
      preferences: preferences,
      clock: const SystemClock(),
    );
    modes = SetModePreferencesUseCase(
      preferences: preferences,
      clock: const SystemClock(),
    );
    restore = RestoreDefaultPreferencesUseCase(preferences: preferences);
  });

  tearDown(() async {
    await database.close();
  });

  test('restore returns appearance and mode preferences to defaults', () async {
    await appearance.setMode(AppearanceMode.dark);
    await modes.setPreferences(
      const ModePreferences(
        enabledInOrder: [StudyModeType.fill],
        defaultMode: StudyModeType.fill,
      ),
    );
    expect(await appearance.current(), AppearanceMode.dark);
    expect((await modes.current()).enabledInOrder, [StudyModeType.fill]);

    await restore.restoreDefaults();

    expect(await appearance.current(), AppearanceMode.system);
    expect((await modes.current()).enabledInOrder, [
      StudyModeType.review,
      StudyModeType.match,
      StudyModeType.guess,
      StudyModeType.recall,
      StudyModeType.fill,
    ]);
  });

  test('restore is safe when nothing was customised', () async {
    await restore.restoreDefaults();
    expect(await appearance.current(), AppearanceMode.system);
  });
}

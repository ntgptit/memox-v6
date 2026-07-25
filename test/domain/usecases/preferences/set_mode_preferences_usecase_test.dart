import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/domain/study_modes/mode_preferences.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/usecases/preferences/set_mode_preferences_usecase.dart';

/// WBS 8.3 — mode preferences persist a valid, normalized Practice
/// configuration and fall back safely for unset/corrupt data
/// (configure-mode-preferences.md §§1,4).
void main() {
  late db.AppDatabase database;
  late DriftPreferenceRepository preferences;
  late SetModePreferencesUseCase usecase;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    preferences = DriftPreferenceRepository(database);
    usecase = SetModePreferencesUseCase(
      preferences: preferences,
      clock: const SystemClock(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('unset reads every selectable mode in canonical order', () async {
    final prefs = await usecase.current();
    expect(prefs.enabledInOrder, [
      StudyModeType.review,
      StudyModeType.match,
      StudyModeType.guess,
      StudyModeType.recall,
      StudyModeType.fill,
    ]);
    expect(prefs.defaultMode, StudyModeType.review);
  });

  test('a saved configuration reads back', () async {
    await usecase.setPreferences(
      const ModePreferences(
        enabledInOrder: [StudyModeType.fill, StudyModeType.guess],
        defaultMode: StudyModeType.guess,
      ),
    );
    final prefs = await usecase.current();
    expect(prefs.enabledInOrder, [StudyModeType.fill, StudyModeType.guess]);
    expect(prefs.defaultMode, StudyModeType.guess);
  });

  test('an all-disabled configuration is rejected', () async {
    await expectLater(
      usecase.setPreferences(
        const ModePreferences(
          enabledInOrder: [],
          defaultMode: StudyModeType.review,
        ),
      ),
      throwsA(
        isA<ValidationFailure>().having((f) => f.code, 'code', 'noneEnabled'),
      ),
    );
  });

  test('a default outside the enabled set is rejected', () async {
    await expectLater(
      usecase.setPreferences(
        const ModePreferences(
          enabledInOrder: [StudyModeType.review],
          defaultMode: StudyModeType.fill,
        ),
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.code,
          'code',
          'defaultNotEnabled',
        ),
      ),
    );
  });

  test(
    'a stored default no longer enabled repairs to the first enabled',
    () async {
      // Persist a raw payload whose default is not in the enabled list — the
      // safe-fallback read repairs it rather than discarding the config.
      await preferences.save(
        SetModePreferencesUseCase.preferenceKey,
        value: const <String, Object?>{
          'enabled': ['match', 'guess'],
          'default': 'review',
        },
        schemaVersion: 1,
        updatedAt: DateTime.utc(2026, 7, 24),
      );
      final prefs = await usecase.current();
      expect(prefs.enabledInOrder, [StudyModeType.match, StudyModeType.guess]);
      expect(prefs.defaultMode, StudyModeType.match);
    },
  );

  test('unknown and session-only ids are dropped on read', () async {
    await preferences.save(
      SetModePreferencesUseCase.preferenceKey,
      value: const <String, Object?>{
        'enabled': ['guess', 'legacyMode', 'srsBinaryReview', 'guess'],
        'default': 'guess',
      },
      schemaVersion: 1,
      updatedAt: DateTime.utc(2026, 7, 24),
    );
    final prefs = await usecase.current();
    expect(prefs.enabledInOrder, [StudyModeType.guess]);
    expect(prefs.defaultMode, StudyModeType.guess);
  });
}

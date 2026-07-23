import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/domain/usecases/preferences/set_appearance_preference_usecase.dart';

/// WBS 8.1 — the appearance preference persists a supported mode and falls back
/// to System for a missing or invalid value (set-appearance-preference.md §1).
void main() {
  late db.AppDatabase database;
  late SetAppearancePreferenceUseCase usecase;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    usecase = SetAppearancePreferenceUseCase(
      preferences: DriftPreferenceRepository(database),
      clock: const SystemClock(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('unset preference reads as System', () async {
    expect(await usecase.current(), AppearanceMode.system);
  });

  test('setMode persists and current reads it back', () async {
    await usecase.setMode(AppearanceMode.dark);
    expect(await usecase.current(), AppearanceMode.dark);

    await usecase.setMode(AppearanceMode.light);
    expect(await usecase.current(), AppearanceMode.light);
  });

  test('watch emits the effective mode as it changes', () async {
    final seen = <AppearanceMode>[];
    final sub = usecase.watch().listen(seen.add);
    await usecase.setMode(AppearanceMode.dark);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(seen.last, AppearanceMode.dark);
  });

  test('an invalid stored value decodes to System', () {
    expect(AppearanceMode.fromStorage('neon'), AppearanceMode.system);
    expect(AppearanceMode.fromStorage(null), AppearanceMode.system);
    expect(AppearanceMode.fromStorage('dark'), AppearanceMode.dark);
  });
}

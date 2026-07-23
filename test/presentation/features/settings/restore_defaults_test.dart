import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/domain/usecases/preferences/set_appearance_preference_usecase.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

/// WBS 8.6 — the Restore defaults row confirms, then resets preferences.
void main() {
  late db.AppDatabase database;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    // Pre-set a non-default appearance to observe the reset.
    await SetAppearancePreferenceUseCase(
      preferences: DriftPreferenceRepository(database),
      clock: const SystemClock(),
    ).setMode(AppearanceMode.dark);
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfilePlaceholderScreen(),
      ),
    );
  }

  Future<AppearanceMode> storedAppearance() {
    return SetAppearancePreferenceUseCase(
      preferences: DriftPreferenceRepository(database),
      clock: const SystemClock(),
    ).current();
  }

  testWidgets('confirming Restore defaults resets the preferences', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(await storedAppearance(), AppearanceMode.dark);

    await tester.tap(find.text('Restore defaults'));
    await tester.pumpAndSettle();

    expect(find.text('Restore default settings?'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(await storedAppearance(), AppearanceMode.system);
  });

  testWidgets('cancelling keeps the current preferences', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore defaults'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await storedAppearance(), AppearanceMode.dark);
  });
}

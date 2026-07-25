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

/// WBS 8.1 — the Profile settings hub opens the Appearance sheet; picking a mode
/// persists it (set-appearance-preference.md).
void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
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

  Future<AppearanceMode> storedMode() {
    return SetAppearancePreferenceUseCase(
      preferences: DriftPreferenceRepository(database),
      clock: const SystemClock(),
    ).current();
  }

  testWidgets('picking Dark from the Appearance sheet persists it', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    // The sheet shows the three supported options.
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(await storedMode(), AppearanceMode.dark);
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_landing_screen.dart';

import '../../support/kit_parity.dart';

/// Kit-parity gate (WBS 3.15): the shipped first-run landing must stay
/// within the pre-merge threshold against its kit shot, light and dark.
void main() {
  const threshold = 0.03;

  late db.AppDatabase database;

  setUpAll(loadAppFonts);

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Widget app(Brightness brightness) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FirstRunLandingScreen(),
      ),
    );
  }

  Future<void> pumpStreams(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> expectParity(WidgetTester tester, String shotName) async {
    final shot = kitShotSize(shotName);
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = shot;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(shotName.endsWith('--dark') ? Brightness.dark : Brightness.light),
    );
    await pumpStreams(tester);

    final result = await compareWithKitShot(
      tester,
      find.byType(MaterialApp),
      shotName: shotName,
    );
    expect(
      result.ratio,
      lessThan(threshold),
      reason:
          '$shotName differs by '
          '${(result.ratio * 100).toStringAsFixed(2)}% (gate: <3%)',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('first-run landing matches its kit shot (light)', (tester) async {
    await expectParity(tester, 'create-deck-firstrun--landing--light');
  });

  testWidgets('first-run landing matches its kit shot (dark)', (tester) async {
    await expectParity(tester, 'create-deck-firstrun--landing--dark');
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_landing_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/library_screen.dart';

import '../../support/kit_parity.dart';

/// Parity measurement probe (WBS 3.15A): prints the current diff ratio
/// of shipped screens against their kit shots. Enforcement tests grow
/// from these measurements.
void main() {
  late db.AppDatabase database;

  setUpAll(loadAppFonts);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.preferenceDao.upsertPreference(
      'activeLanguagePairId',
      '"lp1"',
      1,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget app(Widget home, Brightness brightness) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  Future<void> pumpStreams(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> probe(
    WidgetTester tester, {
    required Widget home,
    required String shotName,
    required Brightness brightness,
  }) async {
    final shot = kitShotSize(shotName);
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = shot;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(home, brightness));
    await pumpStreams(tester);

    final result = await compareWithKitShot(
      tester,
      find.byType(MaterialApp),
      shotName: shotName,
    );
    // ignore: avoid_print
    print(
      'PARITY $shotName: '
      '${(result.ratio * 100).toStringAsFixed(2)}% differing '
      '(kit ${result.kitSize}, rendered ${result.renderedSize})',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('measure first-run landing vs kit', (tester) async {
    await probe(
      tester,
      home: const FirstRunLandingScreen(),
      shotName: 'create-deck-firstrun--landing--light',
      brightness: Brightness.light,
    );
  });

  testWidgets('measure library empty vs kit', (tester) async {
    await probe(
      tester,
      home: const LibraryScreen(),
      shotName: 'library--empty--light',
      brightness: Brightness.light,
    );
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_deck_setup_screen.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/first_run_deck_viewmodel.dart';

import '../../support/kit_parity.dart';

/// Kit-parity gate (WBS 3.15): the first-run deck step (step 2) must
/// stay within the pre-merge threshold against its kit shot. The kit
/// fixture shows the Korean -> Vietnamese pair and "Korean TOPIK I".
void main() {
  late db.AppDatabase database;

  setUpAll(loadAppFonts);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'ko',
      'vi',
      'ko|vi',
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
        home: const FirstRunDeckSetupScreen(),
      ),
    );
  }

  Future<void> typeKitFixtureName(WidgetTester tester) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FirstRunDeckSetupScreen)),
    );
    container
        .read(firstRunDeckDraftViewmodelProvider.notifier)
        .setDeckName('Korean TOPIK I');
    await tester.enterText(find.byType(TextField).first, 'Korean TOPIK I');
    // The kit shot shows the field at rest, not focused.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }

  testWidgets('first-run step 2 matches its kit shot (light)', (tester) async {
    await expectKitParity(
      tester,
      app: app(Brightness.light),
      shotName: 'create-deck-firstrun--step2--light',
      prepare: typeKitFixtureName,
    );
  });

  testWidgets('first-run step 2 matches its kit shot (dark)', (tester) async {
    await expectKitParity(
      tester,
      app: app(Brightness.dark),
      shotName: 'create-deck-firstrun--step2--dark',
      prepare: typeKitFixtureName,
    );
  });
}

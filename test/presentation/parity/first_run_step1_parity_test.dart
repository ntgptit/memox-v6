import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/language_pair/screens/first_run_language_screen.dart';
import 'package:memox_v6/presentation/features/language_pair/viewmodels/first_run_language_viewmodel.dart';

import '../../support/kit_parity.dart';

/// Kit-parity gate (WBS 3.15): the first-run language step (step 1)
/// must stay within the pre-merge threshold against its kit shot. The
/// kit fixture shows Korean → Vietnamese selected.
void main() {
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
        home: const FirstRunLanguageScreen(),
      ),
    );
  }

  Future<void> selectKitFixturePair(WidgetTester tester) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FirstRunLanguageScreen)),
    );
    container.read(firstRunLanguageDraftViewmodelProvider.notifier)
      ..setLearningLanguage('ko')
      ..setMeaningLanguage('vi');
    await tester.pump();
  }

  testWidgets('first-run step 1 matches its kit shot (light)', (tester) async {
    await expectKitParity(
      tester,
      app: app(Brightness.light),
      shotName: 'create-deck-firstrun--step1--light',
      prepare: selectKitFixturePair,
    );
  });

  testWidgets('first-run step 1 matches its kit shot (dark)', (tester) async {
    await expectKitParity(
      tester,
      app: app(Brightness.dark),
      shotName: 'create-deck-firstrun--step1--dark',
      prepare: selectKitFixturePair,
    );
  });
}

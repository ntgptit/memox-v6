import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/screens/card_editor_screen.dart';

import '../../support/kit_parity.dart';

/// Kit-parity gate (WBS 3.15/5.3.2A): the Card Editor create state
/// must stay within the pre-merge threshold against its kit shot. The
/// kit fixture deck is "Beginner Grammar" (Korean term → English
/// meaning).
void main() {
  late db.AppDatabase database;

  setUpAll(loadAppFonts);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'ko',
      'en',
      'ko|en',
      0,
      0,
    );
    await database.preferenceDao.upsertPreference(
      'activeLanguagePairId',
      '"lp1"',
      1,
      0,
    );
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Beginner Grammar',
      'beginner grammar',
      0,
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
        home: const CardEditorScreen(deckId: 'd1'),
      ),
    );
  }

  testWidgets('card editor create matches its kit shot (light)', (
    tester,
  ) async {
    await expectKitParity(
      tester,
      app: app(Brightness.light),
      shotName: 'flashcard-editor--create--light',
    );
  });

  testWidgets('card editor create matches its kit shot (dark)', (tester) async {
    await expectKitParity(
      tester,
      app: app(Brightness.dark),
      shotName: 'flashcard-editor--create--dark',
    );
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/screens/deck_detail_screen.dart';

import '../../support/kit_parity.dart';

/// Kit-parity gate (WBS 3.15): the empty deck screen (open-deck §5,
/// kit `empty-deck--default`) — unblocked by 5.3.2A activating the
/// Add card CTA. The kit fixture opens "Korean TOPIK I".
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
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Korean TOPIK I',
      'korean topik i',
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
        home: const DeckDetailScreen(deckId: 'd1'),
      ),
    );
  }

  testWidgets('empty deck matches its kit shot (light)', (tester) async {
    await expectKitParity(
      tester,
      app: app(Brightness.light),
      shotName: 'empty-deck--default--light',
    );
  });

  testWidgets('empty deck matches its kit shot (dark)', (tester) async {
    await expectKitParity(
      tester,
      app: app(Brightness.dark),
      shotName: 'empty-deck--default--dark',
    );
  });
}

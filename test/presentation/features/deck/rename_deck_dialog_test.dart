import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';

/// WBS 6.1 — the deck app-bar Rename action opens a pre-filled dialog whose Save
/// renames the deck (edit-deck.md, kit deck-settings--rename).
void main() {
  late db.AppDatabase database;

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
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: RoutePaths.deckDetail('root'),
      routes: deckRoutes(),
    );
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Future<void> pumpStreams(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> disposeAndFlushStreams(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('renames the deck from the pre-filled dialog', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.byIcon(Symbols.edit_rounded));
    await pumpStreams(tester);

    // The dialog opens pre-filled with the current name.
    expect(find.text('Rename deck'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Korean');

    await tester.enterText(find.byType(TextField), 'Japanese');
    await pumpStreams(tester);
    await tester.tap(find.text('Save'));
    await pumpStreams(tester);

    // Dialog closed; the app bar title reflects the renamed deck.
    expect(find.text('Rename deck'), findsNothing);
    expect(find.text('Japanese'), findsWidgets);

    final row = await database
        .customSelect("SELECT name FROM decks WHERE id = 'root'")
        .getSingle();
    expect(row.read<String>('name'), 'Japanese');

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a duplicate sibling name shows the inline error', (
    tester,
  ) async {
    await database.deckDao.insertDeck(
      'sib',
      'lp1',
      null,
      'Japanese',
      'japanese',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.byIcon(Symbols.edit_rounded));
    await pumpStreams(tester);
    await tester.enterText(find.byType(TextField), 'Japanese');
    await pumpStreams(tester);
    await tester.tap(find.text('Save'));
    await pumpStreams(tester);

    expect(
      find.text('A deck with this name already exists here.'),
      findsOneWidget,
    );

    await disposeAndFlushStreams(tester);
  });
}

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

/// WBS 6.1 — the deck app-bar Delete action opens an impact confirm; Delete deck
/// removes the deck and leaves it, Keep deck cancels (delete-deck.md §4).
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

  Future<bool> deckExists() async {
    final row = await database
        .customSelect("SELECT COUNT(*) AS n FROM decks WHERE id = 'root'")
        .getSingle();
    return row.read<int>('n') > 0;
  }

  testWidgets('Delete deck removes an empty deck and leaves', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.byIcon(Symbols.delete_rounded));
    await pumpStreams(tester);

    expect(find.text('Delete “Korean”?'), findsOneWidget);
    expect(
      find.text('This empty deck will be permanently deleted.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete deck'));
    await pumpStreams(tester);

    expect(await deckExists(), isFalse);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('Keep deck cancels without deleting', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.byIcon(Symbols.delete_rounded));
    await pumpStreams(tester);
    await tester.tap(find.text('Keep deck'));
    await pumpStreams(tester);

    expect(find.text('Delete “Korean”?'), findsNothing);
    expect(await deckExists(), isTrue);

    await disposeAndFlushStreams(tester);
  });
}

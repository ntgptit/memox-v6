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

/// WBS 6.1 — the deck Move action promotes a nested deck to the Library root
/// (move-deck.md). The action shows only for nested decks.
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
      'Root',
      'root',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'child',
      'lp1',
      'root',
      'Child',
      'child',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget app(String initialLocation) {
    final router = GoRouter(
      initialLocation: initialLocation,
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

  Future<String?> parentOf(String id) async {
    final row = await database
        .customSelect("SELECT parent_id FROM decks WHERE id = '$id'")
        .getSingle();
    return row.read<String?>('parent_id');
  }

  testWidgets('moving a nested deck relocates it to the Library root', (
    tester,
  ) async {
    await tester.pumpWidget(app(RoutePaths.deckDetail('child')));
    await pumpStreams(tester);

    await tester.tap(find.byIcon(Symbols.more_vert_rounded));
    await pumpStreams(tester);
    await tester.tap(find.text('Move to Library'));
    await pumpStreams(tester);

    expect(find.text('Move “Child”?'), findsOneWidget);
    await tester.tap(find.text('Move here'));
    await pumpStreams(tester);

    expect(await parentOf('child'), isNull);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a root deck offers no Move action', (tester) async {
    await tester.pumpWidget(app(RoutePaths.deckDetail('root')));
    await pumpStreams(tester);

    await tester.tap(find.byIcon(Symbols.more_vert_rounded));
    await pumpStreams(tester);
    expect(find.text('Move to Library'), findsNothing);
    expect(find.byIcon(Symbols.drive_file_move_rounded), findsNothing);

    await disposeAndFlushStreams(tester);
  });
}

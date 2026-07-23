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
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';

/// WBS 6.1 — the deck Reset action returns the subtree's cards to Box 0 after a
/// confirm; Keep progress cancels (reset-deck-progress.md §4).
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
    await database.flashcardDao.insertFlashcard(
      'c1',
      'root',
      't1',
      't1',
      'm1',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p1',
      'c1',
      5,
      9999,
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

  Future<int> boxOf(String cardId) async {
    final row = await database
        .customSelect(
          "SELECT box FROM learning_progress WHERE card_id = '$cardId'",
        )
        .getSingle();
    return row.read<int>('box');
  }

  testWidgets('Reset progress returns the deck cards to Box 0', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(MxContextualAppBar),
        matching: find.byIcon(Symbols.more_vert_rounded),
      ),
    );
    await pumpStreams(tester);
    await tester.tap(find.text('Reset progress'));
    await pumpStreams(tester);

    expect(find.text('Reset learning progress?'), findsOneWidget);
    await tester.tap(find.text('Reset progress'));
    await pumpStreams(tester);

    expect(await boxOf('c1'), 0);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('Keep progress cancels without resetting', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(MxContextualAppBar),
        matching: find.byIcon(Symbols.more_vert_rounded),
      ),
    );
    await pumpStreams(tester);
    await tester.tap(find.text('Reset progress'));
    await pumpStreams(tester);
    await tester.tap(find.text('Keep progress'));
    await pumpStreams(tester);

    expect(find.text('Reset learning progress?'), findsNothing);
    expect(await boxOf('c1'), 5);

    await disposeAndFlushStreams(tester);
  });
}

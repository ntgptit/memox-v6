import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';

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
  });

  tearDown(() async {
    await database.close();
  });

  late ProviderContainer container;

  Widget app() {
    final router = GoRouter(
      initialLocation: RoutePaths.library,
      routes: deckRoutes(),
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Future<void> pumpLibrary(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> disposeAndFlushStreams(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() {
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
  });

  testWidgets('shows the empty state without decks', (tester) async {
    await tester.pumpWidget(app());
    await pumpLibrary(tester);

    expect(
      find.text('Create a deck or import cards to get started.'),
      findsOneWidget,
    );

    await disposeAndFlushStreams(tester);
  });

  testWidgets('lists roots reactively as decks are created', (tester) async {
    await tester.pumpWidget(app());
    await pumpLibrary(tester);

    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Travel',
      'travel',
      0,
      0,
    );
    await pumpLibrary(tester);

    expect(find.text('Travel'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  test('deck summary counts due and new cards for the meta status', () async {
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
    // c0: never studied → new. c1: scheduled in the past → due. c2: boxed
    // with no due date → neither (up to date).
    await database.flashcardDao.insertFlashcard(
      'c0',
      'd1',
      'a',
      'a',
      'm',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd1',
      'b',
      'b',
      'm',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress('p1', 'c1', 1, 1, 0, 0);
    await database.flashcardDao.insertFlashcard(
      'c2',
      'd1',
      'c',
      'c',
      'm',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p2',
      'c2',
      8,
      null,
      0,
      0,
    );

    final repo = DriftDeckRepository(database, const SystemClock());
    final summaries = await repo.watchRootSummaries('lp1').first;
    final korean = summaries.singleWhere((s) => s.deck.id == 'd1');

    expect(korean.cardCount, 3);
    expect(korean.dueCount, 1);
    expect(korean.newCount, 1);
  });
}

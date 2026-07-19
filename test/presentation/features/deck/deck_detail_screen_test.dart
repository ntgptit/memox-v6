import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Travel',
      'travel',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget app(String initialDeckId) {
    final router = GoRouter(
      initialLocation: RoutePaths.deckDetail(initialDeckId),
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

  Future<void> pumpDeck(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> disposeAndFlushStreams(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('an empty deck shows the content-choice state', (tester) async {
    await tester.pumpWidget(app('root'));
    await pumpDeck(tester);

    expect(find.text('This deck is empty'), findsOneWidget);
    expect(find.text('Add card'), findsOneWidget);
    expect(find.text('Create nested deck'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a leaf deck lists its cards with the count summary', (
    tester,
  ) async {
    await database.flashcardDao.insertFlashcard(
      'c1',
      'root',
      'hello',
      'hello',
      'xin chào',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c2',
      'root',
      'bye',
      'bye',
      'tạm biệt',
      1,
      1,
    );

    await tester.pumpWidget(app('root'));
    await pumpDeck(tester);

    expect(find.text('2 cards'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('bye'), findsOneWidget);
    expect(find.text('Create nested deck'), findsNothing);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a parent deck lists children and browses deeper', (
    tester,
  ) async {
    await database.deckDao.insertDeck(
      'asia',
      'lp1',
      'root',
      'Asia',
      'asia',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c1',
      'asia',
      'hello',
      'hello',
      'xin chào',
      0,
      0,
    );

    await tester.pumpWidget(app('root'));
    await pumpDeck(tester);

    expect(find.textContaining('1 nested decks'), findsOneWidget);
    expect(find.text('Asia'), findsOneWidget);
    expect(find.text('Add card'), findsNothing);

    await tester.tap(find.text('Asia'));
    await pumpDeck(tester);

    // Nested child opened as a Leaf; Back walks up to the parent.
    expect(find.text('1 cards'), findsOneWidget);
    await tester.tap(find.byIcon(Symbols.arrow_back).first);
    await pumpDeck(tester);
    expect(find.textContaining('1 nested decks'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('transitions update in place: first card flips Empty to Leaf', (
    tester,
  ) async {
    await tester.pumpWidget(app('root'));
    await pumpDeck(tester);
    expect(find.text('This deck is empty'), findsOneWidget);

    await database.flashcardDao.insertFlashcard(
      'c1',
      'root',
      'hello',
      'hello',
      'xin chào',
      0,
      0,
    );
    await pumpDeck(tester);

    expect(find.text('This deck is empty'), findsNothing);
    expect(find.text('1 cards'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('an unknown deck shows not-found with the Library exit', (
    tester,
  ) async {
    await tester.pumpWidget(app('missing'));
    await pumpDeck(tester);

    expect(find.text('This deck is no longer available.'), findsOneWidget);
    expect(find.text('Back to Library'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });
}

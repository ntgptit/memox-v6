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
import 'package:memox_v6/presentation/features/flashcard/routes/flashcard_routes.dart';
import 'package:memox_v6/presentation/features/search/routes/search_routes.dart';
import 'package:memox_v6/presentation/features/search/screens/search_screen.dart';

/// WBS 10.2 — the search screen queries the read-model: a blank query shows the
/// prompt, a matching query lists ranked hits, and no hits shows guidance.
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
      'hello',
      'hello',
      'xin chào',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SearchScreen(),
      ),
    );
  }

  testWidgets('a blank query shows the neutral prompt', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Search your decks and cards by name.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a matching query lists the ranked hit', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a query with no hits shows guidance', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No decks or cards match your search.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tapping a card result opens the card editor', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.search,
      routes: [...searchRoutes(), ...deckDetailRoutes(), ...flashcardRoutes()],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();

    // The card opens its editor in edit mode.
    expect(find.text('Edit card'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

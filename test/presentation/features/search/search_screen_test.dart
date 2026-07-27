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
import 'package:memox_v6/domain/search/search_result.dart';
import 'package:memox_v6/domain/search/search_repository.dart';

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

  /// The screen under a real router, for the tests that navigate away and
  /// come back.
  Widget routedApp(GoRouter router) {
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

  // `search-rank-v1` says "Hidden/deleted content bị loại trước ranking", and
  // the sentence after it — "Filters chạy trước ranking" — is what that clause
  // is: the default visibility filter. `int-93` made hidden cards findable,
  // which `hide-flashcard.md` §1 requires, but showed them unconditionally and
  // so dropped that default (`int-98`).
  testWidgets('a hidden card stays out of the results by default', (
    tester,
  ) async {
    await database.customStatement(
      "UPDATE flashcards SET is_hidden = 1 WHERE id = 'c1'",
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsNothing);
    // Not a no-match: the query found something the filter is holding back,
    // and `filter-search-results.md` §4 wants that said with a way out.
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // §1 of `filter-search-results.md` lists visibility as one of the four
  // filter dimensions, and `hide-flashcard.md` §1 keeps a hidden Card
  // findable — search is where a learner goes to find one back. §4 of that
  // spec: its state is a semantic label, "không chỉ opacity/color".
  testWidgets('the Hidden chip brings it back, reading as hidden', (
    tester,
  ) async {
    await database.customStatement(
      "UPDATE flashcards SET is_hidden = 1 WHERE id = 'c1'",
    );
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hidden'));
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
    // The row's own label leads; MxTappable merges its descendants after it,
    // so the state is heard before the term's own text repeats it.
    expect(
      tester.getSemantics(find.text('hello')).label,
      startsWith('hello, hidden'),
    );

    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // The clear on that empty state has to actually clear: resetting only the
  // type chip would leave a query whose only matches are hidden showing the
  // same empty state with the same dead button.
  testWidgets('clearing the filters reveals what they held back', (
    tester,
  ) async {
    await database.customStatement(
      "UPDATE flashcards SET is_hidden = 1 WHERE id = 'c1'",
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // KIT-26-02: no-results must not look like the empty dataset. Both were the
  // same centred caption, so "you haven't searched yet" and "your search found
  // nothing" were indistinguishable; the kit's `search/no-results` is a
  // warning-toned empty state that names the query back.
  testWidgets('a query with no hits names the query it failed on', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
    expect(
      find.text(
        'Nothing matched \u201czzz\u201d. Try another term or check the spelling.',
      ),
      findsOneWidget,
    );
    // The blank-query prompt is a different picture, not the same one.
    expect(find.text('Search your decks and cards by name.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // `filter-search-results.md` §4: "No-results-with-filters nêu Clear/adjust
  // filters", §6: "Clear phục hồi query không filter". A filter that hid every
  // hit claimed the query matched nothing and offered no way back.
  testWidgets('a filter that hides every hit says so and clears', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 'hel' matches the card `hello` and no deck.
    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);

    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.text('No results match these filters'), findsOneWidget);
    expect(
      find.text('No matches'),
      findsNothing,
      reason: 'the query did match — the chip is what hid it',
    );

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a submitted query becomes a recent search on blank', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Clear the field: the recent list shows the committed query.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(find.text('hel'), findsOneWidget);

    // Clear wipes it back to the neutral prompt.
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('RECENT SEARCHES'), findsNothing);
    expect(find.text('Search your decks and cards by name.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // §3: "Row có query và remove action". Dropping one query meant clearing
  // the whole history until now.
  testWidgets('a recent row removes just its own query', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (final query in const <String>['hel', 'wor']) {
      await tester.enterText(find.byType(TextField), query);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('hel'), findsOneWidget);
    expect(find.text('wor'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel('Remove “hel” from recent searches'),
    );
    await tester.pumpAndSettle();

    expect(find.text('hel'), findsNothing);
    expect(find.text('wor'), findsOneWidget, reason: 'the rest stays');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the type filters narrow the results by kind', (tester) async {
    await database.deckDao.insertDeck(
      'appdeck',
      'lp1',
      null,
      'Apple',
      'apple',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c_apple',
      'root',
      'apple',
      'apple',
      'táo',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'app');
    await tester.pumpAndSettle();

    // All: both the deck and the card show.
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);

    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('apple'), findsNothing);

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // `open-search-result.md` §3: "Valid Card → Open Card/detail contract". It
  // opened the *editor*, because no detail screen existed — so looking
  // something up dropped the learner into a form over content they had only
  // asked to look at (`int-100`).
  testWidgets('tapping a card result opens its detail', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.search,
      routes: [...searchRoutes(), ...deckDetailRoutes(), ...flashcardRoutes()],
    );
    await tester.pumpWidget(routedApp(router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();

    // The card opens its detail, which is a read surface: the term is shown,
    // not loaded into a field.
    expect(find.text('Card'), findsWidgets);
    expect(find.text('Edit card'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // `recover-search-failure.md` §3: the primary CTA on a recoverable failure
  // is Retry, and §1's objective is recovery "mà không buộc user nhập lại".
  // There was no retry at all, so the only escape from a failed search was to
  // edit the query — the re-entry this flow exists to prevent.
  testWidgets('a failed search offers a retry that reruns it', (tester) async {
    var failNext = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          searchRepositoryProvider.overrideWith(
            (ref) => _FlakySearch(() => failNext),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'greet');
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    // The query survives the failure — nothing to retype.
    expect(find.text('greet'), findsWidgets);

    failNext = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsNothing);
  });
  // `open-search-result.md` §4: "Sau edit/delete, return refresh affected
  // result/index". Search stays mounted under the pushed route and its list is
  // a future cached per query, so a card deleted in the editor came back to a
  // row that opened an object no longer in the store.
  testWidgets('returning from a result refreshes what it listed', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RoutePaths.search,
      routes: [...searchRoutes(), ...deckDetailRoutes(), ...flashcardRoutes()],
    );
    await tester.pumpWidget(routedApp(router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();
    expect(find.text('Card'), findsWidgets);

    // What the card's delete action does to the store.
    await database.flashcardDao.softDeleteFlashcard(1, 1, 'c1');

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsNothing);
    expect(find.text('No matches'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // §4: "Double tap chỉ tạo một navigation". The pushed route takes a frame to
  // cover the row, and a second tap inside that frame stacked a second copy of
  // the destination that Back then had to be pressed twice to leave.
  testWidgets('a double tap on a result opens one destination', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.search,
      routes: [...searchRoutes(), ...deckDetailRoutes(), ...flashcardRoutes()],
    );
    await tester.pumpWidget(routedApp(router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pumpAndSettle();

    // Both taps land before the route transition rebuilds anything.
    await tester.tap(find.text('hello'));
    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();
    expect(find.text('Card'), findsWidgets);

    router.pop();
    await tester.pumpAndSettle();

    expect(
      find.text('hello'),
      findsOneWidget,
      reason: 'one pop is back on the result list, so only one was pushed',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Fails until told otherwise, so the retry has something to recover from.
class _FlakySearch implements SearchRepository {
  _FlakySearch(this._shouldFail);

  final bool Function() _shouldFail;

  @override
  Future<List<SearchResult>> searchLibrary(
    String languagePairId, {
    required String cardQuery,
    required String deckQuery,
  }) async {
    if (_shouldFail()) throw StateError('search index unavailable');
    return const <SearchResult>[];
  }
}

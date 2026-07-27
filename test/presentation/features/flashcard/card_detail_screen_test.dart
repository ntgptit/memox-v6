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
import 'package:memox_v6/presentation/features/flashcard/routes/flashcard_routes.dart';

/// WBS 6.x — the Card Detail read projection (`view-card-detail.md`).
///
/// The screen did not exist, which is why `open-search-result.md` §3's "Valid
/// Card → Open Card/detail contract" resolved to the editor (`int-100`).
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

  Widget app(String cardId) {
    final router = GoRouter(
      initialLocation: RoutePaths.cardDetail('root', cardId),
      routes: [
        ...flashcardRoutes(),
        // A stub for the deck route, not the real screen: what this file has
        // to prove is that the exit *leaves* Card Detail and lands on the
        // deck's path. Mounting the real deck detail drags its streams into
        // every teardown here, and the deck suite already owns those.
        GoRoute(
          path: RoutePaths.deckDetailPattern,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('deck route')),
          ),
        ),
      ],
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

  Future<void> pumpDetail(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  testWidgets('renders the card, its deck and its progress', (tester) async {
    await database.flashcardDao.insertTranslation(
      't1',
      'c1',
      'vi',
      'chào bạn',
      0,
      0,
      0,
    );

    await tester.pumpWidget(app('c1'));
    await pumpDetail(tester);

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('xin chào'), findsOneWidget);
    // The deck path, which is what tells two same-named cards apart.
    expect(find.text('Korean'), findsOneWidget);
    expect(find.text('chào bạn'), findsOneWidget);
    // Read-only, and honest about a card that has never been scheduled.
    expect(find.text('Not scheduled yet.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  // The spec's not-found row asks the screen to explain that the Card is
  // unavailable and to offer a safe return to its prior list or Deck.
  testWidgets('a deleted card explains itself and offers the deck', (
    tester,
  ) async {
    await database.customStatement(
      "UPDATE flashcards SET deleted_at = 1 WHERE id = 'c1'",
    );

    await tester.pumpWidget(app('c1'));
    await pumpDetail(tester);

    expect(find.text('This card is unavailable'), findsOneWidget);
    expect(find.text('hello'), findsNothing);

    // The exit has to actually leave — a dead end whose only way out is broken
    // is the worst version of this screen.
    await tester.tap(find.text('Back to deck'));
    // Settle rather than pump a fixed budget: the route transition keeps the
    // old page mounted for its duration, so a short pump sees both.
    await tester.pumpAndSettle();
    expect(find.text('deck route'), findsOneWidget);
    expect(find.text('This card is unavailable'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  // A card that is merely hidden is not gone: `hide-flashcard.md` §1 keeps it
  // manageable, and §4 wants the state said rather than only shown.
  testWidgets('a hidden card still opens, marked hidden', (tester) async {
    await database.customStatement(
      "UPDATE flashcards SET is_hidden = 1 WHERE id = 'c1'",
    );

    await tester.pumpWidget(app('c1'));
    await pumpDetail(tester);

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('Hidden'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

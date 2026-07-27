import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';
import 'package:memox_v6/presentation/features/flashcard/routes/flashcard_routes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_fab.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_list_controls.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_quick_study_action.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_summary_row.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/presentation/features/deck/screens/library_screen.dart';

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
      routes: <RouteBase>[...deckRoutes(), ...flashcardRoutes()],
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

    // The kit's `flashcard-list` FAB adds a card. This screen offered the
    // create-deck one on every branch, so a Leaf deck promoted the action
    // `organise-deck.md` §2 blocks: "Leaf | Attempt tạo/move child vào | Bị
    // chặn". Only the store's exclusivity trigger stopped it, after the
    // learner had typed a name.
    expect(find.bySemanticsLabel('Add card'), findsWidgets);
    await tester.tap(find.byType(MxFab));
    await pumpDeck(tester);
    expect(find.text('New card'), findsOneWidget);

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

    // Kit `SubdeckList.jsx`: the Library's FilterRow over the same deck
    // cards the Library root renders.
    expect(find.byType(DeckListControls), findsOneWidget);
    expect(find.text('Asia'), findsOneWidget);
    expect(find.text('Add card'), findsNothing);

    await tester.tap(find.text('Asia'));
    await pumpDeck(tester);

    // Nested child opened as a Leaf; Back walks up to the parent.
    expect(find.text('1 cards'), findsOneWidget);
    await tester.tap(find.byIcon(Symbols.arrow_back).first);
    await pumpDeck(tester);
    // Back from a nested deck returns to its PARENT, not out to the
    // Library — the child row pushes rather than replacing the route.
    expect(find.byType(DeckListControls), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('the Parent branch shows its scope counters and child rows', (
    tester,
  ) async {
    // One child deck holding a due card and a never-studied card. The row
    // must carry the same counters the Library root shows for a root deck,
    // which is the point of giving the Parent branch the same deck card.
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
      'due-card',
      'asia',
      'hello',
      'hello',
      'xin chào',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p-due',
      'due-card',
      2,
      1,
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'new-card',
      'asia',
      'bye',
      'bye',
      'tạm biệt',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p-new',
      'new-card',
      0,
      null,
      0,
      0,
    );

    // The counters themselves are asserted on the read model: the card's
    // meta line is a `Text.rich`, so a widget finder cannot see it.
    final decks = DriftDeckRepository(database, const SystemClock());
    final children = await decks.watchChildSummaries('root').first;
    final asia = children.singleWhere((child) => child.deck.id == 'asia');
    expect(asia.cardCount, 2);
    expect(asia.dueCount, 1);
    expect(asia.newCount, 1);

    await tester.pumpWidget(app('root'));
    await pumpDeck(tester);

    // The child renders as a row under the filter controls; the counters
    // themselves are asserted on the read model above, because the card's
    // meta line is a `Text.rich` a widget finder cannot see.
    expect(find.byType(DeckListControls), findsOneWidget);
    expect(find.text('Asia'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a child row starts a session for that deck, not the parent', (
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
    // Five cards with distinct meanings, each with its Box-0 progress row:
    // a newLearning session needs five distinct meanings for the Guess
    // stage, and a card seeded without progress is a state the app cannot
    // produce (the create path writes both in one transaction).
    const seeded = <(String, String, String)>[
      ('c1', 'hello', 'xin chào'),
      ('c2', 'goodbye', 'tạm biệt'),
      ('c3', 'please', 'làm ơn'),
      ('c4', 'thanks', 'cảm ơn'),
      ('c5', 'sorry', 'xin lỗi'),
    ];
    for (final (id, term, meaning) in seeded) {
      await database.flashcardDao.insertFlashcard(
        id,
        'asia',
        term,
        term,
        meaning,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        0,
        0,
      );
    }

    await tester.pumpWidget(app('root'));
    await pumpDeck(tester);

    final bolt = find.descendant(
      of: find.byType(DeckSummaryRow),
      matching: find.byType(DeckQuickStudyAction),
    );
    expect(bolt, findsOneWidget);

    await tester.tap(bolt);
    await pumpDeck(tester);

    // The session that starts is scoped to the CHILD deck — opening the
    // parent first is exactly what the bolt exists to skip.
    final started = await database.studySessionDao
        .watchActiveSession()
        .getSingleOrNull();
    expect(started, isNotNull);
    expect(started!.deckId, 'asia');

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

    // Kit `subdeck-list--not-found`: a warning tile with a safe exit, and an
    // app bar stripped of its actions — there is nothing left to search or
    // configure once the deck is gone.
    expect(find.text('This deck no longer exists'), findsOneWidget);
    expect(find.text('Back to Library'), findsOneWidget);
    expect(find.bySemanticsLabel('Search'), findsNothing);
    expect(find.bySemanticsLabel('Deck options'), findsNothing);

    await disposeAndFlushStreams(tester);
  });

  // The exit was asserted to *exist* in two places and proven to *work* in
  // none. That matters more here than anywhere else on this screen:
  // `MX-VIS-039` cannot be photographed — no §6.6-compliant journey reaches a
  // deck that vanishes while open, because deleting one navigates to Library
  // by design — so no parity run will ever notice if this button stops
  // navigating. A dead end whose only way out is broken is the worst version
  // of this screen, and until now nothing would have caught it.
  testWidgets('the not-found exit actually returns to Library', (tester) async {
    await tester.pumpWidget(app('missing'));
    await pumpDeck(tester);

    await tester.tap(find.text('Back to Library'));
    await pumpDeck(tester);

    expect(find.text('This deck no longer exists'), findsNothing);
    expect(find.byType(LibraryScreen), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });
}

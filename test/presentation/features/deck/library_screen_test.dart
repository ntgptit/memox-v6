import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/usecases/flashcard/create_flashcard_usecase.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';

import '../../../support/sequential_ids.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

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

  // `MX-VIS-024` — Library error. The kit has no shot for this state (nearest
  // is `library--offline`), so under the owner decision of 2026-07-26 it is
  // asserted here rather than photographed. This is that assertion.
  testWidgets('a failed root read shows the error, not an empty library', (
    tester,
  ) async {
    final failing = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        deckRepositoryProvider.overrideWith((ref) => _FailingDecks()),
      ],
    );
    addTearDown(failing.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: failing,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: RoutePaths.library,
            routes: deckRoutes(),
          ),
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await pumpLibrary(tester);

    // The distinction that matters: a failure must not read as "you have no
    // decks", which would invite the learner to create one they already have.
    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.text('Create your first deck'), findsNothing);

    await disposeAndFlushStreams(tester);
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

  testWidgets('the filter row filters the list by status', (tester) async {
    await database.deckDao.insertDeck('a', 'lp1', null, 'Alpha', 'alpha', 0, 0);
    await database.deckDao.insertDeck('b', 'lp1', null, 'Beta', 'beta', 0, 0);
    // Beta owns a card scheduled in the past → it is the only "due" deck.
    await database.flashcardDao.insertFlashcard('c1', 'b', 't', 't', 'm', 0, 0);
    await database.learningProgressDao.insertProgress('p1', 'c1', 1, 1, 0, 0);

    await tester.pumpWidget(app());
    await pumpLibrary(tester);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    // Open the filters sheet and keep only decks with due cards.
    await tester.tap(find.text('Filters'));
    await pumpLibrary(tester);
    await tester.tap(find.text('Due'));
    await pumpLibrary(tester);

    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);

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

    // Cards arrive through the production write path, which commits a
    // Box-0 progress row with the card (initialise-card-progress.md §1).
    // The earlier version of this test inserted a card with *no* progress
    // row and called it new — a state the app cannot produce, which is
    // what let the always-zero counter defect (`int-2`) through.
    final cards = DriftFlashcardRepository(database);
    final decks = DriftDeckRepository(database, const SystemClock());
    final create = CreateFlashcardUseCase(
      cards: cards,
      decks: decks,
      idGenerator: SequentialIdGenerator(prefix: 'card'),
      clock: const SystemClock(),
    );
    Future<String> add(String term) async {
      final result =
          await create(deckId: 'd1', term: term, primaryMeaning: 'm')
              as FlashcardCreated;
      return result.card.id;
    }

    await add('a'); // stays Box 0 → new
    final due = await add('b');
    final mastered = await add('c');

    // Box 1 scheduled in the past → due; Box 8 → mastered, in no queue.
    await database.learningProgressDao.updateProgressGuarded(
      1,
      1,
      1,
      0,
      null,
      null,
      null,
      0,
      due,
      0,
    );
    await database.learningProgressDao.updateProgressGuarded(
      8,
      null,
      1,
      0,
      null,
      null,
      null,
      0,
      mastered,
      0,
    );

    final summaries = await decks.watchRootSummaries('lp1').first;
    final korean = summaries.singleWhere((s) => s.deck.id == 'd1');

    expect(korean.cardCount, 3);
    expect(korean.dueCount, 1);
    expect(korean.newCount, 1);
  });
}

/// A deck store whose root stream fails, for the `MX-VIS-024` assertion.
class _FailingDecks implements DeckRepository {
  @override
  Stream<List<DeckSummary>> watchRootSummaries(String languagePairId) =>
      Stream<List<DeckSummary>>.error(StateError('library unavailable'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

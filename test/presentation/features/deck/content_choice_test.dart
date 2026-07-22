import 'package:memox_v6/core/time/app_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_language_pair_repository.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';

import '../../../support/fake_clock.dart';
import '../../../support/sequential_ids.dart';

/// Content-choice decision table (WBS 5.2.5; `deck/README.md` §0 and
/// `organise-deck.md`): every state renders exactly its allowed action
/// set, and the store backstop blocks the forbidden transition.
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

  testWidgets('Empty offers all three choices and stays unlocked', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    expect(find.text('Add card'), findsOneWidget);
    expect(find.text('Create nested deck'), findsOneWidget);
    expect(find.text('Import cards'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('Leaf offers Add card only', (tester) async {
    await database.flashcardDao.insertFlashcard(
      'c1',
      'root',
      't',
      't',
      'm',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await pumpStreams(tester);

    expect(find.text('Add card'), findsOneWidget);
    expect(find.text('Create nested deck'), findsNothing);
    expect(find.text('Import cards'), findsNothing);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('Parent offers Create deck only', (tester) async {
    await database.deckDao.insertDeck(
      'asia',
      'lp1',
      'root',
      'Asia',
      'asia',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await pumpStreams(tester);

    expect(find.text('Create deck'), findsOneWidget);
    expect(find.text('Add card'), findsNothing);
    expect(find.text('Create nested deck'), findsNothing);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('back to Empty reopens every choice (no stale lock)', (
    tester,
  ) async {
    await database.flashcardDao.insertFlashcard(
      'c1',
      'root',
      't',
      't',
      'm',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await pumpStreams(tester);
    expect(find.text('Create nested deck'), findsNothing);

    await database.flashcardDao.softDeleteFlashcard(1, 1, 'c1');
    await pumpStreams(tester);

    expect(find.text('This deck is empty'), findsOneWidget);
    expect(find.text('Create nested deck'), findsOneWidget);
    expect(find.text('Import cards'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  test('the store backstop blocks a child under a Leaf', () async {
    await database.flashcardDao.insertFlashcard(
      'c1',
      'root',
      't',
      't',
      'm',
      0,
      0,
    );
    final createDeck = CreateDeckUseCase(
      decks: DriftDeckRepository(database, const SystemClock()),
      pairs: DriftLanguagePairRepository(database),
      idGenerator: SequentialIdGenerator(),
      clock: FakeClock(DateTime.utc(2026, 7, 19)),
    );

    await expectLater(
      createDeck(name: 'Sub', languagePairId: 'lp1', parentId: 'root'),
      throwsA(
        isA<ConflictFailure>().having(
          (failure) => failure.code,
          'code',
          'deck-mixed-content',
        ),
      ),
    );
  });
}

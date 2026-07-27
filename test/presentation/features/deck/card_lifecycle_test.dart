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

/// WBS 6.5 — the Leaf card row opens a lifecycle sheet: Hide toggles the card's
/// eligibility (and a hidden indicator), Delete removes it after a confirm
/// (hide-flashcard.md / delete-flashcard.md).
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

  Future<int> hiddenOf(String id) async {
    final row = await database
        .customSelect("SELECT is_hidden FROM flashcards WHERE id = '$id'")
        .getSingle();
    return row.read<int>('is_hidden');
  }

  Future<bool> isDeleted(String id) async {
    final row = await database
        .customSelect("SELECT deleted_at FROM flashcards WHERE id = '$id'")
        .getSingle();
    return row.read<int?>('deleted_at') != null;
  }

  Future<String> deckOf(String id) async {
    final row = await database
        .customSelect("SELECT deck_id FROM flashcards WHERE id = '$id'")
        .getSingle();
    return row.read<String>('deck_id');
  }

  testWidgets('Hide toggles the card and shows the hidden indicator', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.text('hello'));
    await pumpStreams(tester);
    expect(find.text('Card options'), findsOneWidget);

    await tester.tap(find.text('Hide'));
    await pumpStreams(tester);

    expect(await hiddenOf('c1'), 1);
    expect(find.byIcon(Symbols.visibility_off_rounded), findsOneWidget);
    expect(find.text('Card hidden'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('Delete removes the card after the confirm', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.text('hello'));
    await pumpStreams(tester);
    await tester.tap(find.text('Delete'));
    await pumpStreams(tester);

    expect(find.text('Delete this card?'), findsOneWidget);
    await tester.tap(find.text('Delete card'));
    await pumpStreams(tester);

    expect(await isDeleted('c1'), isTrue);
    expect(find.text('hello'), findsNothing);
    expect(find.text('Card deleted'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('Move relocates the card to the chosen deck', (tester) async {
    // An empty sibling deck is the only eligible target.
    await database.deckDao.insertDeck(
      'target',
      'lp1',
      null,
      'Archive',
      'archive',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.text('hello'));
    await pumpStreams(tester);
    await tester.tap(find.text('Move'));
    await pumpStreams(tester);
    expect(find.text('Move card to…'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await pumpStreams(tester);

    expect(await deckOf('c1'), 'target');
    // The card left the source Leaf list.
    expect(find.text('hello'), findsNothing);
    expect(find.text('Card moved'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  // `move-flashcard.md` §5: a duplicate in the target is resolved *before*
  // commit. The picker committed straight through, and the sheet closed on the
  // action state — which a pause settles exactly like a commit — so a paused
  // move would have announced "Card moved" over a card that never left
  // (`int-94`).
  testWidgets('a duplicate in the target pauses the move', (tester) async {
    await database.deckDao.insertDeck(
      'target',
      'lp1',
      null,
      'Archive',
      'archive',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'twin',
      'target',
      'hello',
      'hello',
      'xin chào',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.text('hello').first);
    await pumpStreams(tester);
    await tester.tap(find.text('Move'));
    await pumpStreams(tester);
    await tester.tap(find.text('Archive'));
    await pumpStreams(tester);

    expect(find.text('"hello" is already in that deck.'), findsOneWidget);
    expect(find.text('Card moved'), findsNothing);
    expect(await deckOf('c1'), 'root');

    // The keep-both override is the only way past it.
    await tester.tap(find.text('Move anyway'));
    await pumpStreams(tester);

    expect(await deckOf('c1'), 'target');
    expect(find.text('Card moved'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  // The picker lists every deck in the pair now, blocked ones included, so
  // "nowhere to move this" stopped being an empty list and this guidance went
  // unreachable — a learner with one deck saw a lone disabled row and nothing
  // telling them why (`int-94`).
  testWidgets('a card with no eligible target is told so', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.text('hello'));
    await pumpStreams(tester);
    await tester.tap(find.text('Move'));
    await pumpStreams(tester);

    expect(find.text('Already here'), findsOneWidget);
    expect(
      find.text(
        'No other deck can hold this card yet. Create an empty deck first.',
      ),
      findsOneWidget,
    );

    await disposeAndFlushStreams(tester);
  });

  // `int-35`: nothing watches the lifecycle notifier, so before the bar a
  // failed hide or delete reached nobody — the row just stayed as it was.
  // The card vanishing under an open sheet is how that happens for real
  // (`hide-flashcard.md` §9: another surface deleted it).
  testWidgets('a hide that cannot land says so and changes nothing', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.text('hello'));
    await pumpStreams(tester);
    await database.customStatement("DELETE FROM flashcards WHERE id = 'c1'");

    await tester.tap(find.text('Hide'));
    await pumpStreams(tester);

    expect(find.text('Couldn’t update this card. Try again.'), findsOneWidget);
    expect(find.text('Card hidden'), findsNothing);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('Keep card cancels the delete', (tester) async {
    await tester.pumpWidget(app());
    await pumpStreams(tester);

    await tester.tap(find.text('hello'));
    await pumpStreams(tester);
    await tester.tap(find.text('Delete'));
    await pumpStreams(tester);
    await tester.tap(find.text('Keep card'));
    await pumpStreams(tester);

    expect(await isDeleted('c1'), isFalse);
    expect(find.text('hello'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });
}

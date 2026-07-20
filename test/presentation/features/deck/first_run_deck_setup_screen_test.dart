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
import 'package:memox_v6/presentation/features/language_pair/routes/language_pair_routes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_select_row.dart';

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

  Widget app() {
    final router = GoRouter(
      initialLocation: RoutePaths.firstRunDeckSetup,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('home-stub')),
        ),
        ...languagePairRoutes(),
        ...deckRoutes(),
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

  Future<void> disposeAndFlushStreams(WidgetTester tester) async {
    // Dispose the tree first so drift's stream-retention timer gets
    // scheduled, then advance time so it fires before the binding's
    // pending-timer check.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpLibrary(WidgetTester tester) async {
    // The Library renders a stream-fed list; bounded pumps let the first
    // emission land without racing the loading spinner's animation.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Let any just-scheduled stream fetch timer fire before teardown.
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('renders the pair summary and gates create on the name', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('English → Vietnamese'), findsOneWidget);

    MxButton createButton() =>
        tester.widget<MxButton>(find.widgetWithText(MxButton, 'Create deck'));
    expect(createButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Korean TOPIK I');
    await tester.pumpAndSettle();
    expect(createButton().onPressed, isNotNull);
  });

  testWidgets('the draft survives Change to step 1 and back', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Korean TOPIK I');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('What are you learning? *'), findsOneWidget);

    // Re-confirm the selections on step 1 (fresh draft in this test),
    // then continue back to step 2.
    await tester.tap(find.byType(MxSelectRow).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English · English').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxSelectRow).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Việt · Vietnamese').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Korean TOPIK I'), findsOneWidget);
  });

  testWidgets('creating persists name and description then lands home', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, ' Korean TOPIK I ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Vocabulary for TOPIK I',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create deck'));
    await pumpLibrary(tester);

    // Success lands in the Library with the first-deck callout.
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Your first deck is ready'), findsOneWidget);

    await disposeAndFlushStreams(tester);

    final row = await database
        .customSelect('SELECT name, description FROM decks')
        .getSingle();
    expect(row.read<String>('name'), 'Korean TOPIK I');
    expect(row.read<String>('description'), 'Vocabulary for TOPIK I');
  });

  testWidgets('a duplicate root deck shows the Library-scoped inline error', (
    tester,
  ) async {
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, ' KOREAN ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create deck'));
    await tester.pumpAndSettle();

    // First-run always creates a root deck, so the clash is with the
    // Library, never with a sibling (`create-deck.md` §19).
    expect(
      find.text('A deck with this name already exists in your Library.'),
      findsOneWidget,
    );
    expect(find.text('Library'), findsNothing);
  });
}

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

  Widget app(String initialLocation) {
    final router = GoRouter(
      initialLocation: initialLocation,
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

  testWidgets('creates a root deck from the Library dialog', (tester) async {
    await tester.pumpWidget(app(RoutePaths.library));
    await pumpStreams(tester);

    await tester.tap(find.text('Create deck'));
    await pumpStreams(tester);
    expect(find.text('Inside Library'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Korean');
    await pumpStreams(tester);
    await tester.tap(find.text('Create deck').last);
    await pumpStreams(tester);

    // Dialog closed; the reactive list shows the new root.
    expect(find.text('Inside Library'), findsNothing);
    expect(find.text('Korean'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('nested create from a parent deck inherits its pair', (
    tester,
  ) async {
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Travel',
      'travel',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'asia',
      'lp1',
      'root',
      'Asia',
      'asia',
      0,
      0,
    );

    await tester.pumpWidget(app(RoutePaths.deckDetail('root')));
    await pumpStreams(tester);

    await tester.tap(find.text('Create deck'));
    await pumpStreams(tester);
    expect(find.text('Inside Travel'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Europe');
    await pumpStreams(tester);
    await tester.tap(find.text('Create deck').last);
    await pumpStreams(tester);

    expect(find.text('Europe'), findsOneWidget);
    final row = await database
        .customSelect(
          "SELECT language_pair_id, parent_id FROM decks "
          "WHERE normalized_name = 'europe'",
        )
        .getSingle();
    expect(row.read<String>('language_pair_id'), 'lp1');
    expect(row.read<String>('parent_id'), 'root');

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a duplicate sibling shows the inline error and keeps input', (
    tester,
  ) async {
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );

    await tester.pumpWidget(app(RoutePaths.library));
    await pumpStreams(tester);

    await tester.tap(find.text('Create deck'));
    await pumpStreams(tester);
    await tester.enterText(find.byType(TextField), ' KOREAN ');
    await pumpStreams(tester);
    await tester.tap(find.text('Create deck').last);
    await pumpStreams(tester);

    expect(
      find.text('A deck with this name already exists here.'),
      findsOneWidget,
    );
    expect(find.text(' KOREAN '), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await pumpStreams(tester);
    expect(find.text('Inside Library'), findsNothing);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('long deck names ellipsize without breaking rows', (
    tester,
  ) async {
    final longName = 'A very long localized deck name ' * 4;
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      longName,
      longName.toLowerCase(),
      0,
      0,
    );

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 780);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(RoutePaths.deckDetail('root')));
    await pumpStreams(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('A very long'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('deep nesting browses five levels down', (tester) async {
    String parent = '';
    for (var level = 0; level < 5; level++) {
      final id = 'deck-$level';
      await database.deckDao.insertDeck(
        id,
        'lp1',
        level == 0 ? null : parent,
        'Level $level',
        'level $level',
        0,
        0,
      );
      parent = id;
    }

    await tester.pumpWidget(app(RoutePaths.deckDetail('deck-0')));
    await pumpStreams(tester);

    for (var level = 1; level < 5; level++) {
      await tester.tap(find.text('Level $level'));
      await pumpStreams(tester);
    }

    expect(find.text('This deck is empty'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });
}

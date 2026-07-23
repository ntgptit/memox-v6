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
import 'package:memox_v6/presentation/shared/widgets/mx_breadcrumb.dart';

/// WBS 6.2 — the nested-deck breadcrumb shows the ancestor path and jumps up.
/// A root deck shows no breadcrumb; a nested deck shows `Library › Root › …`
/// and tapping an ancestor navigates to it.
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
    // Root › Grammar › Verbs — three levels so the crumb trail is non-trivial.
    await database.deckDao.insertDeck(
      'root',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'grammar',
      'lp1',
      'root',
      'Grammar',
      'grammar',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'verbs',
      'lp1',
      'grammar',
      'Verbs',
      'verbs',
      0,
      0,
    );
    // A card keeps the leaf non-empty (breadcrumb renders on the leaf branch).
    await database.flashcardDao.insertFlashcard(
      'c1',
      'verbs',
      't1',
      't1',
      'm1',
      0,
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

  testWidgets('a root deck shows no breadcrumb', (tester) async {
    await tester.pumpWidget(app(RoutePaths.deckDetail('root')));
    await pumpStreams(tester);

    expect(find.byType(MxBreadcrumb), findsNothing);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a nested deck shows the ancestor trail', (tester) async {
    await tester.pumpWidget(app(RoutePaths.deckDetail('verbs')));
    await pumpStreams(tester);

    expect(find.byType(MxBreadcrumb), findsOneWidget);
    // Library › Korean › Grammar › Verbs — every level is present.
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);
    expect(find.text('Grammar'), findsOneWidget);
    // The current deck name appears in both the app bar and the crumb.
    expect(find.text('Verbs'), findsWidgets);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('tapping an ancestor crumb navigates to it', (tester) async {
    await tester.pumpWidget(app(RoutePaths.deckDetail('verbs')));
    await pumpStreams(tester);

    await tester.tap(find.text('Grammar'));
    await pumpStreams(tester);

    // Grammar has one child (Verbs) and no direct cards: the Parent branch
    // renders its create-deck action, and the breadcrumb loses the Verbs crumb.
    expect(find.byType(MxBreadcrumb), findsOneWidget);
    expect(find.text('Verbs'), findsOneWidget); // now only the child row
    expect(find.text('Grammar'), findsWidgets); // app-bar title + crumb

    await disposeAndFlushStreams(tester);
  });
}

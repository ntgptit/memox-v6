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
import 'package:memox_v6/presentation/features/study/routes/study_routes.dart';
import 'package:memox_v6/presentation/features/today/routes/today_routes.dart';

/// WBS 5.7.3 — the Today → study → Today handoff, driven the way a learner
/// drives it.
///
/// The domain seam for this exists (`study_to_dashboard_seam_test`), and so
/// does the study loop's own end-to-end (`int-45`). What neither covers is the
/// join: Today's own read deciding what to offer, the route it hands off to,
/// and the same read afterwards deciding it is done. Every defect this session
/// found on this path — the due count that counted decks, the projection that
/// discarded a streak, the session that could not finish — was invisible from
/// one side of a boundary.
///
/// Real database, real providers, real routes.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;
  late GoRouter router;

  final dueAt = DateTime.utc(2026, 7, 26, 9);

  setUp(() async {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    router = GoRouter(
      initialLocation: RoutePaths.home,
      routes: <RouteBase>[...todayBranchRoutes(), ...studyRoutes()],
    );
    addTearDown(router.dispose);

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
      'd1',
      'lp1',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
    for (final (id, term, meaning) in const <(String, String, String)>[
      ('c1', '학교', 'school'),
      ('c2', '친구', 'friend'),
    ]) {
      await database.flashcardDao.insertFlashcard(
        id,
        'd1',
        term,
        term,
        meaning,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        3,
        dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  });

  /// Lets the real work finish, then paints what came of it.
  ///
  /// Two reasons this is not `pumpAndSettle`. Today's loading state shimmers,
  /// and a repeating animation never settles; and the commands here go to a
  /// real database, whose I/O does not advance inside the test's fake-async
  /// zone — `runAsync` is what gives it real time to complete.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Widget app() => UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );

  testWidgets('Today starts the review, and reads as done after it', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await settle(tester);

    // Two cards are due, and Today offers the review.
    expect(find.text('Start review'), findsOneWidget);

    await tester.tap(find.text('Start review'));
    await settle(tester);

    // The handoff landed on the stage the due plan runs.
    expect(find.text('Remembered'), findsOneWidget);

    await tester.tap(find.text('Remembered'));
    await settle(tester);
    await tester.tap(find.text('Remembered'));
    await settle(tester);
    expect(find.text('Session complete'), findsOneWidget);

    // Out the way the result offers, which is also the refresh trigger
    // `refresh-today-projections.md` §3 names for a finished session.
    await tester.tap(find.text('Keep studying'));
    await settle(tester);

    // The same read that offered the review has to agree there is nothing
    // left: the cards left the due queue when the session scheduled them.
    expect(find.text('Start review'), findsNothing);
    expect(find.text('You’re all caught up'), findsOneWidget);
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_deck_setup_screen.dart';
import 'package:memox_v6/presentation/features/deck/screens/first_run_landing_screen.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

import '../../../support/golden_test_harness.dart';

/// First-run setup evidence (WBS 5.2.3C): landing→deck E2E over the
/// real router, vi locale renders and light/dark + adaptive goldens.
void main() {
  late db.AppDatabase database;

  setUpAll(loadAppFonts);

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Widget screenApp(Widget home, {Locale? locale, Brightness? brightness}) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
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

  group('E2E: landing through deck creation on the real router', () {
    testWidgets('the full first-run journey opens the new deck with data', (
      tester,
    ) async {
      final router = createAppRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      router.go(RoutePaths.firstRunLanding);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create your first deck'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MxTappable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('English · English').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MxTappable).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếng Việt · Vietnamese').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Korean TOPIK I');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create deck'));
      await pumpLibrary(tester);

      // Success opens the just-created deck directly: its name titles the
      // detail and its empty state offers the next step (create-deck.md §7).
      expect(find.text('Korean TOPIK I'), findsWidgets);
      expect(find.text('This deck is empty'), findsOneWidget);
      expect(find.text('Your first deck is ready'), findsNothing);

      await disposeAndFlushStreams(tester);
      final counts = await database
          .customSelect(
            'SELECT (SELECT COUNT(*) FROM language_pairs) AS pairs, '
            '(SELECT COUNT(*) FROM decks) AS decks',
          )
          .getSingle();
      expect(counts.read<int>('pairs'), 1);
      expect(counts.read<int>('decks'), 1);
    });
  });

  group('vi locale evidence', () {
    testWidgets('the landing renders Vietnamese copy', (tester) async {
      await tester.pumpWidget(
        screenApp(const FirstRunLandingScreen(), locale: const Locale('vi')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xây dựng thư viện học của bạn'), findsOneWidget);
      expect(find.text('Tạo deck đầu tiên'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
    });

    testWidgets('step 2 renders Vietnamese copy', (tester) async {
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

      await tester.pumpWidget(
        screenApp(const FirstRunDeckSetupScreen(), locale: const Locale('vi')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bước 2/2'), findsOneWidget);
      expect(find.textContaining('Tên deck'), findsOneWidget);
      expect(find.text('Tạo deck'), findsOneWidget);
    });
  });

  group('light/dark and adaptive goldens', () {
    const surfaces = <String, Size>{
      'mobile-390': Size(390, 780),
      'expanded-1024': Size(1024, 800),
    };

    for (final brightness in Brightness.values) {
      for (final entry in surfaces.entries) {
        testWidgets('landing ${entry.key} ${brightness.name}', (tester) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = entry.value;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            screenApp(const FirstRunLandingScreen(), brightness: brightness),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/landing_${entry.key}_${brightness.name}.png',
            ),
          );
        });

        testWidgets('deck setup ${entry.key} ${brightness.name}', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = entry.value;
          addTearDown(tester.view.reset);

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

          await tester.pumpWidget(
            screenApp(const FirstRunDeckSetupScreen(), brightness: brightness),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/deck_setup_${entry.key}_${brightness.name}.png',
            ),
          );
        });
      }
    }
  });
}

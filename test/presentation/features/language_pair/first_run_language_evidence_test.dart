import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/domain/language_pair/create_language_pair_result.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/language_pair/screens/first_run_language_screen.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

import '../../../support/golden_test_harness.dart';
import '../../../support/test_container.dart';

/// Language Pair evidence suite (WBS 5.1.3): provider graph, full-router
/// E2E, vi locale and light/dark + adaptive goldens.
void main() {
  late db.AppDatabase database;

  setUpAll(loadAppFonts);

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('provider evidence', () {
    test('use-case providers resolve over the DI graph', () async {
      final container = createTestContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );

      final create = container.read(createLanguagePairUseCaseProvider);
      final select = container.read(selectLanguagePairUseCaseProvider);

      final result = await create(
        learningLanguageCode: 'en',
        nativeLanguageCode: 'vi',
      );
      await select(result.pair.id);

      expect(result, isA<LanguagePairCreated>());
      expect((await select.activePair())?.normalizedPairKey, 'en|vi');
    });
  });

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

  group('E2E over the real app router', () {
    testWidgets('first run completes through to the Library', (tester) async {
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
      router.go(RoutePaths.firstRunLanguage);
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

      // Step 2: name the first deck and create it.
      expect(find.text('Step 2 of 2'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Korean TOPIK I');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create deck'));
      await pumpLibrary(tester);

      // Landed on the Library deck list, with the pair and deck persisted.
      expect(find.text('Library'), findsWidgets);

      await disposeAndFlushStreams(tester);
      final deck = await database
          .customSelect('SELECT COUNT(*) AS n FROM decks')
          .getSingle();
      expect(deck.read<int>('n'), 1);
      final stored = await database.languagePairDao
          .findLanguagePairByKey('en|vi')
          .getSingleOrNull();
      expect(stored, isNotNull);
    });
  });

  group('vi locale evidence', () {
    testWidgets('the screen renders Vietnamese copy end to end', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const FirstRunLanguageScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thiết lập việc học của bạn'), findsOneWidget);
      expect(find.text('Bạn đang học gì? *'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });
  });

  group('light/dark and adaptive goldens', () {
    const surfaces = <String, Size>{
      'mobile-390': Size(390, 780),
      'expanded-1024': Size(1024, 800),
    };

    for (final brightness in Brightness.values) {
      for (final entry in surfaces.entries) {
        testWidgets('first-run ${entry.key} ${brightness.name}', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = entry.value;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [appDatabaseProvider.overrideWithValue(database)],
              child: MaterialApp(
                theme: brightness == Brightness.light
                    ? AppTheme.light()
                    : AppTheme.dark(),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const FirstRunLanguageScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/first_run_${entry.key}_${brightness.name}.png',
            ),
          );
        });
      }
    }
  });
}

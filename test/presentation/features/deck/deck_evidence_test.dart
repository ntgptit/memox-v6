import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:memox_v6/core/random/deterministic_random.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/domain/deck/deck_name.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/routes/deck_routes.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/library_viewmodel.dart';

import '../../../support/test_container.dart';

/// Deck block evidence (WBS 5.2.6): provider graph, a property-style
/// normalization sweep, vi locale renders and light/dark goldens.
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

  group('provider evidence over the DI graph', () {
    test('library and deck providers resolve end to end', () async {
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
      await database.flashcardDao.insertFlashcard(
        'c1',
        'asia',
        't',
        't',
        'm',
        0,
        0,
      );

      final container = createTestContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );

      // Hold subscriptions so autoDispose providers survive the awaits.
      container.listen(libraryRootDecksProvider, (_, _) {});
      container.listen(deckChildrenProvider(deckId: 'root'), (_, _) {});
      container.listen(deckSubtreeCardsProvider(deckId: 'root'), (_, _) {});

      final roots = await container.read(libraryRootDecksProvider.future);
      expect(roots.single.name, 'Travel');

      final children = await container.read(
        deckChildrenProvider(deckId: 'root').future,
      );
      expect(children.single.name, 'Asia');

      final subtree = await container.read(
        deckSubtreeCardsProvider(deckId: 'root').future,
      );
      expect(subtree, 1);
    });
  });

  group('property evidence: name normalization', () {
    test('normalization is idempotent and case/trim-insensitive across a '
        'seeded sweep', () {
      final random = DeterministicRandom(42);
      const alphabet = 'aAbBcC đĐ xyZ';
      for (var i = 0; i < 200; i++) {
        final length = 1 + random.nextInt(24);
        final buffer = StringBuffer();
        for (var j = 0; j < length; j++) {
          buffer.write(alphabet[random.nextInt(alphabet.length)]);
        }
        final raw = ' ${buffer.toString()} ';
        final normalized = normalizeDeckName(raw);

        expect(normalizeDeckName(normalized), normalized, reason: raw);
        expect(
          normalizeDeckName(raw.toUpperCase()),
          normalizeDeckName(raw.toLowerCase()),
          reason: raw,
        );
        expect(normalized, normalized.trim(), reason: raw);
      }
    });
  });

  group('vi locale evidence', () {
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
          locale: const Locale('vi'),
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

    testWidgets('Library renders Vietnamese copy', (tester) async {
      await tester.pumpWidget(app(RoutePaths.library));
      await pumpStreams(tester);

      expect(find.text('Thư viện'), findsWidgets);
      expect(
        find.text('Tạo một deck hoặc import thẻ để bắt đầu.'),
        findsOneWidget,
      );
      expect(find.text('Tạo deck'), findsOneWidget);

      await disposeAndFlushStreams(tester);
    });

    testWidgets('the empty deck renders Vietnamese copy', (tester) async {
      await database.deckDao.insertDeck(
        'root',
        'lp1',
        null,
        'Travel',
        'travel',
        0,
        0,
      );

      await tester.pumpWidget(app(RoutePaths.deckDetail('root')));
      await pumpStreams(tester);

      expect(find.text('Deck này đang trống'), findsOneWidget);
      expect(find.text('Thêm thẻ'), findsOneWidget);
      expect(find.text('Tạo deck con'), findsOneWidget);
      expect(find.text('Nhập thẻ'), findsOneWidget);

      await disposeAndFlushStreams(tester);
    });
  });

  group('light/dark goldens', () {
    Widget app(String initialLocation, Brightness brightness) {
      final router = GoRouter(
        initialLocation: initialLocation,
        routes: deckRoutes(),
      );
      return ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
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

    Future<void> seedLibrary() async {
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
        'work',
        'lp1',
        null,
        'Work',
        'work',
        0,
        0,
      );
    }

    for (final brightness in Brightness.values) {
      testWidgets('library 390 ${brightness.name}', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(390, 780);
        addTearDown(tester.view.reset);
        await seedLibrary();

        await tester.pumpWidget(app(RoutePaths.library, brightness));
        await pumpStreams(tester);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/library_390_${brightness.name}.png'),
        );

        await disposeAndFlushStreams(tester);
      });

      testWidgets('deck parent 390 ${brightness.name}', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(390, 780);
        addTearDown(tester.view.reset);
        await seedLibrary();
        await database.deckDao.insertDeck(
          'asia',
          'lp1',
          'root',
          'Asia',
          'asia',
          0,
          0,
        );

        await tester.pumpWidget(app(RoutePaths.deckDetail('root'), brightness));
        await pumpStreams(tester);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/deck_parent_390_${brightness.name}.png'),
        );

        await disposeAndFlushStreams(tester);
      });
    }
  });
}

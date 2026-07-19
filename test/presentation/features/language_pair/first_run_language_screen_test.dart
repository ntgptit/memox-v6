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
import 'package:memox_v6/presentation/features/language_pair/routes/language_pair_routes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: RoutePaths.firstRunLanguage,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('home-stub')),
        ),
        GoRoute(
          path: RoutePaths.firstRunDeckSetup,
          builder: (context, state) =>
              const Scaffold(body: Text('deck-step-stub')),
        ),
        ...languagePairRoutes(),
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

  Future<void> pickLanguage(
    WidgetTester tester, {
    required int fieldIndex,
    required String rowText,
  }) async {
    await tester.tap(find.byType(MxTappable).at(fieldIndex));
    await tester.pumpAndSettle();
    await tester.tap(find.text(rowText).last);
    await tester.pumpAndSettle();
  }

  testWidgets('continue stays disabled until both selectors are set', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    MxButton continueButton() => tester.widget<MxButton>(find.byType(MxButton));
    expect(continueButton().onPressed, isNull);

    await pickLanguage(tester, fieldIndex: 0, rowText: 'English · English');
    expect(continueButton().onPressed, isNull);

    await pickLanguage(
      tester,
      fieldIndex: 1,
      rowText: 'Tiếng Việt · Vietnamese',
    );
    expect(continueButton().onPressed, isNotNull);
  });

  testWidgets('the sheet search filters languages', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MxTappable).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'viet');
    await tester.pumpAndSettle();

    expect(find.text('Tiếng Việt · Vietnamese'), findsOneWidget);
    expect(find.text('English · English'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No languages match your search.'), findsOneWidget);
  });

  testWidgets('saving persists the pair and selection then opens step 2', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await pickLanguage(tester, fieldIndex: 0, rowText: 'English · English');
    await pickLanguage(
      tester,
      fieldIndex: 1,
      rowText: 'Tiếng Việt · Vietnamese',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('deck-step-stub'), findsOneWidget);

    final pair = await database.languagePairDao
        .findLanguagePairByKey('en|vi')
        .getSingle();
    final selection = await database.preferenceDao
        .findPreference('activeLanguagePairId')
        .getSingle();
    expect(selection.valueJson, '"${pair.id}"');
  });

  testWidgets('an existing pair is adopted, never duplicated', (tester) async {
    await database.languagePairDao.insertLanguagePair(
      'existing',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await pickLanguage(tester, fieldIndex: 0, rowText: 'English · English');
    await pickLanguage(
      tester,
      fieldIndex: 1,
      rowText: 'Tiếng Việt · Vietnamese',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final count = await database
        .customSelect('SELECT COUNT(*) AS n FROM language_pairs')
        .getSingle();
    expect(count.read<int>('n'), 1);

    final selection = await database.preferenceDao
        .findPreference('activeLanguagePairId')
        .getSingle();
    expect(selection.valueJson, '"existing"');
  });

  testWidgets('a save failure shows the banner and keeps the draft', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await pickLanguage(tester, fieldIndex: 0, rowText: 'English · English');
    await pickLanguage(
      tester,
      fieldIndex: 1,
      rowText: 'Tiếng Việt · Vietnamese',
    );

    // Break the store so the save fails with a catchable storage error.
    await database.customStatement('DROP TABLE language_pairs');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(MxBanner), findsOneWidget);
    expect(find.text('Could not save'), findsOneWidget);
    expect(find.text('English · English'), findsOneWidget);
    expect(find.text('Tiếng Việt · Vietnamese'), findsOneWidget);
    expect(find.text('deck-step-stub'), findsNothing);
  });
}

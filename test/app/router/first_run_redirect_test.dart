import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/app.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Widget app() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        // Home is the async Today entry (WBS 5.7.2); pin a resolved projection
        // so it settles deterministically instead of leaving a live drift
        // stream that never quiesces under bounded pumps.
        todayProjectionProvider.overrideWith(
          (ref) async => const TodayProjection(
            primaryAction: TodayPrimaryAction.caughtUp,
            dueCount: 0,
          ),
        ),
      ],
      child: const MemoxApp(),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> disposeAndFlushStreams(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a fresh install lands on the first-run landing', (tester) async {
    await tester.pumpWidget(app());
    await pumpApp(tester);

    expect(find.text('Build your learning library'), findsOneWidget);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('a dismissed landing keeps the home entry', (tester) async {
    await database.preferenceDao.upsertPreference(
      'firstRunLandingDismissed',
      'true',
      1,
      0,
    );

    await tester.pumpWidget(app());
    await pumpApp(tester);

    // Home is the Today entry (WBS 5.7.2); its title also labels the nav tab.
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Library'), findsWidgets);

    await disposeAndFlushStreams(tester);
  });

  testWidgets('an existing pair skips first-run and reaches the Library', (
    tester,
  ) async {
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

    await tester.pumpWidget(app());
    await pumpApp(tester);

    // Home is the Today entry (WBS 5.7.2); its title also labels the nav tab.
    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.text('Library').last);
    await pumpApp(tester);

    expect(
      find.text('Create a deck or import cards to get started.'),
      findsOneWidget,
    );

    await disposeAndFlushStreams(tester);
  });
}

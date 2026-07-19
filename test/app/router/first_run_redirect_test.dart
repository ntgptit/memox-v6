import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/app.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;

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
      overrides: [appDatabaseProvider.overrideWithValue(database)],
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

    expect(find.text('MemoX Home'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);

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

    expect(find.text('MemoX Home'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await pumpApp(tester);

    expect(
      find.text('Create a deck to start building your library.'),
      findsOneWidget,
    );

    await disposeAndFlushStreams(tester);
  });
}

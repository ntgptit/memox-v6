import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/settings/widgets/daily_goal_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_switch.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_chip.dart';

/// WBS study-goal — `set-daily-study-goal.md`, through the sheet.
///
/// The chain this closes was inert end to end: nothing could create a goal, so
/// `latestGoal()` was always null and the tracking built for it never
/// activated. These tests go through the real database, so a save that does
/// not reach storage fails here rather than silently leaving the goal unset.
void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  // One test closes the database mid-flight to make a save fail; closing an
  // already-closed database is a no-op, so this stays unconditional.
  tearDown(() => database.close());

  Widget host() => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDailyGoalSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('saving creates the configuration', (tester) async {
    await open(tester);

    await tester.tap(find.text('30 cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final goals = await database.studyGoalDao
        .findLatestGoal()
        .getSingleOrNull();
    expect(goals, isNotNull);
    expect(goals!.targetCardCount, 30);
    expect(goals.isEnabled, 1);
    expect(find.text('Daily goal updated'), findsOneWidget);
  });

  // §6: "Failure giữ draft". The sheet popped on whatever came back, so a
  // goal that never reached storage closed the form and read as saved — the
  // learner would have gone looking for it on the dashboard.
  testWidgets('a save that cannot land keeps the sheet and the draft', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('30 cards'));
    await tester.pumpAndSettle();
    // The store goes away under the open sheet — the write fails, and the
    // form is left holding a draft it must not lose.
    await database.close();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Couldn’t update your daily goal. Your changes are still here.',
      ),
      findsOneWidget,
    );
    expect(find.text('Save'), findsOneWidget, reason: 'the sheet stayed open');
    final chip = tester.widget<MxChip>(
      find.ancestor(of: find.text('30 cards'), matching: find.byType(MxChip)),
    );
    expect(chip.selected, isTrue, reason: 'the draft target is still chosen');
    expect(find.text('Daily goal updated'), findsNothing);
  });

  testWidgets('a saved goal prefills the form', (tester) async {
    await open(tester);
    await tester.tap(find.text('50 cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final chip = tester.widget<MxChip>(
      find.ancestor(of: find.text('50 cards'), matching: find.byType(MxChip)),
    );
    expect(chip.selected, isTrue, reason: 'the stored target comes back');
  });

  // §5: the target stays visible while disabled, so the learner can see what
  // re-enabling would restore — it is inert, not hidden.
  testWidgets('disabling leaves the target visible but inert', (tester) async {
    await open(tester);

    await tester.tap(find.byType(MxSwitch));
    await tester.pumpAndSettle();

    final chip = tester.widget<MxChip>(
      find.ancestor(of: find.text('50 cards'), matching: find.byType(MxChip)),
    );
    expect(find.text('50 cards'), findsOneWidget);
    expect(chip.onTap, isNull);
  });

  testWidgets('a second save updates rather than stacking', (tester) async {
    await open(tester);
    await tester.tap(find.text('10 cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20 cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final rows = await database.studyGoalDao.findLatestGoal().get();
    expect(rows, hasLength(1), reason: 'one effective configuration');
    expect(rows.single.targetCardCount, 20);
  });
}

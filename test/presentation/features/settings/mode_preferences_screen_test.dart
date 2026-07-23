import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/router/route_placeholder.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/usecases/preferences/set_mode_preferences_usecase.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// WBS 8.3 — the mode-preferences sheet enables/defaults the Practice modes and
/// blocks Save when the configuration is invalid (configure-mode-preferences.md).
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
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfilePlaceholderScreen(),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study modes'));
    await tester.pumpAndSettle();
  }

  Future<List<StudyModeType>> savedEnabled() async {
    final prefs = await SetModePreferencesUseCase(
      preferences: DriftPreferenceRepository(database),
      clock: const SystemClock(),
    ).current();
    return prefs.enabledInOrder;
  }

  // The first tappable in a mode row is its enable checkbox.
  Finder enableToggle(String modeId) => find
      .descendant(
        of: find.byKey(ValueKey('mode-$modeId')),
        matching: find.byType(MxTappable),
      )
      .first;

  MxButton saveButton(WidgetTester tester) =>
      tester.widget<MxButton>(find.byType(MxButton));

  testWidgets('lists the five selectable modes with Review the default', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Match'), findsOneWidget);
    expect(find.text('Guess'), findsOneWidget);
    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
    // The unset default config marks Review as default.
    expect(find.text('Default'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disabling a mode and saving persists the smaller set', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(enableToggle('fill'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(await savedEnabled(), [
      StudyModeType.review,
      StudyModeType.match,
      StudyModeType.guess,
      StudyModeType.recall,
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disabling every mode blocks Save', (tester) async {
    await openSheet(tester);

    for (final id in ['review', 'match', 'guess', 'recall', 'fill']) {
      await tester.tap(enableToggle(id));
      await tester.pump();
    }

    expect(saveButton(tester).onPressed, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('moving a mode down saves the new order', (tester) async {
    await openSheet(tester);

    // Review starts first; move it down one place.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('mode-review')),
        matching: find.bySemanticsLabel('Move down'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(await savedEnabled(), [
      StudyModeType.match,
      StudyModeType.review,
      StudyModeType.guess,
      StudyModeType.recall,
      StudyModeType.fill,
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

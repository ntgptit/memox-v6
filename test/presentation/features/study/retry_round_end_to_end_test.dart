import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/study_session_screen.dart';

/// WBS 5.6 — a graded mode carried through a real mastery retry round.
///
/// `finish_session_end_to_end_test` already drives a session that fails a card
/// and re-opens it, but it drives the binary review mode, which holds no
/// per-attempt state of its own. `int-78` lived in the state the *graded*
/// modes hold: Fill, Guess and Recall each keep their pre-commit UI state in a
/// provider, and those providers were keyed by card alone. A retry round
/// re-opens the same card, so the widget element survives the boundary, the
/// provider is never released, and the retry began already graded — input
/// locked, answer revealed, Continue showing. Every per-mode test passed,
/// because each mounts one fixed runtime and never crosses a round.
///
/// This is the layer that would have caught it: one stage, one real store, and
/// the round boundary driven the way a learner drives it.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2200);
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

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
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
    // One card, so the retry round it fails into holds exactly that card —
    // the case where the stage re-opens on the same element it just left.
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd1',
      'apple',
      'apple',
      'fruit',
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p-c1',
      'c1',
      0,
      null,
      0,
      0,
    );
  });

  Widget app() => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StudySessionScreen(),
    ),
  );

  /// A new-learning session parked at its Fill stage, the last of the five.
  ///
  /// Seeded rather than started, because the only route the app has to a Fill
  /// stage is four stages of answering first — and `Practice`, whose plan is a
  /// single chosen mode, cannot be started at all (`int-79`). Everything that
  /// matters here is still real: the answer command, the advance policy, the
  /// store and the re-read that follows each answer. Only the starting
  /// position is placed.
  Future<void> seedFillStage() async {
    const fillStageIndex = 4;
    await database.studySessionDao.insertSession(
      's1',
      'newLearning',
      'd1',
      'subtree',
      'active',
      1,
      0,
      0,
      0,
    );
    await database.sessionSnapshotDao.insertSessionCard(
      'sc1',
      's1',
      'c1',
      0,
      'apple',
      'fruit',
      1,
      0,
      0,
      0,
    );
    await database.sessionSnapshotDao.insertRoundOrder(
      'ro1',
      's1',
      1,
      1,
      '["c1"]',
      0,
    );
    await database.sessionCheckpointDao.upsertCheckpoint(
      'cp1',
      's1',
      fillStageIndex,
      1,
      0,
      '[]',
      '{}',
      1,
      0,
    );
  }

  testWidgets('a failed card can be answered again in its retry round', (
    tester,
  ) async {
    await seedFillStage();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('fruit'), findsOneWidget, reason: 'the Fill prompt');

    // Round 1: get it wrong.
    await tester.enterText(find.byType(TextField), 'pear');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // The round closed with one failed card and re-opened on it. This is the
    // boundary `int-78` could not cross: the attempt has to start clean.
    expect(
      find.text('Check'),
      findsOneWidget,
      reason: 'the retry round opens a fresh attempt, not the last grade',
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isTrue);
    expect(field.controller?.text ?? '', isEmpty);

    // Round 2: get it right, and the stage can finally finish.
    await tester.enterText(find.byType(TextField), 'apple');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
  });

  // The evidence half of the same defect: a hint belongs to the attempt that
  // asked for it (`fill-card-answer.md` §4), so a retry must not inherit one —
  // it would record `hintUsed` on an attempt that never asked for help.
  testWidgets('a hint does not follow the card into its retry round', (
    tester,
  ) async {
    await seedFillStage();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    expect(find.textContaining('starts with'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pear');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('starts with'), findsNothing);
    expect(find.text('Help'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/fill_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.9 — Fill compares the typed term against the accepted answer under
/// SM-FILL-v1 and reveals correct/wrong feedback (`fill-card-answer.md`).
void main() {
  final now = DateTime.utc(2026, 7, 23, 19);

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2200);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  StudyRuntimeState runtime() => StudyRuntimeState.assemble(
    session: StudySession(
      id: 's1',
      type: SessionType.newLearning,
      deckId: 'd1',
      scope: SessionScope.subtree,
      state: SessionState.active,
      revision: 0,
      snapshotVersion: 1,
      scheduleSrs: true,
      startedAt: now,
      finalizedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
    stages: const <StudyModeType>[StudyModeType.fill],
    cardSnapshots: <SessionCardSnapshot>[
      SessionCardSnapshot(
        id: 'sc0',
        sessionId: 's1',
        cardId: 'c0',
        displayOrder: 0,
        term: 'apple',
        meaning: 'fruit',
        contentVersion: 1,
        progressBox: 0,
        progressRevision: 0,
      ),
    ],
    currentOrder: SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: const <String>['c0'],
    ),
  );

  Widget wrap() => ProviderScope(
    overrides: [
      studySessionRuntimeProvider.overrideWith(
        (ref) => Future.value(runtime()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FillScreen(),
    ),
  );

  testWidgets('waiting shows the meaning, input and Check/Help', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Fill'), findsOneWidget);
    expect(find.text('fruit'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    // Nothing is graded yet, so there is no Continue and no answer reveal.
    expect(find.text('Continue'), findsNothing);
    expect(find.textContaining('Answer:'), findsNothing);
  });

  testWidgets('a matching answer grades correct and offers Continue', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'apple');
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Check'), findsNothing);
    // A correct answer does not reveal the answer line.
    expect(find.textContaining('Answer:'), findsNothing);
  });

  testWidgets('a wrong answer reveals the answer and offers Continue', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'banana');
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Answer: apple'), findsOneWidget);
  });

  testWidgets('a blank answer keeps Check disabled (no grading)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Check is present but disabled; tapping it grades nothing.
    await tester.tap(find.text('Check'));
    await tester.pump();
    expect(find.text('Continue'), findsNothing);
  });
}

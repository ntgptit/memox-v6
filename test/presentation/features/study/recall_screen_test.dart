import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/recall_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.8 — Recall reveals on demand or on the 20s deadline, then maps the
/// self-grade to a canonical outcome (`recall-and-self-grade.md`).
void main() {
  final now = DateTime.utc(2026, 7, 23, 18);

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2200);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
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
    stages: const <StudyModeType>[StudyModeType.recall],
    cardSnapshots: <SessionCardSnapshot>[
      SessionCardSnapshot(
        id: 'sc0',
        sessionId: 's1',
        cardId: 'c0',
        displayOrder: 0,
        term: 'friend-term',
        meaning: 'friend',
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
      studySessionRuntimeProvider.overrideWith((ref) => Future.value(runtime())),
      studyAnswerViewmodelProvider.overrideWith(_SpyAnswer.new),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RecallScreen(),
    ),
  );

  setUp(recorded.clear);

  testWidgets('meaning and self-grade are hidden until reveal', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('friend'), findsNothing);
    expect(find.text('Got it'), findsNothing);
    expect(find.text('Forgot'), findsNothing);
    // The reveal button shows the live countdown from 20 seconds.
    expect(find.textContaining('20'), findsOneWidget);
  });

  testWidgets('Show reveals the meaning and the self-grade actions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('·'));
    await tester.pump();

    expect(find.text('friend'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text('Forgot'), findsOneWidget);
  });

  testWidgets('Got it commits a remembered resolution', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('·'));
    await tester.pump();

    await tester.tap(find.text('Got it'));
    await tester.pump();

    expect(recorded, hasLength(1));
    final input = recorded.single as RecallInput;
    expect(input.resolution, RecallResolution.remembered);
    expect(input.revealed, isTrue);
  });

  testWidgets('the 20-second deadline auto-reveals and commits a timeout', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 20));
    await tester.pump();

    expect(find.text('friend'), findsOneWidget);
    expect(find.text('Got it'), findsNothing);
    expect(find.textContaining('Time'), findsOneWidget);
    expect(recorded, hasLength(1));
    final input = recorded.single as RecallInput;
    expect(input.resolution, RecallResolution.timeout);
    expect(input.elapsedActiveMs, greaterThanOrEqualTo(20000));
  });
}

/// The committed inputs, shared between the spy command and the assertions
/// (the override factory takes no arguments, so the list lives at top level).
final List<StudyModeInput> recorded = <StudyModeInput>[];

/// A no-op answer command that records the committed inputs instead of hitting
/// the repository, so the timeout auto-commit is observable without a database.
class _SpyAnswer extends StudyAnswerViewmodel {
  @override
  Future<void> answer(StudyModeInput input) async {
    recorded.add(input);
  }
}

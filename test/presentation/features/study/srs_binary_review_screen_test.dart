import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
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
import 'package:memox_v6/presentation/features/study/screens/srs_binary_review_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.5 — the stage every due review runs (`srs-binary-review.md`).
///
/// It had no screen at all: the dispatcher's wildcard arm rendered "coming
/// soon", so a due-review session could be started and never answered.
void main() {
  final now = DateTime.utc(2026, 7, 27, 12);

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
      type: SessionType.dueReview,
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
    stages: const <StudyModeType>[StudyModeType.srsBinaryReview],
    cardSnapshots: <SessionCardSnapshot>[
      SessionCardSnapshot(
        id: 'sc0',
        sessionId: 's1',
        cardId: 'c0',
        displayOrder: 0,
        term: 'friend-term',
        meaning: 'friend',
        contentVersion: 1,
        progressBox: 3,
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
      studyAnswerViewmodelProvider.overrideWith(_SpyAnswer.new),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SrsBinaryReviewScreen(),
    ),
  );

  setUp(recorded.clear);

  // §1: "Term và meaning snapshot của đúng Card đều hiển thị." There is no
  // reveal step — this mode does not test recall, it asks the learner to grade
  // themselves against the answer in front of them.
  testWidgets('term and meaning are both shown, with no reveal step', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('friend-term'), findsOneWidget);
    expect(find.text('friend'), findsOneWidget);
    expect(find.text('Remembered'), findsOneWidget);
    expect(find.text('Relearn'), findsOneWidget);
  });

  // §1: "Không có timer, hint hoặc inference từ thời gian."
  testWidgets('no countdown appears', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('20'), findsNothing);
  });

  testWidgets('Remembered commits the correct-mapping action', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remembered'));
    await tester.pump();

    expect(recorded, hasLength(1));
    final input = recorded.single as SrsBinaryReviewInput;
    expect(input.action, SrsBinaryAction.remembered);
    expect(input.cardId, 'c0');
    expect(input.roundIndex, 1);
  });

  testWidgets('Relearn commits the wrong-mapping action', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Relearn'));
    await tester.pump();

    final input = recorded.single as SrsBinaryReviewInput;
    expect(input.action, SrsBinaryAction.relearn);
  });

  // §3: the same identity with a different action is a conflict, so the two
  // actions must not share an attempt id.
  testWidgets('the two actions carry different attempt identities', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remembered'));
    await tester.pump();
    await tester.tap(find.text('Relearn'));
    await tester.pump();

    final ids = recorded
        .cast<SrsBinaryReviewInput>()
        .map((input) => input.eventId)
        .toSet();
    expect(ids, hasLength(2));
  });
}

/// Records committed inputs instead of hitting the repository (the override
/// factory takes no arguments, so the list lives at top level).
final List<StudyModeInput> recorded = <StudyModeInput>[];

class _SpyAnswer extends StudyAnswerViewmodel {
  @override
  Future<void> answer(StudyModeInput input) async {
    recorded.add(input);
  }
}

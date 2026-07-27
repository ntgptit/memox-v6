import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:flutter/services.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/presentation/features/study/screens/review_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';

/// WBS 5.6.5 — the Review screen shows term + meaning together with browse
/// navigation (`review-cards.md`, kit `review-mode`).
void main() {
  final now = DateTime.utc(2026, 7, 23, 15);

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
    stages: const <StudyModeType>[StudyModeType.review, StudyModeType.match],
    cardSnapshots: <SessionCardSnapshot>[
      _card('a', 0, 'school', '학교'),
      _card('b', 1, 'teacher', '선생님'),
    ],
    currentOrder: const SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: <String>['a', 'b'],
    ),
  );

  StudyRuntimeState atSecondCard() => StudyRuntimeState.assemble(
    session: runtime().session,
    stages: const <StudyModeType>[StudyModeType.review, StudyModeType.match],
    cardSnapshots: <SessionCardSnapshot>[
      _card('a', 0, 'school', '학교'),
      _card('b', 1, 'teacher', '선생님'),
    ],
    currentOrder: const SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: <String>['a', 'b'],
    ),
    checkpoint: SessionCheckpoint(
      id: 'cp1',
      sessionId: 's1',
      stageIndex: 0,
      roundIndex: 1,
      cardPosition: 1,
      failedCardIds: const <String>[],
      timerStateJson: '{}',
      stateVersion: 1,
      updatedAt: now,
    ),
  );

  Widget wrap(StudyRuntimeState? state) => ProviderScope(
    overrides: [
      studySessionRuntimeProvider.overrideWith((ref) => Future.value(state)),
      studyAnswerViewmodelProvider.overrideWith(_SpyAnswer.new),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ReviewScreen(),
    ),
  );

  setUp(recorded.clear);

  testWidgets('shows the current card term + meaning and browse controls', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    expect(find.text('school'), findsOneWidget);
    expect(find.text('학교'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    // Kit review-mode bottom hint between the chevrons.
    expect(find.text('Swipe to continue'), findsOneWidget);

    // The previous chevron is disabled on the first card; next is enabled.
    final previous = tester.widget<MxIconButton>(
      find.ancestor(
        of: find.byIcon(Symbols.chevron_left_rounded),
        matching: find.byType(MxIconButton),
      ),
    );
    expect(previous.onPressed, isNull);
    final next = tester.widget<MxIconButton>(
      find.ancestor(
        of: find.byIcon(Symbols.chevron_right_rounded),
        matching: find.byType(MxIconButton),
      ),
    );
    expect(next.onPressed, isNotNull);
  });

  // §1: "Vuốt trái chuyển sang Card kế tiếp; vuốt phải quay lại Card trước
  // đó." The stage carried the kit's "Swipe to continue" hint over a surface
  // that ignored every swipe, so the one instruction on screen was the one
  // thing that did not work.
  testWidgets('a left swipe advances to the next card', (tester) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.fling(find.text('school'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(recorded, hasLength(1));
    expect((recorded.single as ReviewInput).cardId, 'a');
  });

  // §4: "Vuốt phải ở Card đầu tiên không đổi Card" — the same rule the
  // disabled Previous control already followed.
  testWidgets('a right swipe on the first card changes nothing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.fling(find.text('school'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    expect(recorded, isEmpty);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('a right swipe goes back a card once there is one', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(atSecondCard()));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);

    await tester.fling(find.text('teacher'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    expect(recorded, isEmpty, reason: 'browsing back records no evidence');
  });

  // §4: "Hai hướng đều phải có control và keyboard shortcut truy cập được,
  // không phụ thuộc gesture duy nhất." On Web there was no key that moved a
  // card at all.
  testWidgets('the arrow keys move the same two directions', (tester) async {
    await tester.pumpWidget(wrap(atSecondCard()));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    expect(
      recorded,
      isEmpty,
      reason: 'returning to a card already seen records nothing again',
    );
  });

  testWidgets('shows an empty message when no session is active', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();
    expect(find.text('No study session is in progress.'), findsOneWidget);
  });
}

SessionCardSnapshot _card(String id, int order, String meaning, String term) =>
    SessionCardSnapshot(
      id: 'sc-$id',
      sessionId: 's1',
      cardId: id,
      displayOrder: order,
      term: term,
      meaning: meaning,
      contentVersion: 1,
      progressBox: 0,
      progressRevision: 0,
    );

/// Records what the stage submits instead of writing it.
final recorded = <StudyModeInput>[];

class _SpyAnswer extends StudyAnswerViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  @override
  Future<AsyncValue<void>> answer(StudyModeInput input) async {
    recorded.add(input);
    state = const AsyncData<void>(null);
    return state;
  }
}

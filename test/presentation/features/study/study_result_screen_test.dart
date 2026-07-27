import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/study_result_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_result_notifier.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';

/// WBS 5.6.13 — the Study Result screen renders the committed summary and the
/// finalizing / finalize-error states (`finalize-study-session.md` §§4,6,7).
void main() {
  Widget wrap(
    AsyncValue<StudySessionSummary?> state, {
    _FakeResult? notifier,
  }) => ProviderScope(
    overrides: [
      studyResultProvider.overrideWith(() => notifier ?? _FakeResult(state)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StudyResultScreen(),
    ),
  );

  testWidgets('the result shows the summary counts, accuracy and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AsyncData<StudySessionSummary?>(
          StudySessionSummary(
            reviewedCount: 5,
            correctCount: 4,
            missedCardIds: <String>['c5'],
            durationActiveMs: 390000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // reviewed count stat
    expect(find.text('80%'), findsOneWidget); // 4/5 accuracy
    expect(find.text('6:30'), findsOneWidget); // active-time stat
    expect(find.text('Review mistakes'), findsOneWidget); // missed cards → link
    expect(find.widgetWithText(MxButton, 'Keep studying'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Back to library'), findsOneWidget);
  });

  // `relearn-cards.md` §6. The link is the retry, so it stays; what was
  // missing is any sign that the tap failed at all — the learner was left
  // tapping a control that did nothing, the same way it behaved before it
  // started a session in the first place.
  testWidgets('a relearn that cannot start says so and keeps the link', (
    tester,
  ) async {
    final fake = _FakeResult(
      const AsyncData<StudySessionSummary?>(
        StudySessionSummary(
          reviewedCount: 5,
          correctCount: 4,
          missedCardIds: <String>['c5'],
        ),
      ),
      relearn: AsyncError<void>(
        ValidationFailure(field: 'relearn', code: 'unwritable'),
        StackTrace.empty,
      ),
    );
    await tester.pumpWidget(
      wrap(const AsyncData<StudySessionSummary?>(null), notifier: fake),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review mistakes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Couldn’t save the relearn queue. Your answers are safe.'),
      findsOneWidget,
    );
    expect(find.text('Review mistakes'), findsOneWidget);
  });

  testWidgets('the streak card shows when the session has a goal status', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AsyncData<StudySessionSummary?>(
          StudySessionSummary(
            reviewedCount: 24,
            correctCount: 21,
            missedCardIds: <String>[],
            durationActiveMs: 390000,
            goalStatus: StudyResultGoalStatus(
              streakDays: 12,
              goalDoneCards: 14,
              goalTargetCards: 20,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12 days'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    expect(find.text("Today's goal"), findsOneWidget);
    expect(find.text('14/20 cards'), findsOneWidget);
    // No missed cards → no Review mistakes link.
    expect(find.text('Review mistakes'), findsNothing);
  });

  // `complete-daily-goal.md` §3 node F: the goal-met result state. The screen
  // had one hero for every outcome, so the surface where the goal is actually
  // completed was the one surface that never said so.
  testWidgets('a session that met the goal says so', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AsyncData<StudySessionSummary?>(
          StudySessionSummary(
            reviewedCount: 24,
            correctCount: 21,
            missedCardIds: <String>[],
            goalStatus: StudyResultGoalStatus(
              streakDays: 13,
              goalDoneCards: 20,
              goalTargetCards: 20,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily goal reached!'), findsOneWidget);
    // §4's second line, and the standard hero's copy is gone.
    expect(find.text('20 of 20 completed today'), findsOneWidget);
    expect(find.text('Session complete'), findsNothing);
    // The kit's achievement badge on the streak card.
    expect(find.text('Daily goal completed!'), findsOneWidget);
    // The streak card itself is unchanged beside it.
    expect(find.text('13 days'), findsOneWidget);
  });

  // §1: "Goal vượt target vẫn giữ completed state".
  testWidgets('passing the target still reads as met', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AsyncData<StudySessionSummary?>(
          StudySessionSummary(
            reviewedCount: 30,
            correctCount: 30,
            missedCardIds: <String>[],
            goalStatus: StudyResultGoalStatus(
              streakDays: 3,
              goalDoneCards: 22,
              goalTargetCards: 20,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily goal reached!'), findsOneWidget);
    expect(find.text('22 of 20 completed today'), findsOneWidget);
  });

  // §1: "Disabled Goal không phát completion". Finalize returns no goal status
  // when no goal is configured, and a session with nothing to complete must
  // not read as a completion.
  testWidgets('no goal configured completes nothing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AsyncData<StudySessionSummary?>(
          StudySessionSummary(
            reviewedCount: 24,
            correctCount: 21,
            missedCardIds: <String>[],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily goal reached!'), findsNothing);
    expect(find.text('Daily goal completed!'), findsNothing);
    expect(find.text('Session complete'), findsOneWidget);
  });

  // A goal that is still short keeps the standard hero. §3 branches on the
  // completion alone, and the kit's goal-missed state has no rule in this
  // build for when a shortfall counts as almost — recorded as int-73.
  testWidgets('a goal still short keeps the standard result', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AsyncData<StudySessionSummary?>(
          StudySessionSummary(
            reviewedCount: 14,
            correctCount: 12,
            missedCardIds: <String>[],
            goalStatus: StudyResultGoalStatus(
              streakDays: 12,
              goalDoneCards: 14,
              goalTargetCards: 20,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Daily goal completed!'), findsNothing);
  });

  testWidgets('a zero-card summary renders 0% without dividing by zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AsyncData<StudySessionSummary?>(
          StudySessionSummary(
            reviewedCount: 0,
            correctCount: 0,
            missedCardIds: <String>[],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('the finalizing state shows a progress label', (tester) async {
    await tester.pumpWidget(wrap(const AsyncLoading<StudySessionSummary?>()));
    await tester.pump();
    expect(find.text('Finalizing…'), findsWidgets);
    expect(find.text('Session complete'), findsNothing);
  });

  testWidgets('a not-yet-finalized state also shows finalizing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const AsyncData<StudySessionSummary?>(null)));
    await tester.pump();
    expect(find.text('Finalizing…'), findsWidgets);
  });

  // §6. This screen is terminal by design — no back, exit only through its
  // own actions — so a finalize that kept failing had the learner holding one
  // button with nowhere to go. Leaving is safe: the session stays active,
  // Today offers it back, and opening it finalizes again under the same
  // request identity, so the deferred attempt counts once.
  testWidgets('the finalize-error state explains itself and offers both '
      'ways on', (tester) async {
    await tester.pumpWidget(
      wrap(AsyncError<StudySessionSummary?>('boom', StackTrace.empty)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t save your results'), findsOneWidget);
    expect(
      find.text(
        'Your session finished, but we couldn’t update your schedule. Retry '
        'so this session counts.',
      ),
      findsOneWidget,
    );
    // The kit's own labels (`StudyResult.jsx`: `Retry` + `Not now`), which
    // `MX-VIS-077` measures at 1.61% light / 2.50% dark.
    expect(find.widgetWithText(MxButton, 'Retry'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Not now'), findsOneWidget);
  });
}

/// Overrides the result notifier to a fixed state; retry is a no-op so the error
/// test never reaches the real finalize dependencies.
class _FakeResult extends StudyResult {
  _FakeResult(this._state, {this.relearn});
  final AsyncValue<StudySessionSummary?> _state;

  /// What a `Review mistakes` tap returns: null when there was nothing to
  /// start, otherwise the start's own outcome.
  final AsyncValue<void>? relearn;

  int relearnTaps = 0;

  @override
  AsyncValue<StudySessionSummary?> build() => _state;

  @override
  Future<void> retry() async {}

  @override
  Future<void> finalize() async {}

  @override
  Future<AsyncValue<void>?> startRelearn() async {
    relearnTaps++;
    return relearn;
  }
}

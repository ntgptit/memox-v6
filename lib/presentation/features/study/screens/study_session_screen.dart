import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/fill_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/guess_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/match_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/recall_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/review_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/srs_binary_review_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/study_result_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_result_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';

/// The active study route (WBS 5.6). It dispatches to the current stage's
/// mode screen from the runtime; an empty session shows a placeholder.
///
/// The switch is exhaustive over `StudyModeType` on purpose. It ended in a
/// `_ =>` "coming soon" arm, which is how `srsBinaryReview` — the plan every
/// due review runs — reached production with no screen behind it: the mode
/// was added to the enum and the wildcard swallowed it. An exhaustive switch
/// makes the next one a compile error.
///
/// Template-only: the consumer child does the watch (guard
/// `template_shell_no_ref_watch`).
class StudySessionScreen extends StatelessWidget {
  const StudySessionScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StudyStageDispatch();
}

class _StudyStageDispatch extends ConsumerWidget {
  const _StudyStageDispatch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Finalize once when the session completes, and step over a card that is
    // no longer askable before it can be rendered (ST-CHG-005/006).
    ref.listen(studySessionRuntimeProvider, (_, next) {
      final runtime = next.asData?.value;
      if (runtime == null) return;
      if (runtime.isComplete) {
        ref.read(studyResultProvider.notifier).finalize();
        return;
      }
      unawaited(_skipUnavailableCard(ref, runtime));
    });

    // `answer-study-stage.md` §6: a save that fails opens a dialog and the
    // answer stays. Nothing read this command's state, so a failed save was
    // invisible in every mode — the card simply stayed put, exactly as it
    // does while a save is in flight. Mounted here rather than per mode
    // screen: all five submit through the same command, and this is the one
    // widget that outlives the stage they are dispatched into.
    listenMxAction(
      ref,
      studyAnswerViewmodelProvider,
      onFailure: (failure) =>
          unawaited(_reportAnswerFailure(context, ref, failure)),
    );

    // The result outlives the active session (finalize clears it), so show it
    // whenever finalize has started, failed or produced a committed summary.
    final result = ref.watch(studyResultProvider);
    if (result.isLoading || result.hasError || result.asData?.value != null) {
      return const StudyResultScreen();
    }

    return MxAsyncBuilder<StudyRuntimeState?>(
      value: ref.watch(studySessionRuntimeProvider),
      loadingLabel: l10n.loadingLabel,
      // §4's own composition rather than the compact banner: this is a
      // full-screen route with no tab bar and no back, so the error owns the
      // frame and has to carry its own exits. §8 names one of them —
      // "Back từ resume error về Dashboard, giữ session paused" — and it was
      // not there, so a resume that kept failing left the learner with a
      // Retry button and nothing else.
      error: (context, failure) => _ResumeFailed(
        onRetry: () => ref.invalidate(studySessionRuntimeProvider),
      ),
      errorTitle: l10n.studyResumeFailedTitle,
      data: (context, runtime) {
        if (runtime == null) {
          // §3 node E / §7: "Session unavailable: về Dashboard/Deck với copy
          // phục hồi". This was a dead end — a title and nothing else, on a
          // full-screen route with no tab bar and no back. A learner who
          // opened it after their session was finalized elsewhere, or who
          // came in on a link, had no way out of it at all.
          return MxEmptyState(
            icon: Icons.school_outlined,
            title: l10n.reviewNoSessionMessage,
            body: l10n.reviewNoSessionBody,
            action: MxButton(
              label: l10n.reviewNoSessionActionLabel,
              onPressed: () => context.goHome(),
            ),
          );
        }
        // A completed session shows the result while finalize runs.
        if (runtime.isComplete) return const StudyResultScreen();
        return switch (runtime.currentMode) {
          StudyModeType.review => const ReviewScreen(),
          StudyModeType.match => const MatchScreen(),
          StudyModeType.guess => const GuessScreen(),
          StudyModeType.recall => const RecallScreen(),
          StudyModeType.fill => const FillScreen(),
          StudyModeType.srsBinaryReview => const SrsBinaryReviewScreen(),
        };
      },
    );
  }
}

/// The answer-save failure dialog (`answer-study-stage.md` §6, §9).
///
/// Two cases, and §9 gives each its own copy. A stale write means the session
/// moved elsewhere and the fix is to re-read it; anything else is a save that
/// did not land, where the answer is still on screen and `Try again`
/// re-submits the same attempt.
Future<void> _reportAnswerFailure(
  BuildContext context,
  WidgetRef ref,
  AppFailure failure,
) async {
  final l10n = AppLocalizations.of(context);
  final isStale = failure is ConflictFailure;
  final retried = await showMxDialog<bool>(
    context,
    title: isStale
        ? l10n.studyStaleSessionTitle
        : l10n.studyAnswerSaveFailedTitle,
    body: MxText(
      isStale ? l10n.studyStaleSessionBody : l10n.studyAnswerSaveFailedBody,
      role: MxTextRole.body,
    ),
    actions: <Widget>[
      MxButton(
        label: isStale ? l10n.studyReloadLabel : l10n.studyTryAgainLabel,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ],
  );
  if (retried != true || !context.mounted) return;
  if (isStale) {
    ref.invalidate(studySessionRuntimeProvider);
    return;
  }
  await ref.read(studyAnswerViewmodelProvider.notifier).retry();
}

/// Commits a skip past a card the learner deleted or hid since the session
/// started, then re-reads the runtime so the next card renders
/// (ST-CONTENT-CHANGE-v1 ST-CHG-005, ST-CHG-006).
///
/// Nothing is said about it. The card is gone because the learner removed it,
/// and a session that quietly declines to quiz them on it is doing what they
/// asked; a notice here would report their own action back to them mid-study.
Future<void> _skipUnavailableCard(
  WidgetRef ref,
  StudyRuntimeState runtime,
) async {
  final skipped = await ref
      .read(skipUnavailableCardUseCaseProvider)
      .call(runtime);
  if (skipped == null) return;
  ref.invalidate(studySessionRuntimeProvider);
}

/// The resume-error state (`resume-study-session.md` §4, §8).
///
/// §4 pairs `Try again` with `Start fresh`, and `Start fresh` is still not
/// offered: ending a running session is the undefined act `int-15` records,
/// and here it would discard answers whose count the learner can see. Leaving
/// for the dashboard is not that act — §8 is explicit that Back keeps the
/// session paused — so that is the second way out.
class _ResumeFailed extends StatelessWidget {
  const _ResumeFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MxEmptyState(
      icon: Icons.refresh_rounded,
      tone: MxIconTileTone.warning,
      title: l10n.studyResumeFailedTitle,
      body: l10n.studyResumeFailedBody,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MxButton(
            label: l10n.studyTryAgainLabel,
            block: true,
            onPressed: onRetry,
          ),
          const MxGap.s2(),
          MxButton(
            label: l10n.reviewNoSessionActionLabel,
            variant: MxButtonVariant.ghost,
            block: true,
            onPressed: () => context.goHome(),
          ),
        ],
      ),
    );
  }
}

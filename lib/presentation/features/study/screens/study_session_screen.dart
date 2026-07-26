import 'dart:async';
import 'package:flutter/material.dart';
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

    // Finalize once when the session completes.
    ref.listen(studySessionRuntimeProvider, (_, next) {
      if (next.asData?.value?.isComplete ?? false) {
        ref.read(studyResultProvider.notifier).finalize();
      }
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
      errorTitle: l10n.studyResumeFailedTitle,
      // §3 node H: "Recoverable error" offers Retry. The spec pairs it with
      // `Start fresh`, which is not offered — ending the running session is
      // the same undefined act `int-15` records, and here it would discard
      // answers the learner can still see the count of.
      retryLabel: l10n.studyRetryLabel,
      onRetry: () => ref.invalidate(studySessionRuntimeProvider),
      data: (context, runtime) {
        if (runtime == null) {
          return MxEmptyState(
            icon: Icons.school_outlined,
            title: l10n.reviewNoSessionMessage,
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

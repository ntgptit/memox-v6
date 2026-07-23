import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/fill_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/guess_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/recall_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/review_screen.dart';
import 'package:memox_v6/presentation/features/study/screens/study_result_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_result_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';

/// The active study session route (WBS 5.6). It dispatches to the current
/// stage's mode screen from the runtime; an empty session shows a placeholder.
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

    // The result outlives the active session (finalize clears it), so show it
    // whenever finalize has started, failed or produced a committed summary.
    final result = ref.watch(studyResultProvider);
    if (result.isLoading || result.hasError || result.asData?.value != null) {
      return const StudyResultScreen();
    }

    return MxAsyncBuilder<StudyRuntimeState?>(
      value: ref.watch(studySessionRuntimeProvider),
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
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
          StudyModeType.guess => const GuessScreen(),
          StudyModeType.recall => const RecallScreen(),
          StudyModeType.fill => const FillScreen(),
          // Match (5.6.6) is deferred on a board-runtime gap; until its screen
          // lands a Match stage parks here rather than crashing.
          _ => MxEmptyState(
            icon: Icons.hourglass_empty_outlined,
            title: l10n.studyStageComingSoonMessage,
          ),
        };
      },
    );
  }
}

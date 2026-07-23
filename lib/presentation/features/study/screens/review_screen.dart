import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/review_browse_cursor_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/features/study/widgets/study_shell.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_label.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Review stage (WBS 5.6.5; `review-cards.md`, kit `review-mode`). Term and
/// meaning show together with no reveal; the learner browses forward (Next /
/// swipe left) and back (Previous / swipe right) through the round's cards, and
/// Finish on the last card completes the stage.
///
/// Template-only screen: the consumer child does the watch (guard
/// `template_shell_no_ref_watch`).
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ReviewView();
}

class _ReviewView extends ConsumerWidget {
  const _ReviewView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MxAsyncBuilder<StudyRuntimeState?>(
      value: ref.watch(studySessionRuntimeProvider),
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, runtime) {
        if (runtime == null || runtime.currentMode != StudyModeType.review) {
          return MxEmptyState(
            icon: Icons.menu_book_outlined,
            title: l10n.reviewNoSessionMessage,
          );
        }
        return _ReviewStage(runtime: runtime);
      },
    );
  }
}

class _ReviewStage extends ConsumerWidget {
  const _ReviewStage({required this.runtime});

  final StudyRuntimeState runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final browseBack = ref.watch(reviewBrowseCursorProvider);
    final position = runtime.position;
    final roundCards = position.roundCardIds;
    final total = roundCards.length;
    final viewIndex = (position.cardPosition - browseBack).clamp(0, total - 1);
    final card = runtime.cardsById[roundCards[viewIndex]];

    final atCommittedCard = browseBack == 0;
    final isLastCard = atCommittedCard && position.cardPosition == total - 1;
    final canGoBack = viewIndex > 0;

    return StudyShell(
      title: l10n.reviewModeTitle,
      progress: total == 0 ? 0 : (viewIndex + 1) / total,
      progressCounter: '${viewIndex + 1}/$total',
      progressSemanticLabel: l10n.studyProgressLabel(viewIndex + 1, total),
      onBack: () => Navigator.of(context).maybePop(),
      backLabel: l10n.studyExitLabel,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MxSectionLabel(text: l10n.meaningLabel),
                const MxGap.s2(),
                MxText(card?.meaning ?? '', role: MxTextRole.title),
              ],
            ),
          ),
          const MxGap.s4(),
          Expanded(
            child: MxCard(
              child: Center(
                child: MxText(card?.term ?? '', role: MxTextRole.display),
              ),
            ),
          ),
        ],
      ),
      bottomBar: Row(
        children: <Widget>[
          Expanded(
            child: MxButton(
              label: l10n.reviewPreviousLabel,
              variant: MxButtonVariant.secondary,
              onPressed: canGoBack
                  ? () => ref.read(reviewBrowseCursorProvider.notifier).back()
                  : null,
            ),
          ),
          const MxGap.s3(),
          Expanded(
            child: MxButton(
              label: isLastCard ? l10n.reviewFinishLabel : l10n.reviewNextLabel,
              onPressed: () => _goForward(ref, card?.cardId, browseBack),
            ),
          ),
        ],
      ),
    );
  }

  void _goForward(WidgetRef ref, String? cardId, int browseBack) {
    // Re-viewing an already-seen card: purely local, no evidence.
    if (browseBack > 0) {
      ref.read(reviewBrowseCursorProvider.notifier).forward();
      return;
    }
    if (cardId == null) return;
    // At the committed cursor: record the reviewed evidence and advance. The
    // runtime query invalidates, rebuilding this stage at the next card.
    ref
        .read(studyAnswerViewmodelProvider.notifier)
        .answer(
          ReviewInput(
            sessionId: runtime.session.id,
            cardId: cardId,
            eventId: 'review-$cardId',
          ),
        );
  }
}

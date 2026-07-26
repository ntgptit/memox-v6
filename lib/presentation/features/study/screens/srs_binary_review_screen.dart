import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/features/study/widgets/study_shell.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_divider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The SRS Binary Review stage (WBS 5.6.5; `srs-binary-review.md`).
///
/// The mode every `dueReview` session runs, and the Relearn fallback when the
/// snapshot has no Guess pool. It had no screen: the dispatcher fell through
/// to "coming soon", so a due review — the app's daily loop — could be started
/// and never answered.
///
/// §1 fixes the interaction exactly: term **and** meaning both shown, two
/// actions, `Remembered → correct` and `Relearn → wrong`. There is no reveal
/// step, because there is nothing to reveal — this mode does not test recall,
/// it asks the learner to grade themselves against the answer in front of
/// them. "Không có timer, hint hoặc inference từ thời gian" is why no
/// countdown appears here even though Recall looks superficially similar.
///
/// Template-only screen: the consumer child does the watch.
class SrsBinaryReviewScreen extends StatelessWidget {
  const SrsBinaryReviewScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SrsBinaryReviewView();
}

class _SrsBinaryReviewView extends ConsumerWidget {
  const _SrsBinaryReviewView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MxAsyncBuilder<StudyRuntimeState?>(
      value: ref.watch(studySessionRuntimeProvider),
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, runtime) {
        final current = runtime?.currentCard;
        if (runtime == null ||
            runtime.currentMode != StudyModeType.srsBinaryReview ||
            current == null) {
          return MxEmptyState(
            icon: Icons.school_outlined,
            title: l10n.reviewNoSessionMessage,
          );
        }
        return _SrsBinaryReviewStage(runtime: runtime, card: current);
      },
    );
  }
}

class _SrsBinaryReviewStage extends ConsumerWidget {
  const _SrsBinaryReviewStage({required this.runtime, required this.card});

  final StudyRuntimeState runtime;
  final SessionCardSnapshot card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final position = runtime.position;
    final total = position.roundCardIds.length;
    final currentIndex = position.cardPosition + 1;

    return StudyShell(
      title: l10n.srsBinaryReviewTitle,
      progress: total == 0 ? 0 : currentIndex / total,
      progressCounter: '$currentIndex/$total',
      progressSemanticLabel: l10n.studyProgressLabel(currentIndex, total),
      onBack: () => Navigator.of(context).maybePop(),
      backLabel: l10n.studyExitLabel,
      body: Center(
        child: MxCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MxText(
                card.term,
                role: MxTextRole.display,
                textAlign: TextAlign.center,
              ),
              const MxGap.s5(),
              const MxDivider(),
              const MxGap.s5(),
              MxText(
                card.meaning,
                role: MxTextRole.title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      // §4: "Hai action map deterministic tới `correct|wrong` và có non-color
      // affordance" — each carries its own glyph and label, so the pair reads
      // without relying on the tint to tell them apart.
      bottomBar: Row(
        children: <Widget>[
          Expanded(
            child: MxButton(
              variant: MxButtonVariant.outline,
              icon: Symbols.replay_rounded,
              label: l10n.srsBinaryRelearnLabel,
              block: true,
              onPressed: () => _commit(ref, SrsBinaryAction.relearn),
            ),
          ),
          const MxGap.s3(),
          Expanded(
            child: MxButton(
              icon: Symbols.check_rounded,
              label: l10n.srsBinaryRememberedLabel,
              block: true,
              onPressed: () => _commit(ref, SrsBinaryAction.remembered),
            ),
          ),
        ],
      ),
    );
  }

  void _commit(WidgetRef ref, SrsBinaryAction action) {
    ref
        .read(studyAnswerViewmodelProvider.notifier)
        .answer(
          SrsBinaryReviewInput(
            sessionId: runtime.session.id,
            cardId: card.cardId,
            roundIndex: runtime.position.roundIndex,
            // §3: the same identity with the same payload replays the prior
            // evidence, and with a *different* action is a conflict — so the
            // action belongs in the key rather than being keyed by card alone.
            eventId: 'srs-binary-${card.cardId}-${action.name}',
            action: action,
          ),
        );
  }
}

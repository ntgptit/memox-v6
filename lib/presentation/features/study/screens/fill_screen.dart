import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/fill_answer_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/features/study/widgets/study_shell.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_label.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Fill stage (WBS 5.6.9; `fill-card-answer.md`, kit `fill-mode`). The meaning
/// shows; the learner types the term and taps Check. The answer is compared
/// under `fill-compare-v1` (SM-FILL-v1) — a normalized exact match is `correct`,
/// else `wrong` with the answer revealed. Continue commits the outcome and
/// advances; a wrong card returns in the next mastery round.
///
/// Check previews the outcome through the mode factory's pure `evaluate`; the
/// durable commit happens on Continue via the shared answer command. Per-card
/// "accept"/Retry overrides and hint-driven grading are out of the master flow
/// and deferred. Template-only screen: the consumer child does the watch.
class FillScreen extends StatelessWidget {
  const FillScreen({super.key});

  @override
  Widget build(BuildContext context) => const _FillView();
}

class _FillView extends ConsumerWidget {
  const _FillView();

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
            runtime.currentMode != StudyModeType.fill ||
            current == null) {
          return MxEmptyState(
            icon: Icons.keyboard_outlined,
            title: l10n.reviewNoSessionMessage,
          );
        }
        // Key by card so the input controller + feedback reset each card.
        return _FillStage(
          key: ValueKey<String>(current.cardId),
          runtime: runtime,
          card: current,
        );
      },
    );
  }
}

class _FillStage extends HookConsumerWidget {
  const _FillStage({super.key, required this.runtime, required this.card});

  final StudyRuntimeState runtime;
  final SessionCardSnapshot card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final answer = useMxTextSubmitState();
    final outcome = ref.watch(fillFeedbackProvider(card.cardId));
    final hintShown = ref.watch(fillHintProvider(card.cardId));
    final position = runtime.position;
    final total = position.roundCardIds.length;
    final currentIndex = position.cardPosition + 1;

    final graded = outcome != null;
    final isWrong = outcome == ModeOutcome.wrong;

    return StudyShell(
      title: l10n.fillModeTitle,
      progress: total == 0 ? 0 : currentIndex / total,
      progressCounter: '$currentIndex/$total',
      progressSemanticLabel: l10n.studyProgressLabel(currentIndex, total),
      onBack: () => Navigator.of(context).maybePop(),
      backLabel: l10n.studyExitLabel,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: MxCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MxSectionLabel(text: l10n.meaningLabel),
                  const MxGap.s3(),
                  MxText(
                    card.meaning,
                    role: MxTextRole.title,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const MxGap.s6(),
          MxText(
            l10n.fillTypeTermLabel,
            role: MxTextRole.caption,
            color: context.colors.textSecondary,
          ),
          const MxGap.s3(),
          MxTextField(
            controller: answer.controller,
            placeholder: l10n.fillAnswerPlaceholder,
            boxed: true,
            textAlign: TextAlign.center,
            enabled: !graded,
            readOnly: graded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!graded && answer.canSubmit) {
                _check(ref, answer.value, hintShown);
              }
            },
          ),
          if (hintShown && !graded) ...<Widget>[
            const MxGap.s3(),
            MxText(
              l10n.fillHintMessage(
                card.term.characters.length,
                card.term.characters.first,
              ),
              role: MxTextRole.caption,
              color: context.colors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
          if (isWrong) ...<Widget>[
            const MxGap.s4(),
            MxText(
              l10n.fillAnswerRevealLabel(card.term),
              role: MxTextRole.body,
              color: context.colors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      bottomBar: _bottomBar(ref, l10n, answer, outcome, hintShown),
    );
  }

  Widget _bottomBar(
    WidgetRef ref,
    AppLocalizations l10n,
    ({TextEditingController controller, String value, bool canSubmit}) answer,
    ModeOutcome? outcome,
    bool hintShown,
  ) {
    if (outcome != null) {
      return MxButton(
        icon: Symbols.arrow_forward_rounded,
        label: l10n.studyContinueLabel,
        block: true,
        onPressed: () => _continue(ref, answer.value, hintShown),
      );
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: MxButton(
            variant: MxButtonVariant.ghost,
            icon: Symbols.lightbulb_rounded,
            label: l10n.fillHelpLabel,
            block: true,
            onPressed: () =>
                ref.read(fillHintProvider(card.cardId).notifier).reveal(),
          ),
        ),
        const MxGap.s3(),
        Expanded(
          child: MxButton(
            label: l10n.fillCheckLabel,
            block: true,
            onPressed: answer.canSubmit
                ? () => _check(ref, answer.value, hintShown)
                : null,
          ),
        ),
      ],
    );
  }

  FillInput _input(String rawInput, bool hintUsed) => FillInput(
    sessionId: runtime.session.id,
    cardId: card.cardId,
    roundIndex: runtime.position.roundIndex,
    eventId: 'fill-${card.cardId}',
    rawInput: rawInput,
    acceptedAnswers: <String>[card.term],
    hintUsed: hintUsed,
  );

  void _check(WidgetRef ref, String rawInput, bool hintUsed) {
    ref
        .read(fillFeedbackProvider(card.cardId).notifier)
        .grade(_input(rawInput, hintUsed));
  }

  void _continue(WidgetRef ref, String rawInput, bool hintUsed) {
    ref
        .read(studyAnswerViewmodelProvider.notifier)
        .answer(_input(rawInput, hintUsed));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_modes/guess_question_builder.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/guess_selection_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_answer_viewmodel.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/features/study/widgets/study_shell.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Guess stage (WBS 5.6.7; `guess-card-meaning.md`, kit `guess-mode`). Shows the
/// term prompt and exactly five meaning choices (one correct + four
/// distractors). Selecting reveals correct/wrong feedback; Continue commits the
/// answer and advances. A pool without five distinct meanings shows a recovery
/// message rather than a malformed question (ST-TYPE-011).
///
/// Template-only screen: the consumer child does the watch.
class GuessScreen extends StatelessWidget {
  const GuessScreen({super.key});

  @override
  Widget build(BuildContext context) => const _GuessView();
}

class _GuessView extends ConsumerWidget {
  const _GuessView();

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
            runtime.currentMode != StudyModeType.guess ||
            current == null) {
          return MxEmptyState(
            icon: Icons.quiz_outlined,
            title: l10n.reviewNoSessionMessage,
          );
        }
        final GuessQuestion question;
        try {
          question = const GuessQuestionBuilder().build(
            sessionId: runtime.session.id,
            roundIndex: runtime.position.roundIndex,
            target: GuessCandidate(
              cardId: current.cardId,
              meaning: current.meaning,
            ),
            pool: runtime.cardsById.values
                .map((c) => GuessCandidate(cardId: c.cardId, meaning: c.meaning))
                .toList(),
          );
        } on ValidationFailure {
          return MxEmptyState(
            icon: Icons.error_outline,
            title: l10n.guessInvalidPoolMessage,
          );
        }
        return _GuessStage(runtime: runtime, question: question);
      },
    );
  }
}

class _GuessStage extends ConsumerWidget {
  const _GuessStage({required this.runtime, required this.question});

  final StudyRuntimeState runtime;
  final GuessQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(guessSelectionProvider);
    final position = runtime.position;
    final total = position.roundCardIds.length;
    final current = position.cardPosition + 1;

    return StudyShell(
      title: l10n.guessModeTitle,
      progress: total == 0 ? 0 : current / total,
      progressCounter: '$current/$total',
      progressSemanticLabel: l10n.studyProgressLabel(current, total),
      onBack: () => Navigator.of(context).maybePop(),
      backLabel: l10n.studyExitLabel,
      body: ListView(
        children: <Widget>[
          MxCard(
            child: SizedBox(
              height: 96,
              child: Center(
                child: MxText(
                  runtime.currentCard?.term ?? '',
                  role: MxTextRole.display,
                ),
              ),
            ),
          ),
          const MxGap.s5(),
          for (final option in question.options) ...<Widget>[
            _GuessOption(
              option: option,
              selected: selected,
              correctChoiceId: question.correctChoiceId,
              onTap: selected == null
                  ? () =>
                        ref.read(guessSelectionProvider.notifier).select(
                          option.choiceId,
                        )
                  : null,
            ),
            const MxGap.s3(),
          ],
        ],
      ),
      bottomBar: selected == null
          ? null
          : MxButton(
              label: l10n.studyContinueLabel,
              onPressed: () => _continue(ref, selected),
            ),
    );
  }

  void _continue(WidgetRef ref, String selectedChoiceId) {
    final cardId = runtime.currentCard?.cardId;
    if (cardId == null) return;
    ref
        .read(studyAnswerViewmodelProvider.notifier)
        .answer(
          GuessInput(
            sessionId: runtime.session.id,
            cardId: cardId,
            roundIndex: runtime.position.roundIndex,
            eventId: 'guess-$cardId',
            options: question.options,
            correctChoiceId: question.correctChoiceId,
            selectedChoiceId: selectedChoiceId,
          ),
        );
    ref.read(guessSelectionProvider.notifier).clear();
  }
}

class _GuessOption extends StatelessWidget {
  const _GuessOption({
    required this.option,
    required this.selected,
    required this.correctChoiceId,
    required this.onTap,
  });

  final GuessOption option;
  final String? selected;
  final String correctChoiceId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final answered = selected != null;
    final isCorrect = option.choiceId == correctChoiceId;
    final isChosen = option.choiceId == selected;

    // After answering, the correct choice reads success and a wrong pick reads
    // error; before answering every option is neutral.
    final feedbackIcon = !answered
        ? null
        : isCorrect
        ? MxIcon(
            icon: Symbols.check_circle_rounded,
            color: context.colors.success,
          )
        : isChosen
        ? MxIcon(icon: Symbols.cancel_rounded, color: context.colors.error)
        : null;

    return MxCard(
      variant: isChosen ? MxCardVariant.primarySoft : MxCardVariant.flat,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(child: MxText(option.meaning, role: MxTextRole.body)),
          ?feedbackIcon,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/recall_timer_notifier.dart';
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

/// Recall stage (WBS 5.6.8; `recall-and-self-grade.md`, kit `recall-mode`). The
/// term shows with a hidden meaning and a live 20-second countdown; the learner
/// taps Show to reveal, then self-grades Got it / Forgot. If the deadline
/// arrives first the answer auto-reveals and locks to wrong (timeout). Got it →
/// `correct`, Forgot → `wrong`, timeout → `wrong(reason: timeout)`.
///
/// The countdown and the resolved-once lock live in a Riverpod notifier
/// ([RecallTimer]); durable cross-exit timer persistence lands with WBS 5.6.12.
///
/// Template-only screen: the consumer child does the watch.
class RecallScreen extends StatelessWidget {
  const RecallScreen({super.key});

  @override
  Widget build(BuildContext context) => const _RecallView();
}

class _RecallView extends ConsumerWidget {
  const _RecallView();

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
            runtime.currentMode != StudyModeType.recall ||
            current == null) {
          return MxEmptyState(
            icon: Icons.psychology_outlined,
            title: l10n.reviewNoSessionMessage,
          );
        }
        return _RecallStage(runtime: runtime, card: current);
      },
    );
  }
}

class _RecallStage extends ConsumerWidget {
  const _RecallStage({required this.runtime, required this.card});

  final StudyRuntimeState runtime;
  final SessionCardSnapshot card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timer = ref.watch(recallTimerProvider(card.cardId));
    final position = runtime.position;
    final total = position.roundCardIds.length;
    final currentIndex = position.cardPosition + 1;

    // The deadline commits exactly one canonical wrong(timeout): the transition
    // guard fires the answer once, when counting first crosses into timedOut.
    ref.listen<RecallTimerState>(recallTimerProvider(card.cardId), (prev, next) {
      if (prev?.phase != RecallPhase.timedOut &&
          next.phase == RecallPhase.timedOut) {
        _commit(
          ref,
          RecallResolution.timeout,
          elapsedActiveMs: kRecallTimeoutSeconds * Duration.millisecondsPerSecond,
        );
      }
    });

    final revealed = timer.phase != RecallPhase.counting;
    return StudyShell(
      title: l10n.recallModeTitle,
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
              child: Center(
                child: MxText(card.term, role: MxTextRole.display),
              ),
            ),
          ),
          const MxGap.s5(),
          Expanded(
            child: MxCard(
              child: Center(
                child: revealed
                    ? _RevealedAnswer(
                        meaning: card.meaning,
                        timedOut: timer.phase == RecallPhase.timedOut,
                      )
                    : _RecallHint(text: l10n.recallHintBeforeReveal),
              ),
            ),
          ),
        ],
      ),
      bottomBar: _bottomBar(context, ref, l10n, timer),
    );
  }

  Widget? _bottomBar(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    RecallTimerState timer,
  ) {
    switch (timer.phase) {
      case RecallPhase.counting:
        return MxButton(
          icon: Symbols.visibility_rounded,
          label: l10n.recallShowLabel(timer.remainingSeconds),
          block: true,
          onPressed: () =>
              ref.read(recallTimerProvider(card.cardId).notifier).reveal(),
        );
      case RecallPhase.revealed:
        return Row(
          children: <Widget>[
            Expanded(
              child: MxButton(
                variant: MxButtonVariant.outline,
                label: l10n.recallForgotLabel,
                block: true,
                onPressed: () => _commit(
                  ref,
                  RecallResolution.forgot,
                  elapsedActiveMs: timer.elapsedActiveMs,
                ),
              ),
            ),
            const MxGap.s3(),
            Expanded(
              child: MxButton(
                label: l10n.recallGotItLabel,
                block: true,
                onPressed: () => _commit(
                  ref,
                  RecallResolution.remembered,
                  elapsedActiveMs: timer.elapsedActiveMs,
                ),
              ),
            ),
          ],
        );
      case RecallPhase.timedOut:
        // Auto-commit is in flight; the answer card shows the timeout feedback.
        return null;
    }
  }

  void _commit(
    WidgetRef ref,
    RecallResolution resolution, {
    required int elapsedActiveMs,
  }) {
    ref
        .read(studyAnswerViewmodelProvider.notifier)
        .answer(
          RecallInput(
            sessionId: runtime.session.id,
            cardId: card.cardId,
            roundIndex: runtime.position.roundIndex,
            eventId: 'recall-${card.cardId}-${resolution.name}',
            revealed: true,
            resolution: resolution,
            elapsedActiveMs: elapsedActiveMs,
          ),
        );
  }
}

class _RecallHint extends StatelessWidget {
  const _RecallHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxIcon(
          icon: Symbols.visibility_rounded,
          color: context.colors.textSecondary,
        ),
        const MxGap.s3(),
        Flexible(
          child: MxText(
            text,
            role: MxTextRole.body,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RevealedAnswer extends StatelessWidget {
  const _RevealedAnswer({required this.meaning, required this.timedOut});

  final String meaning;
  final bool timedOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxText(meaning, role: MxTextRole.title, textAlign: TextAlign.center),
        if (timedOut) ...<Widget>[
          const MxGap.s4(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MxIcon(icon: Symbols.timer_off_rounded, color: context.colors.error),
              const MxGap.s2(),
              MxText(
                AppLocalizations.of(context).recallTimeoutFeedback,
                role: MxTextRole.body,
                color: context.colors.error,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

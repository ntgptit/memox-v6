import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/match_board_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/match_flush_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/features/study/widgets/study_shell.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Match stage (WBS 5.6.6; `answer-study-stage.md`, SM-MATCH-v1, kit
/// `match-mode`). A two-column board pairs the round's terms with their
/// meanings: a correct pairing locks both tiles; a wrong/almost pairing is a
/// sticky lapse the learner retries. When every pair is locked the round
/// completes and `Next round` flushes the per-card outcomes to the session.
///
/// The board is ephemeral (it persists nothing); durable mid-board resume is
/// WBS 5.6.12. Template-only screen: the consumer child does the watch.
class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) => const _MatchView();
}

class _MatchView extends ConsumerWidget {
  const _MatchView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MxAsyncBuilder<StudyRuntimeState?>(
      value: ref.watch(studySessionRuntimeProvider),
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, runtime) {
        if (runtime == null || runtime.currentMode != StudyModeType.match) {
          return MxEmptyState(
            icon: Symbols.join_inner_rounded,
            title: l10n.reviewNoSessionMessage,
          );
        }
        return const _MatchStage();
      },
    );
  }
}

class _MatchStage extends ConsumerWidget {
  const _MatchStage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final board = ref.watch(matchBoardProvider);
    final flushState = ref.watch(matchFlushProvider);

    if (!board.isReady) {
      return MxEmptyState(
        icon: Symbols.join_inner_rounded,
        title: l10n.reviewNoSessionMessage,
      );
    }

    final total = board.pairCount;
    final done = board.lockedCount;
    final progress = total == 0 ? 0.0 : done / total;

    if (board.isComplete) {
      final flushing = flushState is AsyncLoading<void>;
      return StudyShell(
        title: l10n.matchModeTitle,
        progress: 1,
        progressCounter: '$total/$total',
        progressSemanticLabel: l10n.studyProgressLabel(total, total),
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.studyExitLabel,
        body: MxEmptyState(
          icon: Symbols.celebration_rounded,
          title: l10n.matchRoundCompleteTitle,
          body: l10n.matchRoundCompleteBody,
        ),
        bottomBar: MxButton(
          icon: Symbols.arrow_forward_rounded,
          label: l10n.matchNextRoundLabel,
          onPressed: flushing ? null : () => _flush(ref),
        ),
      );
    }

    return StudyShell(
      title: l10n.matchModeTitle,
      progress: progress,
      progressCounter: '$done/$total',
      progressSemanticLabel: l10n.studyProgressLabel(done, total),
      onBack: () => Navigator.of(context).maybePop(),
      backLabel: l10n.studyExitLabel,
      body: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _TermColumn(board: board)),
            const MxGap.s2(),
            Expanded(child: _MeaningColumn(board: board)),
          ],
        ),
      ),
    );
  }

  void _flush(WidgetRef ref) {
    final inputs = ref.read(matchBoardProvider.notifier).flushInputs();
    ref.read(matchFlushProvider.notifier).flush(inputs);
  }
}

class _TermColumn extends ConsumerWidget {
  const _TermColumn({required this.board});

  final MatchBoardState board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        for (final term in board.terms) ...<Widget>[
          _MatchTile(
            label: term.term,
            variant: _termVariant(board, term.cardId),
            feedbackIcon: _feedbackFor(
              context,
              board,
              isFlash: board.flashCardId == term.cardId,
            ),
            onTap: board.round.isLocked(term.cardId)
                ? null
                : () => ref
                      .read(matchBoardProvider.notifier)
                      .selectTerm(term.cardId),
          ),
          const MxGap.s2(),
        ],
      ],
    );
  }

  MxCardVariant _termVariant(MatchBoardState board, String cardId) {
    if (board.round.isLocked(cardId)) return MxCardVariant.primary;
    if (board.selectedTermId == cardId) return MxCardVariant.primarySoft;
    return MxCardVariant.flat;
  }
}

class _MeaningColumn extends ConsumerWidget {
  const _MeaningColumn({required this.board});

  final MatchBoardState board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        for (final meaning in board.meanings) ...<Widget>[
          _MatchTile(
            label: meaning.meaning,
            variant: board.round.isLocked(meaning.cardId)
                ? MxCardVariant.primary
                : MxCardVariant.flat,
            feedbackIcon: _feedbackFor(
              context,
              board,
              isFlash: board.flashMeaningId == meaning.cardId,
            ),
            onTap: board.round.isLocked(meaning.cardId)
                ? null
                : () => ref
                      .read(matchBoardProvider.notifier)
                      .selectMeaning(meaning.cardId),
          ),
          const MxGap.s2(),
        ],
      ],
    );
  }
}

/// The last-resolved pairing's tiles carry a transient outcome icon (no timer):
/// a wrong pick reads error, an `almost` (duplicate meaning) reads warning.
MxIcon? _feedbackFor(
  BuildContext context,
  MatchBoardState board, {
  required bool isFlash,
}) {
  if (!isFlash) return null;
  return switch (board.flashOutcome) {
    ModeOutcome.wrong => MxIcon(
      icon: Symbols.cancel_rounded,
      color: context.colors.error,
    ),
    ModeOutcome.almost => MxIcon(
      icon: Symbols.info_rounded,
      color: context.colors.warning,
    ),
    ModeOutcome.correct => MxIcon(
      icon: Symbols.check_circle_rounded,
      color: context.colors.success,
    ),
    _ => null,
  };
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.label,
    required this.variant,
    required this.feedbackIcon,
    required this.onTap,
  });

  final String label;
  final MxCardVariant variant;
  final MxIcon? feedbackIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MxCard(
      variant: variant,
      onTap: onTap,
      semanticLabel: label,
      child: Row(
        children: <Widget>[
          Expanded(child: MxText(label, role: MxTextRole.body, maxLines: 2)),
          ?feedbackIcon,
        ],
      ),
    );
  }
}

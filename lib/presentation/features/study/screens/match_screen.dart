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
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
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
        // Kit `match-mode/complete`: the round-complete frame is one
        // `EmptyState` carrying its own action, tone success. `Next round`
        // was a sticky `bottomBar` instead, which put it ~470 logical below
        // the copy it belongs to and gave the celebration a primary tile
        // rather than the success one the kit tones it.
        body: MxEmptyState(
          icon: Symbols.celebration_rounded,
          tone: MxIconTileTone.success,
          title: l10n.matchRoundCompleteTitle,
          body: l10n.matchRoundCompleteBody,
          action: MxButton(
            icon: Symbols.arrow_forward_rounded,
            label: l10n.matchNextRoundLabel,
            onPressed: flushing ? null : () => _flush(ref),
          ),
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
        // Meanings left, terms right — the kit's `MatchMode` fixes the sides
        // (`LEFT = ['time','love',…]`, `RIGHT = ['사랑','학교',…]`). The two
        // were reversed here, which no assertion caught: a matching board is
        // functionally symmetric, so only the shot says which side is which.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _MeaningColumn(board: board)),
            const MxGap.s2(),
            Expanded(child: _TermColumn(board: board)),
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
            cleared:
                board.round.isLocked(term.cardId) &&
                board.flashCardId != term.cardId,
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

  MxCardVariant _termVariant(MatchBoardState board, String cardId) =>
      _toneFor(board, cardId, isFlash: board.flashCardId == cardId) ??
      (board.selectedTermId == cardId
          ? MxCardVariant.primarySoft
          : MxCardVariant.flat);
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
            variant: _meaningVariant(board, meaning.cardId),
            feedbackIcon: _feedbackFor(
              context,
              board,
              isFlash: board.flashMeaningId == meaning.cardId,
            ),
            cleared:
                board.round.isLocked(meaning.cardId) &&
                board.flashMeaningId != meaning.cardId,
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

  /// Mirrors `_termVariant`: a meaning picked first reads selected, exactly as
  /// a term does. It previously had no selected state at all, because a
  /// meaning could not be picked first.
  MxCardVariant _meaningVariant(MatchBoardState board, String cardId) =>
      _toneFor(board, cardId, isFlash: board.flashMeaningId == cardId) ??
      (board.selectedMeaningId == cardId
          ? MxCardVariant.primarySoft
          : MxCardVariant.flat);
}

/// The kit's `Tile.jsx` TONE map: `correct` tints success-soft, `wrong` (and
/// `almost`, its near-miss sibling) tints error-soft, each with an emphasis
/// border in the matching role colour. Null means the tile carries no outcome
/// and the caller decides between selected and resting.
///
/// Only the flashing pair is toned. A locked tile that is no longer flashing
/// has left the board — see [_MatchTile], which hides it — so it never reaches
/// a colour at all.
MxCardVariant? _toneFor(
  MatchBoardState board,
  String cardId, {
  required bool isFlash,
}) {
  if (!isFlash) return null;
  return switch (board.flashOutcome) {
    ModeOutcome.correct => MxCardVariant.successSoft,
    ModeOutcome.wrong || ModeOutcome.almost => MxCardVariant.errorSoft,
    _ => null,
  };
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
    this.cleared = false,
  });

  final String label;
  final MxCardVariant variant;
  final MxIcon? feedbackIcon;
  final VoidCallback? onTap;

  /// A pair that has been resolved and is no longer flashing. The kit's tile
  /// renders `visibility: hidden` at full height once matched: the board keeps
  /// its shape while the solved pair stops competing for attention.
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    if (cleared) {
      return Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: _card(context),
      );
    }
    return _card(context);
  }

  Widget _card(BuildContext context) {
    return MxCard(
      variant: variant,
      // Kit `Tile.jsx`: `min-height: calc(size-xl + space-5)`. Without it the
      // tile shrank to its content and the board ended two-thirds down the
      // screen where the kit's fills it — 72 logical against the kit's 116,
      // measured off the shots.
      minHeight: MxCard.matchTileMinHeight,
      onTap: onTap,
      semanticLabel: label,
      // Kit `match-mode/components/Tile.jsx` centres its label on both axes.
      // The trailing feedback glyph is this build's addition, not the kit's:
      // WBS 5.6.6 requires non-colour cues, and the kit conveys correct/wrong
      // by tone alone. It sits outside the centred text so a tile without one
      // centres exactly.
      child: Row(
        children: <Widget>[
          Expanded(
            child: MxText(
              label,
              // Kit `Tile.jsx` sets the label base+bold. This rendered `body`
              // (base/regular) because no role carried the pairing — recorded
              // as `int-5` when `MX-VIS-063` was measured.
              role: MxTextRole.bodyStrong,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
          ?feedbackIcon,
        ],
      ),
    );
  }
}

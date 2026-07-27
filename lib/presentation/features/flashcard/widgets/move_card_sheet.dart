import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/domain/deck/card_target.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_lifecycle_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Card move-destination picker (WBS 6.5; `move-flashcard.md`). Lists every
/// deck in the card's pair, the ineligible ones disabled with the reason
/// (§5's decision table), and commits on tap. A duplicate term in the target
/// pauses on a review banner before anything is written (§1, §5); the store
/// still owns mixed-content and cross-pair, so a target that changed under the
/// sheet surfaces inline. The card keeps its id, content and progress.
Future<void> showMoveCardSheet(BuildContext context, {required String cardId}) {
  final l10n = AppLocalizations.of(context);
  return showMxSheet<void>(
    context,
    title: l10n.moveCardPickerTitle,
    child: _MoveCardPicker(cardId: cardId),
  );
}

class _MoveCardPicker extends ConsumerWidget {
  const _MoveCardPicker({required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final destinations = ref.watch(
      cardMoveDestinationsProvider(cardId: cardId),
    );
    final moveState = ref.watch(cardLifecycleCommandViewmodelProvider);
    final duplicates = ref.watch(moveCardDuplicatesViewmodelProvider);

    // §5 pauses a duplicate before commit, and a pause settles the action
    // state to data exactly like a commit does. Closing on that would have
    // announced "Card moved" over a card still in its old deck, so the sheet
    // closes on the committed-move tick instead.
    ref.listen<int>(moveCardMovedTickViewmodelProvider, (_, _) {
      // The source Leaf list is a stream; it drops the moved card. Close.
      showMxSnackbar(context, message: l10n.cardMovedMessage);
      Navigator.of(context).pop();
    });

    final isMoving = moveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(moveState);

    void moveTo(String targetDeckId, {bool allowDuplicate = false}) {
      if (isMoving) return;
      ref
          .read(cardLifecycleCommandViewmodelProvider.notifier)
          .moveCard(
            cardId: cardId,
            targetDeckId: targetDeckId,
            allowDuplicate: allowDuplicate,
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxAsyncBuilder<List<CardTarget>>(
          value: destinations,
          loadingLabel: l10n.loadingLabel,
          errorTitle: l10n.somethingWentWrongMessage,
          data: (context, decks) {
            // Every deck in the pair is listed now, blocked ones included, so
            // "nowhere to move this" is no longer an empty list — it is a list
            // with nothing tappable in it. Keyed off `isEmpty`, this guidance
            // had become unreachable and a learner whose only deck was the
            // card's own saw a lone disabled row and no explanation.
            final hasTarget = decks.any((target) => target.isEligible);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasTarget) ...[
                  MxText(
                    l10n.moveCardNoDestinationsBody,
                    role: MxTextRole.caption,
                  ),
                  const MxGap.s3(),
                ],
                // §3's ineligible branch is "Disabled · choose child" and §4
                // draws the Parent row present but disabled. Filtered out, a
                // Parent the learner was looking for simply was not there —
                // the same defect `int-89` fixed for the deck-move picker.
                for (final target in decks)
                  _CardTargetRow(
                    target: target,
                    onTap: target.isEligible
                        ? () => moveTo(target.deck.id)
                        : null,
                  ),
              ],
            );
          },
        ),
        // §5: a duplicate in the target is a decision, not an error — the card
        // stays put until the learner says keep both. The candidates are all in
        // the deck that was picked, so that deck is where the retry goes.
        if (duplicates != null && duplicates.isNotEmpty) ...[
          const MxGap.s3(),
          MxBanner.stacked(
            tone: MxBannerTone.warning,
            message: l10n.moveCardDuplicateMessage(duplicates.first.term),
            stackedActions: [
              MxButton(
                label: l10n.moveAnywayLabel,
                variant: MxButtonVariant.ghost,
                size: MxButtonSize.sm,
                onPressed: isMoving
                    ? null
                    : () =>
                          moveTo(duplicates.first.deckId, allowDuplicate: true),
              ),
            ],
          ),
        ],
        if (failure != null) ...[
          const MxGap.s3(),
          MxText(_moveFailureMessage(failure, l10n), role: MxTextRole.caption),
        ],
      ],
    );
  }
}

/// What a failed move says (`move-flashcard.md` §6, §7).
///
/// §6's copy is "Couldn't move the card. Nothing has changed." and the middle
/// sentence carries the weight: §7 rolls membership and both deck counts back
/// together, and this is the only place a learner is told so. The shared error
/// surface said something went wrong and left them wondering whether the card
/// had half-moved.
///
/// The structural rejections get their own lines. They arrive as typed
/// failures from the store, which is the point: the picker disables these
/// rows, so reaching one means the tree moved under the sheet.
String _moveFailureMessage(AppFailure failure, AppLocalizations l10n) {
  if (failure is ValidationFailure) return l10n.moveCardStaleTargetMessage;
  if (failure is! ConflictFailure) return l10n.moveCardFailedMessage;
  return switch (failure.code) {
    'cross-pair-move' => l10n.moveCardCrossPairMessage,
    'deck-mixed-content' => l10n.moveCardParentTargetMessage,
    _ => l10n.moveCardFailedMessage,
  };
}

/// One picker row: tappable when the deck can take the card, disabled with
/// the reason it cannot when it cannot (`add-content-to-deck.md` §4).
class _CardTargetRow extends StatelessWidget {
  const _CardTargetRow({required this.target, required this.onTap});

  final CardTarget target;

  /// `null` disables the row — `MxTappable` drops its states and its semantics
  /// action, so a blocked target reads as blocked to assistive tech too.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final helper = switch (target.ineligibility) {
      null => null,
      CardTargetIneligibility.isParent => l10n.cardTargetParentHelper,
      CardTargetIneligibility.sourceDeck => l10n.cardTargetSourceHelper,
    };
    return MxTappable(
      semanticLabel: helper == null
          ? target.deck.name
          : l10n.moveDeckBlockedSemantics(target.deck.name, helper),
      onTap: onTap,
      child: Row(
        children: [
          const MxGap.s3(),
          const MxIcon(icon: Symbols.folder),
          const MxGap.s4(),
          Expanded(child: MxText(target.deck.name, role: MxTextRole.body)),
          if (helper != null) ...[
            const MxGap.s3(),
            MxText(
              helper,
              role: MxTextRole.caption,
              color: context.colors.textSecondary,
            ),
          ],
          const MxGap.s3(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/move_deck_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Moves a nested deck up to the Library root (WBS 6.1; `move-deck.md` — the
/// Library-root destination). The deck keeps its id, content and progress; only
/// its parent changes.
///
/// This is the un-nest slice of Move; the full destination picker (choose an
/// arbitrary parent) is a follow-up — it needs a pair-wide deck list + per-deck
/// eligibility that do not exist yet (recorded in the run notes).
Future<void> showMoveToRootDialog(
  BuildContext context, {
  required String deckId,
  required String deckName,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxDialog<void>(
    context,
    title: l10n.moveDeckTitle(deckName),
    body: _MoveToRootBody(deckId: deckId),
    actions: const [],
  );
}

class _MoveToRootBody extends ConsumerWidget {
  const _MoveToRootBody({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final moveState = ref.watch(moveDeckDialogViewmodelProvider);

    listenMxAction(
      ref,
      moveDeckDialogViewmodelProvider,
      onSuccess: () {
        // The moved deck's context (now a root) refreshes in place; then close.
        ref.invalidate(deckDetailProvider(deckId: deckId));
        Navigator.of(context).pop();
      },
    );

    final isMoving = moveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(moveState);

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxText(l10n.moveDeckToRootBody, role: MxTextRole.body),
          if (failure != null) ...[
            const MxGap.s3(),
            MxText(
              MxActionErrors.messageOf(failure, l10n),
              role: MxTextRole.caption,
            ),
          ],
          const MxGap.s6(),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MxButton(
                label: l10n.cancelLabel,
                variant: MxButtonVariant.secondary,
                onPressed: isMoving ? null : () => Navigator.of(context).pop(),
              ),
              const MxGap.s2(),
              MxButton(
                label: l10n.moveDeckConfirmLabel,
                onPressed: isMoving
                    ? null
                    : () => ref
                          .read(moveDeckDialogViewmodelProvider.notifier)
                          .moveDeck(deckId: deckId, newParentId: null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

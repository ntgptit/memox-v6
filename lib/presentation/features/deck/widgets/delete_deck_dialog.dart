import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_deletion_impact.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_deletion_impact_provider.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/delete_deck_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The delete-deck confirm dialog (WBS 6.1; `delete-deck.md` §4, kit
/// `deck-settings--delete-confirm`). Destructive + irreversible: it shows the
/// scope the delete removes (nested decks / cards / progress) and offers the
/// safe `Keep deck` alongside the destructive `Delete deck`. On success it
/// navigates to the surviving Library context (the deck is gone).
Future<void> showDeleteDeckDialog(
  BuildContext context, {
  required String deckId,
  required String deckName,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxDialog<void>(
    context,
    title: l10n.deleteDeckTitle(deckName),
    body: _DeleteDeckBody(deckId: deckId),
    actions: const [],
  );
}

class _DeleteDeckBody extends ConsumerWidget {
  const _DeleteDeckBody({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final impact = ref
        .watch(deckDeletionImpactProvider(deckId: deckId))
        .asData
        ?.value;
    final deleteState = ref.watch(deleteDeckDialogViewmodelProvider);

    listenMxAction(
      ref,
      deleteDeckDialogViewmodelProvider,
      onSuccess: () {
        Navigator.of(context).pop();
        context.goLibrary();
      },
    );

    final isDeleting = deleteState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(deleteState);

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxText(
            impact == null ? l10n.loadingLabel : _impactText(impact, l10n),
            role: MxTextRole.body,
          ),
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
                label: l10n.deleteDeckKeepLabel,
                variant: MxButtonVariant.secondary,
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              const MxGap.s2(),
              MxButton(
                label: l10n.deleteDeckConfirmLabel,
                danger: true,
                // Only enabled once the impact is known and no delete is running.
                onPressed: (impact == null || isDeleting)
                    ? null
                    : () => ref
                          .read(deleteDeckDialogViewmodelProvider.notifier)
                          .deleteDeck(deckId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _impactText(DeckDeletionImpact impact, AppLocalizations l10n) {
    return switch (impact.state) {
      DeckContentState.empty => l10n.deleteDeckEmptyBody,
      DeckContentState.leaf => l10n.deleteDeckLeafBody(impact.cardCount),
      DeckContentState.parent => l10n.deleteDeckParentBody(
        impact.deckCount,
        impact.cardCount,
      ),
    };
  }
}

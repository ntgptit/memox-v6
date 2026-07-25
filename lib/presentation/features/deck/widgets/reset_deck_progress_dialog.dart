import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_deletion_impact.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_deletion_impact_provider.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/reset_deck_progress_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The reset-progress confirm dialog (WBS 6.1; `reset-deck-progress.md` §4). It
/// shows how many cards in the subtree would return to the unlearned state,
/// keeps content + hierarchy in place, and is irreversible. An empty scope shows
/// the "nothing to reset" state (§3) with no destructive action.
Future<void> showResetDeckProgressDialog(
  BuildContext context, {
  required String deckId,
  required String deckName,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxDialog<void>(
    context,
    title: l10n.resetDeckProgressTitle,
    body: _ResetProgressBody(deckId: deckId, deckName: deckName),
    actions: const [],
  );
}

class _ResetProgressBody extends ConsumerWidget {
  const _ResetProgressBody({required this.deckId, required this.deckName});

  final String deckId;
  final String deckName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final impact = ref
        .watch(deckDeletionImpactProvider(deckId: deckId))
        .asData
        ?.value;
    final resetState = ref.watch(resetDeckProgressDialogViewmodelProvider);

    listenMxAction(
      ref,
      resetDeckProgressDialogViewmodelProvider,
      onSuccess: () {
        ref.invalidate(deckDetailProvider(deckId: deckId));
        Navigator.of(context).pop();
      },
    );

    final isResetting = resetState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(resetState);
    final nothingToReset = impact != null && impact.cardCount == 0;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxText(
            impact == null ? l10n.loadingLabel : _bodyText(impact, l10n),
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
                label: nothingToReset
                    ? l10n.cancelLabel
                    : l10n.resetDeckProgressKeepLabel,
                variant: MxButtonVariant.secondary,
                onPressed: isResetting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              if (!nothingToReset) ...[
                const MxGap.s2(),
                MxButton(
                  label: l10n.resetDeckProgressConfirmLabel,
                  danger: true,
                  onPressed: (impact == null || isResetting)
                      ? null
                      : () => ref
                            .read(
                              resetDeckProgressDialogViewmodelProvider.notifier,
                            )
                            .resetDeckProgress(deckId),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _bodyText(DeckDeletionImpact impact, AppLocalizations l10n) {
    if (impact.cardCount == 0) return l10n.resetDeckProgressNothingBody;
    if (impact.state == DeckContentState.parent) {
      return l10n.resetDeckProgressParentBody(
        impact.cardCount,
        impact.deckCount,
        deckName,
      );
    }
    return l10n.resetDeckProgressBody(impact.cardCount, deckName);
  }
}

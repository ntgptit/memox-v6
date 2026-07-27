import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_deletion_impact.dart';
import 'package:memox_v6/domain/deck/reset_progress_availability.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_deletion_impact_provider.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/reset_deck_progress_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/reset_progress_availability_provider.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The reset-progress confirm dialog (WBS 6.1; `reset-deck-progress.md` §4). It
/// shows how many cards in the subtree would return to the unlearned state —
/// the ones carrying progress, which §5 calls the affected count — keeps
/// content + hierarchy in place, and is irreversible. A scope with no progress
/// shows the "nothing to reset" state (§3), and a scope a running session is
/// working through shows the blocked state (§5, §10) — neither offers the
/// destructive action.
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

    // A re-confirm settles the action state exactly like an applied reset, so
    // closing on that would announce "Deck progress reset" over a reset that
    // did not run. The applied tick is the only signal that means it did.
    ref.listen<int>(resetAppliedTickViewmodelProvider, (_, _) {
      ref.invalidate(deckDetailProvider(deckId: deckId));
      showMxSnackbar(context, message: l10n.deckProgressResetMessage);
      Navigator.of(context).pop();
    });
    final impactChanged = ref.watch(resetImpactChangedViewmodelProvider);

    final availability = ref
        .watch(resetProgressAvailabilityProvider(deckId: deckId))
        .asData
        ?.value;

    final isResetting = resetState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(resetState);

    // Three states carry no destructive action: still loading (§7), a session
    // running over the scope (§5), and nothing to reset — §3 branches on
    // "Has progress?", not on "has cards", so a deck of never-introduced
    // cards would otherwise offer an action that changes nothing.
    final offersReset =
        impact != null &&
        availability == ResetProgressAvailability.available &&
        impact.studiedCardCount > 0;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxText(_body(impact, availability, l10n), role: MxTextRole.body),
          // §11's "Impact changed" row: the learner is asked again over the
          // new number rather than having a scope they never agreed to reset.
          if (impactChanged) ...[
            const MxGap.s3(),
            MxText(l10n.resetDeckProgressChangedBody, role: MxTextRole.caption),
          ],
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
                label: offersReset
                    ? l10n.resetDeckProgressKeepLabel
                    : l10n.cancelLabel,
                variant: MxButtonVariant.secondary,
                onPressed: isResetting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              if (offersReset) ...[
                const MxGap.s2(),
                MxButton(
                  label: l10n.resetDeckProgressConfirmLabel,
                  danger: true,
                  onPressed: isResetting
                      ? null
                      : () => ref
                            .read(
                              resetDeckProgressDialogViewmodelProvider.notifier,
                            )
                            .resetDeckProgress(
                              deckId,
                              expectedAffectedCount: impact.studiedCardCount,
                            ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _body(
    DeckDeletionImpact? impact,
    ResetProgressAvailability? availability,
    AppLocalizations l10n,
  ) {
    if (impact == null || availability == null) return l10n.loadingLabel;
    if (availability == ResetProgressAvailability.blockedByActiveSession) {
      return l10n.resetDeckProgressBlockedBody;
    }
    return _bodyText(impact, l10n);
  }

  /// The impact summary §5 asks for: the affected count is *only* the cards
  /// carrying progress to reset, not every card in scope. The two differ for
  /// any deck the learner has partly studied, and naming the larger number
  /// promises to undo work that was never done.
  String _bodyText(DeckDeletionImpact impact, AppLocalizations l10n) {
    final affected = impact.studiedCardCount;
    if (affected == 0) return l10n.resetDeckProgressNothingBody;
    if (impact.state == DeckContentState.parent) {
      return l10n.resetDeckProgressParentBody(
        affected,
        impact.deckCount,
        deckName,
      );
    }
    return l10n.resetDeckProgressBody(affected, deckName);
  }
}

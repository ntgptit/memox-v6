import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/deck/move_destination.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/move_deck_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Move-destination picker (WBS 6.2; `move-deck.md`, kit `deck-settings--move`).
///
/// Lists the Library root plus every eligible destination deck (from
/// [deckMoveDestinationsProvider] — the moving deck's own subtree, card-holding
/// decks and the current parent are already excluded). Tapping a row commits
/// the move; the store still owns cycle / mixed-content / duplicate, so an
/// ineligible pick surfaces inline. The deck keeps its id, content and progress.
Future<void> showMoveDeckSheet(
  BuildContext context, {
  required String deckId,
  required String deckName,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxSheet<void>(
    context,
    title: l10n.moveDeckPickerTitle,
    child: _MoveDeckPicker(deckId: deckId),
  );
}

class _MoveDeckPicker extends ConsumerWidget {
  const _MoveDeckPicker({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final destinations = ref.watch(
      deckMoveDestinationsProvider(deckId: deckId),
    );
    final moveState = ref.watch(moveDeckDialogViewmodelProvider);

    listenMxAction(
      ref,
      moveDeckDialogViewmodelProvider,
      onSuccess: () {
        // The moved deck's parent context and breadcrumb refresh in place.
        ref.invalidate(deckDetailProvider(deckId: deckId));
        ref.invalidate(deckBreadcrumbProvider(deckId: deckId));
        showMxSnackbar(context, message: l10n.deckMovedMessage);
        Navigator.of(context).pop();
      },
    );

    final isMoving = moveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(moveState);

    void moveTo(String? newParentId) {
      if (isMoving) return;
      ref
          .read(moveDeckDialogViewmodelProvider.notifier)
          .moveDeck(deckId: deckId, newParentId: newParentId);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DestinationRow(
          icon: Symbols.home_rounded,
          label: l10n.moveToLibraryRootLabel,
          onTap: () => moveTo(null),
        ),
        MxAsyncBuilder<List<MoveDestination>>(
          value: destinations,
          loadingLabel: l10n.loadingLabel,
          errorTitle: l10n.somethingWentWrongMessage,
          data: (context, decks) => _DestinationList(
            decks: decks,
            l10n: l10n,
            onPick: (id) => moveTo(id),
          ),
        ),
        if (failure != null) ...[
          const MxGap.s3(),
          MxText(_moveFailureMessage(failure, l10n), role: MxTextRole.caption),
        ],
      ],
    );
  }
}

/// What a failed move says (`move-deck.md` §7, §8).
///
/// §8's copy is "Couldn't move the deck. Nothing has changed. Try again." and
/// the middle sentence is the one that matters: §1 promises the move is atomic
/// — never in both places, never lost from both — and this is where a learner
/// is told so. The shared error surface said only that something went wrong,
/// which leaves them wondering whether the deck half-moved.
///
/// §7 gives the structural rejections their own lines. They arrive as typed
/// conflicts from the store, which is deliberate: the picker filters these
/// destinations out, so reaching one means the tree changed under the sheet
/// and the reason is worth naming rather than flattening into "try again".
String _moveFailureMessage(AppFailure failure, AppLocalizations l10n) {
  if (failure is ValidationFailure) return l10n.moveDeckStaleTargetMessage;
  if (failure is! ConflictFailure) return l10n.moveDeckFailedMessage;
  return switch (failure.code) {
    'duplicate' => l10n.moveDeckDuplicateMessage,
    'deck-mixed-content' => l10n.moveDeckLeafTargetMessage,
    'deck-cycle' => l10n.moveDeckDescendantMessage,
    _ => l10n.moveDeckFailedMessage,
  };
}

class _DestinationList extends StatelessWidget {
  const _DestinationList({
    required this.decks,
    required this.l10n,
    required this.onPick,
  });

  final List<MoveDestination> decks;
  final AppLocalizations l10n;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (decks.isEmpty) {
      return MxText(l10n.moveDeckNoDestinationsBody, role: MxTextRole.caption);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // §3's ineligible branch is "Disabled + helper", not "hide", and §4
        // draws the blocked rows with their reason beside them. Filtered out,
        // a deck that holds cards and a deck that was never there looked the
        // same — absent — so a learner hunting for one could not tell which.
        for (final destination in decks)
          _DestinationRow(
            icon: Symbols.folder,
            label: destination.deck.name,
            helper: _helperFor(destination.ineligibility, l10n),
            onTap: destination.isEligible
                ? () => onPick(destination.deck.id)
                : null,
          ),
      ],
    );
  }

  /// §7's copy, shortened to the row labels §4 draws beside each blocked deck.
  static String? _helperFor(MoveIneligibility? reason, AppLocalizations l10n) =>
      switch (reason) {
        null => null,
        MoveIneligibility.self => l10n.moveDeckSelfHelper,
        MoveIneligibility.descendant => l10n.moveDeckDescendantHelper,
        MoveIneligibility.holdsCards => l10n.moveDeckHoldsCardsHelper,
        MoveIneligibility.alreadyThere => l10n.moveDeckAlreadyThereHelper,
      };
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.helper,
  });

  final IconData icon;
  final String label;

  /// `null` disables the row — `MxTappable` drops its states and its semantics
  /// action, so a blocked destination reads as blocked to assistive tech too.
  final VoidCallback? onTap;

  /// Why the row is disabled, shown beside it (§4).
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final helper = this.helper;
    return MxTappable(
      semanticLabel: helper == null
          ? label
          : AppLocalizations.of(
              context,
            ).moveDeckBlockedSemantics(label, helper),
      onTap: onTap,
      child: Row(
        children: [
          const MxGap.s3(),
          MxIcon(icon: icon),
          const MxGap.s4(),
          Expanded(child: MxText(label, role: MxTextRole.body)),
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

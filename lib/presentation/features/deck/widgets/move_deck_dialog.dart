import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/move_deck_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
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
        MxAsyncBuilder<List<Deck>>(
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
          MxText(
            MxActionErrors.messageOf(failure, l10n),
            role: MxTextRole.caption,
          ),
        ],
      ],
    );
  }
}

class _DestinationList extends StatelessWidget {
  const _DestinationList({
    required this.decks,
    required this.l10n,
    required this.onPick,
  });

  final List<Deck> decks;
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
        for (final deck in decks)
          _DestinationRow(
            icon: Symbols.folder,
            label: deck.name,
            onTap: () => onPick(deck.id),
          ),
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MxTappable(
      semanticLabel: label,
      onTap: onTap,
      child: Row(
        children: [
          const MxGap.s3(),
          MxIcon(icon: icon),
          const MxGap.s4(),
          Expanded(child: MxText(label, role: MxTextRole.body)),
          const MxGap.s3(),
        ],
      ),
    );
  }
}

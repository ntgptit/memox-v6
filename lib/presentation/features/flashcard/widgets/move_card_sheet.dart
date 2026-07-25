import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_lifecycle_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Card move-destination picker (WBS 6.5; `move-flashcard.md`). Lists the
/// Empty/Leaf decks the card can move into (from [cardMoveDestinationsProvider]
/// — Parents, the current deck and other pairs are already excluded). Tapping a
/// row commits the move; the store still owns mixed-content / cross-pair /
/// duplicate, so an ineligible pick surfaces inline. The card keeps its id,
/// content and progress.
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

    listenMxAction(
      ref,
      cardLifecycleCommandViewmodelProvider,
      onSuccess: () {
        // The source Leaf list is a stream; it drops the moved card. Close.
        Navigator.of(context).pop();
      },
    );

    final isMoving = moveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(moveState);

    void moveTo(String targetDeckId) {
      if (isMoving) return;
      ref
          .read(cardLifecycleCommandViewmodelProvider.notifier)
          .moveCard(cardId: cardId, targetDeckId: targetDeckId);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxAsyncBuilder<List<Deck>>(
          value: destinations,
          loadingLabel: l10n.loadingLabel,
          errorTitle: l10n.somethingWentWrongMessage,
          data: (context, decks) {
            if (decks.isEmpty) {
              return MxText(
                l10n.moveCardNoDestinationsBody,
                role: MxTextRole.caption,
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final deck in decks)
                  MxTappable(
                    semanticLabel: deck.name,
                    onTap: () => moveTo(deck.id),
                    child: Row(
                      children: [
                        const MxGap.s3(),
                        const MxIcon(icon: Symbols.folder),
                        const MxGap.s4(),
                        Expanded(
                          child: MxText(deck.name, role: MxTextRole.body),
                        ),
                        const MxGap.s3(),
                      ],
                    ),
                  ),
              ],
            );
          },
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

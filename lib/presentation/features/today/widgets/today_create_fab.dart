import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/today/add_card_target.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/widgets/create_deck_dialog.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_select_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_fab.dart';

/// Which entry of the create sheet was chosen (kit `dashboard/create-sheet`).
///
/// The kit lists a third, `Import cards`. It is not offered here: nothing in
/// this build imports anything — there is no import route, flow or use case —
/// and a menu row that opens nothing is worse than a menu that is honest
/// about what it can do.
enum _CreateAction { addCard, createDeck }

/// Today's create FAB and its action sheet
/// (`manage-today-create-actions.md`; kit `dashboard/add`).
///
/// The sheet owns no mutation (§6: "Sheet không trực tiếp persist
/// Deck/Card/Import"). It resolves which flow applies and hands off; the
/// owning flow keeps its own failures (§4).
class TodayCreateFab extends ConsumerWidget {
  const TodayCreateFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return MxFab(
      icon: Symbols.add_rounded,
      semanticLabel: l10n.todayCreateLabel,
      onPressed: () => _open(context, ref, l10n),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final action = await showMxSelectSheet<_CreateAction>(
      context,
      title: l10n.todayCreateSheetTitle,
      options: <MxSelectOption<_CreateAction>>[
        MxSelectOption<_CreateAction>(
          key: _CreateAction.addCard,
          icon: Symbols.note_add_rounded,
          label: l10n.todayCreateAddCardLabel,
        ),
        MxSelectOption<_CreateAction>(
          key: _CreateAction.createDeck,
          icon: Symbols.stacks_rounded,
          label: l10n.createDeckLabel,
        ),
      ],
    );

    // §6: "Dismiss không có side effect."
    if (action == null || !context.mounted) return;

    switch (action) {
      case _CreateAction.addCard:
        await _addCard(context, ref);
      case _CreateAction.createDeck:
        await showCreateDeckDialog(context);
        // §6: "Success refresh Today đúng một lần." A new deck changes the
        // Recent-decks section and can change the primary action, and the
        // dialog does not know that Today is behind it.
        ref.invalidate(todayProjectionProvider);
    }
  }

  /// §2 node C: the target is resolved *after* the action is chosen, not when
  /// the sheet opened — §4 says the sheet may use the last capability
  /// snapshot but the selected action revalidates.
  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    final target = await ref.read(resolveAddCardTargetUseCaseProvider).call();
    if (!context.mounted) return;

    switch (target) {
      case SingleAddCardTarget(:final deckId):
        context.pushNewCard(deckId);
      case ChooseAddCardTarget():
        // Node F. The kit picks the target on its own `add-card-target`
        // screen, which this build does not have; the Library is where a deck
        // is chosen today, and it leads to the same editor.
        context.goLibrary();
      case NoAddCardTarget():
        // Nothing can hold a card yet, so the guidance is the deck the
        // learner has to make first.
        await showCreateDeckDialog(context);
        ref.invalidate(todayProjectionProvider);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// A deck lifecycle action chosen from the settings sheet (WBS 6.1).
enum DeckSettingsAction { rename, move, resetProgress, delete }

/// The deck-settings action sheet (WBS 6.1; kit `deck-settings--action-sheet`).
/// Groups the deck lifecycle actions under one overflow so the app bar stays
/// uncluttered. Returns the chosen [DeckSettingsAction] (or null if dismissed);
/// the caller — which owns the deck — opens the matching dialog. [hasParent]
/// gates Move (only a nested deck can move to the Library root).
Future<DeckSettingsAction?> showDeckSettingsSheet(
  BuildContext context, {
  required bool hasParent,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxSheet<DeckSettingsAction>(
    context,
    title: l10n.deckSettingsLabel,
    child: _DeckSettingsBody(hasParent: hasParent),
  );
}

class _DeckSettingsBody extends StatelessWidget {
  const _DeckSettingsBody({required this.hasParent});

  final bool hasParent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ActionRow(
          icon: Symbols.edit_rounded,
          label: l10n.renameDeckLabel,
          action: DeckSettingsAction.rename,
        ),
        if (hasParent)
          _ActionRow(
            icon: Symbols.drive_file_move_rounded,
            label: l10n.moveDeckLabel,
            action: DeckSettingsAction.move,
          ),
        _ActionRow(
          icon: Symbols.restart_alt_rounded,
          label: l10n.resetDeckProgressLabel,
          action: DeckSettingsAction.resetProgress,
        ),
        _ActionRow(
          icon: Symbols.delete_rounded,
          label: l10n.deleteDeckLabel,
          action: DeckSettingsAction.delete,
          danger: true,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.action,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final DeckSettingsAction action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tint = danger ? context.colors.error : null;
    return MxTappable(
      semanticLabel: label,
      onTap: () => Navigator.of(context).pop(action),
      child: Row(
        children: <Widget>[
          const MxGap.s3(),
          MxIcon(icon: icon, color: tint),
          const MxGap.s4(),
          Expanded(
            child: MxText(label, role: MxTextRole.body, color: tint),
          ),
        ],
      ),
    );
  }
}

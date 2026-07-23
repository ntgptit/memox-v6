import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// A card lifecycle action chosen from the card-settings sheet (WBS 6.5).
enum CardSettingsAction { edit, toggleHidden, delete }

/// The card-settings action sheet (WBS 6.5; `hide-flashcard.md`,
/// `delete-flashcard.md`). Groups the card lifecycle actions off the Leaf card
/// row. Returns the chosen [CardSettingsAction] (or null if dismissed); the
/// caller opens the matching flow. [isHidden] flips the middle row between Hide
/// and Show.
Future<CardSettingsAction?> showCardSettingsSheet(
  BuildContext context, {
  required bool isHidden,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxSheet<CardSettingsAction>(
    context,
    title: l10n.cardOptionsLabel,
    child: _CardSettingsBody(isHidden: isHidden),
  );
}

class _CardSettingsBody extends StatelessWidget {
  const _CardSettingsBody({required this.isHidden});

  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ActionRow(
          icon: Symbols.edit_rounded,
          label: l10n.editCardLabel,
          action: CardSettingsAction.edit,
        ),
        _ActionRow(
          icon: isHidden
              ? Symbols.visibility_rounded
              : Symbols.visibility_off_rounded,
          label: isHidden ? l10n.showCardLabel : l10n.hideCardLabel,
          action: CardSettingsAction.toggleHidden,
        ),
        _ActionRow(
          icon: Symbols.delete_rounded,
          label: l10n.deleteCardLabel,
          action: CardSettingsAction.delete,
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
  final CardSettingsAction action;
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

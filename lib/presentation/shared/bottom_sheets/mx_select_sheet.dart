import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// One option of the select sheet.
final class MxSelectOption<K> {
  const MxSelectOption({
    required this.key,
    required this.icon,
    required this.label,
  });

  final K key;
  final IconData icon;
  final String label;
}

/// Presents the shared single-select composite (kit `_shared/SelectSheet`):
/// an uppercase title and a column of icon+label rows inside [showMxSheet],
/// with a primary-tinted check on the selected row. Owns the pattern the
/// mode-picker scope, library sort and settings value pickers share.
///
/// Returns the tapped option key, or `null` when dismissed.
Future<K?> showMxSelectSheet<K>(
  BuildContext context, {
  required String title,
  required List<MxSelectOption<K>> options,
  K? selected,
}) {
  return showMxSheet<K>(
    context,
    child: _MxSelectSheetBody<K>(
      title: title,
      options: options,
      selected: selected,
    ),
  );
}

class _MxSelectSheetBody<K> extends StatelessWidget {
  const _MxSelectSheetBody({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<MxSelectOption<K>> options;
  final K? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MxText(title, role: MxTextRole.overline),
        const MxGap.s3(),
        for (final option in options)
          MxTappable(
            onTap: () => Navigator.of(context).pop(option.key),
            semanticLabel: option.label,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: AppSpacing.space2,
                ),
                child: Row(
                  children: [
                    MxIcon(icon: option.icon, color: colors.textSecondary),
                    const MxGap.s3(),
                    Expanded(child: MxText(option.label)),
                    if (option.key == selected)
                      MxIcon(icon: Symbols.check_circle, color: colors.accent),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

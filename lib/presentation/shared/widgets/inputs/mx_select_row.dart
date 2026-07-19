import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_label.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// A read-only "select" field row (kit `SelectRow`): a section label
/// above an interactive surface showing the current value with a
/// trailing expand glyph. Tapping opens the caller's picker.
///
/// Purpose:
/// The one composition for tap-to-pick fields (language pickers,
/// deck pickers) so select fields look identical everywhere.
///
/// Use when:
/// A field whose value is chosen from a sheet/dialog, not typed.
///
/// Do not use when:
/// Free-text entry (`MxTextField`) or in-place option rows.
///
/// Category:
/// input
///
/// Public API:
/// - label: the section label above the row (kit `SectionLabel`).
/// - value: the current value (or placeholder) text.
/// - onTap: opens the picker; null renders the disabled surface.
/// - semanticLabel: announced for the tappable row (defaults to label).
class MxSelectRow extends StatelessWidget {
  const MxSelectRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final enabled = onTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MxSectionLabel(text: label),
        const MxGap.s2(),
        MxTappable(
          onTap: onTap,
          borderRadius: AppBorderRadii.control,
          semanticLabel: semanticLabel ?? label,
          child: Container(
            alignment: Alignment.centerLeft,
            constraints: const BoxConstraints(minHeight: AppSpacing.touchMin),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.space2,
              horizontal: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: enabled ? colors.surface : colors.surfaceSunken,
              borderRadius: AppBorderRadii.control,
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: styles.body.copyWith(
                      color: enabled ? colors.text : colors.textSecondary,
                    ),
                  ),
                ),
                if (enabled) ...[
                  const MxGap.s3(),
                  MxIcon(
                    icon: Symbols.expand_more_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

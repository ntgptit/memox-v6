import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';

/// Context pill (kit `flashcard-editor/deck-context` pattern): a
/// sunken pill anchoring which object a form acts on — a primary
/// glyph, a quiet role label and the bold object name.
///
/// Purpose:
/// One treatment for "this form belongs to X" context chips.
///
/// Use when:
/// A form/editor needs to anchor its target object.
///
/// Do not use when:
/// Status pills (`MxBadge`) or filter chips.
///
/// Category:
/// display
///
/// Public API:
/// - icon: the leading glyph (primary color).
/// - label: the quiet role word (e.g. "Deck"), localized by caller.
/// - value: the object name (bold).
class MxContextPill extends StatelessWidget {
  const MxContextPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space2,
        horizontal: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: AppBorderRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxIcon(icon: icon, color: colors.primary),
          const MxGap.s2(),
          Text(label, style: styles.body.copyWith(color: colors.textSecondary)),
          const MxGap.s2(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.body.copyWith(
                fontWeight: styles.boldWeight,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

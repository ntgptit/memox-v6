import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// A filter / choice chip (kit `MxChip`).
///
/// Purpose:
/// A compact pill that selects a filter or choice: outlined when idle,
/// primary-tinted when [selected], with an optional leading icon.
///
/// Use when:
/// Library/search filter and sort controls, or a small set of non-exclusive
/// choices.
///
/// Do not use when:
/// An on/off setting (`MxSwitch`), 2–3 mutually exclusive views
/// (`MxSegmentedControl`), or a primary action (`MxButton`).
///
/// Category:
/// input
///
/// Public API:
/// - label: one short word/phrase, single line.
/// - icon: optional leading glyph.
/// - selected: tinted (chosen) vs outlined (idle).
/// - onTap: chosen; null renders a static (non-interactive) chip.
///
/// States:
/// idle (outlined), selected (primary tint), with/without icon, pressed and
/// focus ring via [MxTappable].
class MxChip extends StatelessWidget {
  const MxChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = this.icon;
    final foreground = selected ? colors.onPrimarySoft : colors.text;

    return MxTappable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: AppBorderRadii.full,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colors.primarySoft : null,
          borderRadius: AppBorderRadii.full,
          border: selected
              ? null
              : Border.all(color: colors.border, width: AppStrokes.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                MxIcon(icon: icon, size: AppIconSizes.sm, color: foreground),
                const MxGap.s2(),
              ],
              MxText(label, role: MxTextRole.caption, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Tint pairs of the kit `Stat` chip.
enum MxStatTone { primary, accent, warning, success }

/// One flat metric: a tinted glyph chip, then the value over its label
/// (kit `Stat`).
///
/// Purpose:
/// A metric in a strip rather than in a card — the kit's way of showing
/// several numbers at once without turning each into its own surface.
///
/// Use when:
/// A row or grid of summary numbers (the dashboard's Today strip).
///
/// Do not use when:
/// The metric owns a whole card with its own action, or the number is a
/// status on another object (`MxBadge`).
///
/// Category:
/// display
///
/// Public API:
/// - icon: the `Symbols.*` glyph.
/// - tone: the chip's soft/on-soft pair.
/// - value: the number, already formatted and localized.
/// - label: what the number counts.
///
/// The chip is not `MxIconTile` despite the same 48-logical box: the kit's
/// Stat chip is `radius-control` (12) where the tile is `radius-tile` (16),
/// and their glyphs differ too. Reusing the tile would be visibly wrong.
///
/// The kit calls the anatomy fixed for every metric — only the tint varies —
/// so nothing else here is parameterized.
class MxStat extends StatelessWidget {
  const MxStat({
    super.key,
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final MxStatTone tone;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = switch (tone) {
      MxStatTone.primary => (colors.primarySoft, colors.onPrimarySoft),
      // The glyph sits on the soft tint, so it takes the bright accent rather
      // than on-accent, which is meant for a solid accent fill.
      MxStatTone.accent => (colors.accentSoft, colors.accent),
      MxStatTone.warning => (colors.warningSoft, colors.onWarningSoft),
      MxStatTone.success => (colors.successSoft, colors.onSuccessSoft),
    };

    return Row(
      children: <Widget>[
        Container(
          width: AppComponentDimensions.iconTileMd,
          height: AppComponentDimensions.iconTileMd,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppBorderRadii.control,
          ),
          // The kit sizes this glyph at `font-size-xl` (24) — off the icon
          // scale, which has no 24. `icon-size-md` (22) is the nearest token,
          // and reaching into the type scale for an icon is what
          // `memox.design_system.no_direct_color_typography_tokens` exists to
          // stop. The 2 logical is a deliberate residual.
          child: MxIcon(icon: icon, size: AppIconSizes.md, color: fg),
        ),
        const MxGap.s4(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Kit: `font-size-lg` at extrabold. `subtitle` is that size at
              // bold, the heaviest role the type scale carries.
              MxText(
                value,
                role: MxTextRole.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.space1),
              MxText(
                label,
                role: MxTextRole.caption,
                color: colors.textSecondary,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

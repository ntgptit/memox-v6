import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';

/// Tint tones of the kit `.icon-tile` contract.
enum MxIconTileTone { primary, accent, success, warning, error }

/// A soft rounded square holding one Material Symbol (kit `MxIconTile`).
///
/// Purpose:
/// The leading visual for deck rows and stat cards — one glyph on a soft
/// tonal tint (or the solid brand fill), sized by the component tokens.
///
/// Use when:
/// Decorative leading art on rows/cards.
///
/// Do not use when:
/// The tile should be a button (it is non-interactive), for user avatars
/// (`MxAvatar`) or for status/counts (`MxBadge`).
///
/// Category:
/// display
///
/// Public API:
/// - icon: the `Symbols.*` glyph.
/// - tone: primary/accent/success/warning/error soft tints.
/// - solid: strong primary fill (overrides tone).
/// - large: hero size (comp-icon-tile-lg, radius-lg, icon-xl).
/// - semanticLabel: optional; the tile is decorative (excluded from
///   semantics) unless a label is provided.
///
/// Variants:
/// See [MxIconTileTone] plus the `solid` and `large` flags.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    super.key,
    required this.icon,
    this.tone = MxIconTileTone.primary,
    this.solid = false,
    this.large = false,
    this.semanticLabel,
  });

  final IconData icon;
  final MxIconTileTone tone;
  final bool solid;
  final bool large;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (bg, fg) = solid
        ? (colors.primary, colors.onPrimary)
        : switch (tone) {
            MxIconTileTone.primary => (
              colors.primarySoft,
              colors.onPrimarySoft,
            ),
            // The glyph sits on the SOFT tint, so it uses the bright accent,
            // not on-accent (meant for a solid accent fill) — kit comment.
            MxIconTileTone.accent => (colors.accentSoft, colors.accent),
            MxIconTileTone.success => (
              colors.successSoft,
              colors.onSuccessSoft,
            ),
            MxIconTileTone.warning => (
              colors.warningSoft,
              colors.onWarningSoft,
            ),
            MxIconTileTone.error => (colors.errorSoft, colors.onErrorSoft),
          };

    final tile = Container(
      width: large
          ? AppComponentDimensions.iconTileLg
          : AppComponentDimensions.iconTileMd,
      height: large
          ? AppComponentDimensions.iconTileLg
          : AppComponentDimensions.iconTileMd,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: large ? AppBorderRadii.lg : AppBorderRadii.tile,
      ),
      child: MxIcon(
        icon: icon,
        size: large ? AppIconSizes.xl : AppIconSizes.lg,
        color: fg,
      ),
    );

    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: tile);
    return Semantics(label: label, child: tile);
  }
}

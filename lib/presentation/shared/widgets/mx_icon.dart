import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';

/// Icon glyph adapter for the kit's Material Symbols contract.
///
/// Purpose:
/// Renders a Material Symbols Rounded glyph at a token size with
/// theme-correct coloring, so feature code never sizes or colors icons
/// ad-hoc (kit contract in `AppIconSizes`; glyphs come from the
/// `material_symbols_icons` package's `Symbols.*`).
///
/// Use when:
/// Any standalone glyph in feature or shared surfaces.
///
/// Do not use when:
/// An owning `Mx*` component already places its own icon — buttons, tiles
/// and nav items apply the contract internally.
///
/// Category:
/// display
///
/// Public API:
/// - icon: a `Symbols.*` glyph (Material Symbols Rounded).
/// - size: token size from `AppIconSizes` (default md).
/// - color: overrides the default `colors.text`.
/// - semanticLabel: passthrough to [Icon].
class MxIcon extends StatelessWidget {
  const MxIcon({
    super.key,
    required this.icon,
    this.size = AppIconSizes.md,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? context.colors.text,
      semanticLabel: semanticLabel,
    );
  }
}

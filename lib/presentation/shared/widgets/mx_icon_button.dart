import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// Ground variants of the kit `.icon-btn` contract.
enum MxIconButtonVariant { transparent, filled, primary }

/// A round, icon-only action (kit `MxIconButton`).
///
/// Purpose:
/// The single icon-action surface — transparent by default, surface chip
/// or primary tint variants, always meeting the 48px target (the sm
/// visual keeps its 48px hit area).
///
/// Use when:
/// Icon-only actions: app-bar tools, row affordances, media controls.
///
/// Do not use when:
/// Primary text actions (`MxButton`), essential-label actions, or
/// navigation destinations (`MxBottomNav`).
///
/// Category:
/// button
///
/// Public API:
/// - icon: the `Symbols.*` glyph.
/// - onPressed: tap handler; `null` disables.
/// - semanticLabel: required localized action name (icon-only surfaces
///   always announce).
/// - variant: transparent/filled/primary grounds.
/// - small: 36px visual inside the 48px target.
/// - `MxIconButton.toolbar(...)`: the app-bar action preset (transparent,
///   small) required by guard
///   `memox.design_system.header_actions_use_toolbar_icon_buttons`.
///
/// States:
/// enabled, hovered/pressed/focused (via `MxTappable`), disabled.
///
/// Variants:
/// See [MxIconButtonVariant] and the `small` flag.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.variant = MxIconButtonVariant.transparent,
    this.small = false,
  });

  /// App-bar toolbar preset: quiet (transparent) and small, so normal
  /// Back/More actions stay visually quiet.
  const MxIconButton.toolbar({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  }) : variant = MxIconButtonVariant.transparent,
       small = true;

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final MxIconButtonVariant variant;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;

    final (bg, fg, shadows) = switch (variant) {
      MxIconButtonVariant.transparent => (
        colors.surface.withAlpha(0),
        colors.text,
        const <BoxShadow>[],
      ),
      MxIconButtonVariant.filled => (
        colors.surface,
        colors.text,
        elevations.shadowSm,
      ),
      MxIconButtonVariant.primary => (
        colors.primarySoft,
        colors.onPrimarySoft,
        const <BoxShadow>[],
      ),
    };

    final visual = small
        ? AppComponentDimensions.iconBtnSm
        : AppSpacing.touchMin;

    return MxTappable(
      onTap: onPressed,
      borderRadius: AppBorderRadii.full,
      semanticLabel: semanticLabel,
      child: Center(
        child: Container(
          width: visual,
          height: visual,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: shadows,
          ),
          child: ExcludeSemantics(
            child: MxIcon(icon: icon, color: fg),
          ),
        ),
      ),
    );
  }
}

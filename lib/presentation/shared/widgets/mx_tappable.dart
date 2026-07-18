import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';

/// Shared shaped tap primitive.
///
/// Purpose:
/// The single interactive surface for hover, pressed and focus treatment —
/// state layers come from the interaction-state tokens and the keyboard
/// focus ring composes the theme's `focus-ring` color at stroke-focus
/// width, so no widget hand-rolls `InkWell`/`GestureDetector` (guard
/// `memox.design_system.no_raw_ink_surface`; this file is its only
/// exclusion).
///
/// Use when:
/// Any tappable shape — rows, tiles, cards, custom controls — that is not
/// already an `Mx*` control with its own surface.
///
/// Do not use when:
/// An `Mx*` button/control exists for the interaction; never stack it
/// inside another tappable surface.
///
/// Category:
/// button
///
/// Public API:
/// - onTap: tap handler; `null` disables the surface.
/// - child: the shaped content.
/// - borderRadius: shape of state layers and ring (default control token).
/// - semanticLabel: optional button semantics wrapping the child.
/// - enforceMinTouchTarget: keeps the 48px accessibility minimum.
///
/// States:
/// enabled, hovered, pressed, focused (visible ring), disabled.
class MxTappable extends StatefulWidget {
  const MxTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.semanticLabel,
    this.enforceMinTouchTarget = true,
  });

  /// Tap handler; `null` disables the surface (no states, no semantics
  /// action).
  final VoidCallback? onTap;

  final Widget child;

  /// Shape of the state layers and focus ring; defaults to the control
  /// radius token.
  final BorderRadius? borderRadius;

  /// Optional button semantics label wrapping [child].
  final String? semanticLabel;

  /// Keeps the hit area at the 48px accessibility minimum (kit
  /// `touch-min`); disable only for dense list internals whose parent row
  /// already guarantees the target.
  final bool enforceMinTouchTarget;

  @override
  State<MxTappable> createState() => _MxTappableState();
}

class _MxTappableState extends State<MxTappable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = widget.borderRadius ?? AppBorderRadii.control;

    Widget surface = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.statePressed;
          }
          if (states.contains(WidgetState.hovered)) return colors.stateHover;
          if (states.contains(WidgetState.focused)) return colors.stateSelected;
          return null;
        }),
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: widget.child,
      ),
    );

    surface = AnimatedContainer(
      duration: AppMotion.durationFast,
      curve: AppMotion.easeStandard,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: _focused ? colors.focusRing : colors.focusRing.withAlpha(0),
          width: AppStrokes.focus,
        ),
      ),
      child: surface,
    );

    if (widget.enforceMinTouchTarget) {
      surface = ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchMin,
          minHeight: AppSpacing.touchMin,
        ),
        child: surface,
      );
    }

    if (widget.semanticLabel != null) {
      surface = Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: widget.onTap != null,
        child: surface,
      );
    }
    return surface;
  }
}

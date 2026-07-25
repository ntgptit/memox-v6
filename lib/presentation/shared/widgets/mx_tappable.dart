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
/// - pressedScale: kit `:active` press scale for controls that specify one
///   (`.btn` 0.97, `.fab` 0.94, `.icon-btn` 0.9); 1 leaves the surface
///   unscaled, which is the default for plain rows and tiles.
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
    this.pressedScale = 1,
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

  /// Kit `:active` press scale; 1 means the surface does not scale.
  final double pressedScale;

  @override
  State<MxTappable> createState() => _MxTappableState();
}

class _MxTappableState extends State<MxTappable> {
  bool _focused = false;
  bool _pressed = false;

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
        onHighlightChanged: widget.pressedScale == 1
            ? null
            : (pressed) => setState(() => _pressed = pressed),
        // Centred inside the enforced minimum. The touch-target constraint
        // below reaches the child unchanged — `Material` does not loosen it —
        // and a control shorter than 48 is simply stretched to 48 with its
        // content laid out against the *top* edge. A breadcrumb crumb sat ~14
        // logical above the separator and the page crumb beside it, which no
        // ratio caught because the row still occupies the same box.
        //
        // The factors keep the box shrink-wrapped: without them a `Center`
        // takes the whole cross-axis extent the parent offers.
        child: widget.enforceMinTouchTarget
            ? Center(widthFactor: 1, heightFactor: 1, child: widget.child)
            : widget.child,
      ),
    );

    if (widget.pressedScale != 1) {
      // Kit `:active { transform: scale(...) }` on the control surfaces.
      surface = AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AppMotion.durationFast,
        curve: AppMotion.easeStandard,
        child: surface,
      );
    }

    surface = AnimatedContainer(
      duration: AppMotion.durationFast,
      curve: AppMotion.easeStandard,
      // The ring paints over the child (kit: an outline ring), so it
      // never takes layout space around the interactive surface.
      foregroundDecoration: BoxDecoration(
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

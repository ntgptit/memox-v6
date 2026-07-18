import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// Emphasis variants of the kit `.btn` contract.
enum MxButtonVariant { primary, secondary, contrast, outline, ghost }

/// Size variants of the kit `.btn` contract.
enum MxButtonSize { sm, md, lg }

/// The standard text button (kit `MxButton` / `.btn`).
///
/// Purpose:
/// One button implementation for every emphasis level so screens never
/// hand-style pressable surfaces; colors, sizes, borders and states come
/// straight from the kit contract.
///
/// Use when:
/// Any in-flow action button, optionally with a leading icon.
///
/// Do not use when:
/// Navigation ("go somewhere" → `MxLink`), icon-only actions
/// (`MxIconButton`), or the screen's floating primary action (`MxFab`).
/// At most one primary button per screen.
///
/// Category:
/// button
///
/// Public API:
/// - onPressed: tap handler; `null` renders the disabled state.
/// - label: single-line localized label.
/// - variant: primary/secondary/contrast/outline/ghost (default primary).
/// - size: sm/md/lg (default md); sm keeps the 48px hit target around its
///   40px visual.
/// - danger: recolors to the error pair (destructive intent).
/// - block: fills the available width.
/// - icon: optional leading Material Symbols glyph at the subtitle size
///   (kit: buttons reuse font-size-lg for glyphs).
///
/// States:
/// enabled, hovered (kit hover fill), pressed/focused (via `MxTappable`
/// layers and ring), disabled (opacity-disabled, no pointer). No built-in
/// loading state by kit contract — the parent disables the button and
/// shows progress while submitting.
///
/// Variants:
/// See [MxButtonVariant], [MxButtonSize] and the `danger`/`block` flags.
class MxButton extends StatefulWidget {
  const MxButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.variant = MxButtonVariant.primary,
    this.size = MxButtonSize.md,
    this.danger = false,
    this.block = false,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String label;
  final MxButtonVariant variant;
  final MxButtonSize size;
  final bool danger;
  final bool block;
  final IconData? icon;

  @override
  State<MxButton> createState() => _MxButtonState();
}

class _MxButtonState extends State<MxButton> {
  bool _hovered = false;

  ({Color bg, Color fg, Color hoverBg, BorderSide? border}) _resolve(
    BuildContext context,
  ) {
    final colors = context.colors;
    if (widget.danger) {
      return (
        bg: colors.error,
        fg: colors.onError,
        hoverBg: colors.error,
        border: null,
      );
    }
    return switch (widget.variant) {
      MxButtonVariant.primary => (
        bg: colors.primary,
        fg: colors.onPrimary,
        hoverBg: colors.primaryStrong,
        border: null,
      ),
      MxButtonVariant.secondary => (
        bg: colors.primarySoft,
        fg: colors.onPrimarySoft,
        hoverBg: colors.stateSelected,
        border: null,
      ),
      MxButtonVariant.contrast => (
        bg: colors.onPrimary,
        fg: colors.primary,
        hoverBg: colors.onPrimary,
        border: null,
      ),
      MxButtonVariant.outline => (
        bg: colors.onPrimary.withAlpha(0),
        fg: colors.text,
        hoverBg: colors.stateHover,
        border: BorderSide(color: colors.borderStrong, width: AppStrokes.mid),
      ),
      MxButtonVariant.ghost => (
        bg: colors.onPrimary.withAlpha(0),
        fg: colors.accent,
        hoverBg: colors.stateHover,
        border: BorderSide(color: colors.border, width: AppStrokes.hairline),
      ),
    };
  }

  ({double height, double padX, TextStyle labelStyle}) _metrics(
    BuildContext context,
  ) {
    final styles = context.textStyles;
    return switch (widget.size) {
      MxButtonSize.sm => (
        height: AppSizes.sizeSm,
        padX: AppSpacing.space4,
        labelStyle: styles.buttonSm,
      ),
      MxButtonSize.md => (
        height: AppSpacing.touchMin,
        padX: AppSpacing.space6,
        labelStyle: styles.button,
      ),
      MxButtonSize.lg => (
        height: AppSizes.sizeMd,
        padX: AppSpacing.space7,
        labelStyle: styles.buttonLg,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolve(context);
    final metrics = _metrics(context);
    final enabled = widget.onPressed != null;
    final icon = widget.icon;
    final border = style.border;
    // Kit: button glyphs reuse font-size-lg == the subtitle role size.
    final iconSize = context.textStyles.subtitle.fontSize ?? AppSizes.sizeXs;

    final content = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          MxIcon(icon: icon, size: iconSize, color: style.fg),
          const MxGap.s2(),
        ],
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metrics.labelStyle.copyWith(color: style.fg),
        ),
      ],
    );

    // The fill paints via Ink so MxTappable's pressed/focused overlays stay
    // visible above it; the kit hover fill swaps through MouseRegion (the
    // 140ms CSS transition is below perception for a solid swap).
    Widget button = MxTappable(
      onTap: widget.onPressed,
      borderRadius: AppBorderRadii.control,
      semanticLabel: widget.label,
      child: ExcludeSemantics(
        child: Center(
          child: Ink(
            width: widget.block ? double.infinity : null,
            height: metrics.height,
            decoration: BoxDecoration(
              color: _hovered && enabled ? style.hoverBg : style.bg,
              borderRadius: AppBorderRadii.control,
              border: border == null ? null : Border.fromBorderSide(border),
            ),
            padding: EdgeInsets.symmetric(horizontal: metrics.padX),
            child: content,
          ),
        ),
      ),
    );

    button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: button,
    );

    if (!enabled) {
      button = Opacity(opacity: AppOpacities.opacityDisabled, child: button);
    }
    return button;
  }
}

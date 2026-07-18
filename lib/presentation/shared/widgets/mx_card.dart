import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// Surface variants of the kit `.card` contract.
enum MxCardVariant { elevated, flat, muted, primary, primarySoft }

/// Padding steps of the kit `.card` contract.
enum MxCardPadding { sm, md, lg }

/// The rounded content surface everything sits on (kit `MxCard`).
///
/// Purpose:
/// One card surface for every emphasis level — elevation, borders, brand
/// fills and press behavior come from the kit contract, and children
/// inherit the correct foreground color automatically.
///
/// Use when:
/// Grouping content on a rounded surface, optionally tappable as a whole
/// (`interactive` with `onTap`).
///
/// Do not use when:
/// Substituting a button (use `MxButton`) or nesting another interactive
/// control inside an interactive card — split into a non-interactive card
/// with explicit child controls (kit constraints matrix).
///
/// Category:
/// card
///
/// Public API:
/// - child: arbitrary content (wraps, never clips; content-driven height).
/// - variant: elevated/flat/muted/primary/primarySoft (default elevated).
/// - padding: sm/md/lg steps from the spacing tokens.
/// - onTap: whole-card tap; supplying it makes the card interactive
///   (hover lift, press scale, focus ring, button semantics).
/// - semanticLabel: button label for interactive cards.
///
/// States:
/// static variants; interactive adds hover (shadow-lg lift), pressed
/// (scale 0.985), focused ring and disabled-free tap semantics.
///
/// Variants:
/// See [MxCardVariant] and [MxCardPadding].
class MxCard extends StatefulWidget {
  const MxCard({
    super.key,
    required this.child,
    this.variant = MxCardVariant.elevated,
    this.padding = MxCardPadding.md,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final MxCardVariant variant;
  final MxCardPadding padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<MxCard> createState() => _MxCardState();
}

class _MxCardState extends State<MxCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final interactive = widget.onTap != null;

    final (bg, fg, shadows, border) = switch (widget.variant) {
      MxCardVariant.elevated => (
        colors.surface,
        colors.text,
        elevations.shadowCard,
        null,
      ),
      MxCardVariant.flat => (
        colors.surface,
        colors.text,
        const <BoxShadow>[],
        Border.all(color: colors.border, width: AppStrokes.hairline),
      ),
      MxCardVariant.muted => (
        colors.surfaceMuted,
        colors.text,
        const <BoxShadow>[],
        null,
      ),
      MxCardVariant.primary => (
        colors.primary,
        colors.onPrimary,
        elevations.shadowFab,
        null,
      ),
      MxCardVariant.primarySoft => (
        colors.primarySoft,
        colors.onPrimarySoft,
        const <BoxShadow>[],
        null,
      ),
    };

    final paddingValue = switch (widget.padding) {
      MxCardPadding.sm => AppSpacing.space4,
      MxCardPadding.md => AppSpacing.space6,
      MxCardPadding.lg => AppSpacing.space6,
    };

    final resolvedShadows = interactive && _hovered
        ? elevations.shadowLg
        : shadows;

    Widget surface = AnimatedContainer(
      duration: AppMotion.durationFast,
      curve: AppMotion.easeStandard,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadii.card,
        boxShadow: resolvedShadows,
        border: border,
      ),
      padding: EdgeInsets.all(paddingValue),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: fg),
        child: IconTheme.merge(
          data: IconThemeData(color: fg),
          child: widget.child,
        ),
      ),
    );

    if (!interactive) return surface;

    surface = AnimatedScale(
      // Kit press scale 0.985 with the fast/standard motion pair.
      scale: _pressed ? 0.985 : 1.0,
      duration: AppMotion.durationFast,
      curve: AppMotion.easeStandard,
      child: surface,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: MxTappable(
          onTap: widget.onTap,
          borderRadius: AppBorderRadii.card,
          semanticLabel: widget.semanticLabel,
          child: surface,
        ),
      ),
    );
  }
}

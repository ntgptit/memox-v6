import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/extensions/app_text_styles.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';

/// Tone grounds of the kit `.badge` contract.
enum MxBadgeTone { primary, success, warning, error }

/// Small status pill (kit `MxBadge` / `.badge`).
///
/// Purpose:
/// Compact count/status markers on cards and rows — "New", due counts —
/// with the kit pill geometry and xs/bold type.
///
/// Use when:
/// Annotating an item with a short status or count.
///
/// Do not use when:
/// Actions (`MxButton`/`MxLink`) or long copy (`MxBanner`).
///
/// Category:
/// display
///
/// Public API:
/// - label: the pill text (localized by the caller).
/// - tone: primary/success/warning/error grounds (kit `.badge--<tone>`).
/// - soft: kit `badge--soft` — tinted surface instead of the solid ground.
/// - leadingIcon: an optional glyph *before* the label, at the kit's
///   icon-size-sm with a space-1 gap. The kit's achievement badges pair a
///   symbol with their text so the meaning does not rest on colour alone
///   (KIT-08); the icon constructor replaces the text instead, which is a
///   different job.
/// - `MxBadge.icon(...)`: a glyph in place of the text, for the states the
///   kit marks with a symbol rather than a count (the up-to-date deck row's
///   check). Announced by `semanticLabel`, since a glyph reads as nothing.
///
/// Variants:
/// See [MxBadgeTone] plus the `soft` flag.
///
/// Layout note:
/// The pill centres its content, so under loose bounded constraints — a
/// `Column` child, an `Align`, a stretch cross-axis — it fills the width it
/// is offered instead of wrapping its label. Place it where the main axis is
/// unbounded (a `Row` child, including the deck row's trailing slot) or wrap
/// it in a min-size `Row`.
class MxBadge extends StatelessWidget {
  const MxBadge({
    super.key,
    required this.label,
    this.tone = MxBadgeTone.primary,
    this.soft = false,
    this.leadingIcon,
  }) : icon = null,
       semanticLabel = null;

  const MxBadge.icon({
    super.key,
    required IconData this.icon,
    required String this.semanticLabel,
    this.tone = MxBadgeTone.primary,
    this.soft = false,
  }) : label = '',
       leadingIcon = null;

  final String label;
  final MxBadgeTone tone;
  final bool soft;

  /// Non-null only for [MxBadge.icon].
  final IconData? icon;
  final String? semanticLabel;

  /// Optional glyph before [label]; ignored by [MxBadge.icon].
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    final (solidBg, solidFg, softBg, softFg) = switch (tone) {
      MxBadgeTone.primary => (
        colors.primary,
        colors.onPrimary,
        colors.primarySoft,
        colors.onPrimarySoft,
      ),
      MxBadgeTone.success => (
        colors.success,
        colors.onSuccess,
        colors.successSoft,
        colors.onSuccessSoft,
      ),
      MxBadgeTone.warning => (
        colors.warning,
        colors.onWarning,
        colors.warningSoft,
        colors.onWarningSoft,
      ),
      MxBadgeTone.error => (
        colors.error,
        colors.onError,
        colors.errorSoft,
        colors.onErrorSoft,
      ),
    };

    return Container(
      height: AppComponentDimensions.badgeHeight,
      constraints: const BoxConstraints(
        minWidth: AppComponentDimensions.badgeMinWidth,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppComponentDimensions.badgePadX,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: soft ? softBg : solidBg,
        borderRadius: AppBorderRadii.pill,
      ),
      child: icon == null
          ? _label(styles, soft ? softFg : solidFg)
          : Icon(
              icon,
              // The kit sizes this glyph at font-size-xs so it matches the
              // count it replaces rather than the icon scale.
              size: styles.overline.fontSize,
              color: soft ? softFg : solidFg,
              semanticLabel: semanticLabel,
            ),
    );
  }

  Widget _label(AppTextStyles styles, Color foreground) {
    final text = Text(
      label,
      style: styles.overline.copyWith(
        fontWeight: styles.boldWeight,
        letterSpacing: null,
        height: 1,
        color: foreground,
      ),
    );
    final leadingIcon = this.leadingIcon;
    if (leadingIcon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Kit: icon-size-sm with a space-1 gap before the text.
        Icon(leadingIcon, size: AppIconSizes.sm, color: foreground),
        const MxGap.s1(),
        text,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';

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
///
/// Variants:
/// See [MxBadgeTone] plus the `soft` flag.
class MxBadge extends StatelessWidget {
  const MxBadge({
    super.key,
    required this.label,
    this.tone = MxBadgeTone.primary,
    this.soft = false,
  });

  final String label;
  final MxBadgeTone tone;
  final bool soft;

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
      child: Text(
        label,
        style: styles.overline.copyWith(
          fontWeight: styles.boldWeight,
          letterSpacing: null,
          height: 1,
          color: soft ? softFg : solidFg,
        ),
      ),
    );
  }
}

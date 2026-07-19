import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';

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
/// - soft: kit `badge--soft` — tinted surface instead of solid primary.
class MxBadge extends StatelessWidget {
  const MxBadge({super.key, required this.label, this.soft = false});

  final String label;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

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
        color: soft ? colors.primarySoft : colors.primary,
        borderRadius: AppBorderRadii.pill,
      ),
      child: Text(
        label,
        style: styles.overline.copyWith(
          fontWeight: styles.boldWeight,
          letterSpacing: null,
          height: 1,
          color: soft ? colors.onPrimarySoft : colors.onPrimary,
        ),
      ),
    );
  }
}

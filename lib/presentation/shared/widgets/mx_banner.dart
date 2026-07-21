import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Tones of the kit `.banner` contract.
enum MxBannerTone { info, success, warning, error, accent }

/// The one inline tone banner (kit `MxBanner`).
///
/// Purpose:
/// A non-blocking message in the content column — tinted soft ground with
/// the paired on-soft foreground, a leading tone glyph, title + optional
/// body and an optional trailing action.
///
/// Use when:
/// Offline notices, save-failure notices with retry, success confirms
/// that must persist in place.
///
/// Do not use when:
/// A blocking decision (`MxDialog`) or progress (`MxProgress`).
///
/// Category:
/// feedback
///
/// Public API:
/// - tone: info/success/warning/error tint pairs.
/// - title: bold base-size headline.
/// - body: optional sm support copy.
/// - action: optional trailing control (retry link/button).
///
/// Variants:
/// See [MxBannerTone].
class MxBanner extends StatelessWidget {
  const MxBanner({
    super.key,
    required this.tone,
    this.title,
    this.body,
    this.action,
  }) : assert(
         title != null || body != null,
         'MxBanner needs a title, a body, or both',
       );

  final MxBannerTone tone;

  /// Optional, as in the kit: a banner carrying one short sentence uses
  /// [body] alone rather than shouting it in the title role.
  final String? title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final (bg, fg, icon) = switch (tone) {
      MxBannerTone.info => (colors.infoSoft, colors.onInfoSoft, Symbols.info),
      MxBannerTone.success => (
        colors.successSoft,
        colors.onSuccessSoft,
        Symbols.check_circle,
      ),
      MxBannerTone.warning => (
        colors.warningSoft,
        colors.onWarningSoft,
        Symbols.warning,
      ),
      MxBannerTone.error => (
        colors.errorSoft,
        colors.onErrorSoft,
        Symbols.error,
      ),
      // The celebratory brand tone the kit uses on the first-deck
      // ActionCallout; MxBanner shares the scale (kit tone contract).
      MxBannerTone.accent => (
        colors.accentSoft,
        colors.onAccentSoft,
        Symbols.celebration,
      ),
    };
    final title = this.title;
    final body = this.body;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: bg, borderRadius: AppBorderRadii.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MxIcon(icon: icon, color: fg),
          const MxGap.s3(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(title, style: styles.button.copyWith(color: fg)),
                if (body != null) ...[
                  if (title != null) const MxGap.s1(),
                  MxText(body, role: MxTextRole.caption, color: fg),
                ],
              ],
            ),
          ),
          if (action != null) ...[const MxGap.s3(), ?action],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart'
    show MxBannerTone;
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// A one-line tinted notice with an optional action (kit `ActionCallout`).
///
/// Purpose:
/// The compact in-flow notice screens actually use: a tone tile, one short
/// sentence and, when there is something to do about it, a single inline
/// action. Tighter than [MxBanner] and vertically centred, because it
/// carries a sentence rather than a titled block.
///
/// Use when:
/// A screen reports something in place — a failed submit, a restored
/// draft, an offline notice — and the message fits one line of `sm` text.
/// The kit composes this, not `.banner`, on every feature screen.
///
/// Do not use when:
/// The notice needs a title above its body (`MxBanner`), or it is a
/// transient confirmation (`MxSnackbar`).
///
/// Category:
/// feedback
///
/// Public API:
/// - tone: shares the kit's tone scale with [MxBanner] — the soft fill and
///   its on-color come from the same token pair.
/// - text: the sentence, at `sm`.
/// - icon: tone glyph; defaults to the tone's own.
/// - action: optional trailing control, e.g. an `MxLink`.
///
/// Variants:
/// See [MxBannerTone].
class MxActionCallout extends StatelessWidget {
  const MxActionCallout({
    super.key,
    required this.tone,
    required this.text,
    this.icon,
    this.action,
  });

  final MxBannerTone tone;
  final String text;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, toneIcon) = switch (tone) {
      MxBannerTone.info => (
        colors.infoSoft,
        colors.onInfoSoft,
        Symbols.info_rounded,
      ),
      MxBannerTone.success => (
        colors.successSoft,
        colors.onSuccessSoft,
        Symbols.check_circle_rounded,
      ),
      MxBannerTone.warning => (
        colors.warningSoft,
        colors.onWarningSoft,
        Symbols.warning_rounded,
      ),
      MxBannerTone.error => (
        colors.errorSoft,
        colors.onErrorSoft,
        Symbols.error_rounded,
      ),
    };
    final action = this.action;

    return Container(
      // Kit `ActionCallout`: s3/s4 padding on the control radius — tighter
      // than `.banner`'s s4 box, which is what keeps a one-line notice from
      // pushing the rest of the screen down.
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppBorderRadii.control,
      ),
      child: Row(
        children: [
          MxIcon(icon: icon ?? toneIcon, color: foreground),
          const MxGap.s3(),
          Expanded(
            child: MxText(text, role: MxTextRole.caption, color: foreground),
          ),
          if (action != null) ...[const MxGap.s3(), action],
        ],
      ),
    );
  }
}

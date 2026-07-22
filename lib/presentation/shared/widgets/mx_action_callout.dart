import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart'
    show MxBannerTone;
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// A soft-tinted in-flow notice with an optional action (kit `ActionCallout`).
///
/// Purpose:
/// The compact tonal notice screens actually use: a tone tile, a short
/// message and, when there is something to do about it, an action. Two kit
/// shapes: a centred single row for a one-line notice, and — when [title]
/// is set — a titled block whose action drops below the body.
///
/// Use when:
/// A screen reports something in place — a failed submit, a restored
/// draft, an offline notice, a first-run success — with a message and at
/// most one action. The kit composes this, not `.banner`, on feature screens.
///
/// Do not use when:
/// It is a blocking decision (`MxDialog`) or a transient confirmation
/// (`MxSnackbar`).
///
/// Category:
/// feedback
///
/// Public API:
/// - tone: shares the kit's tone scale with [MxBanner] — the soft fill and
///   its on-color come from the same token pair (`accent` is the kit's
///   celebratory first-run tone).
/// - text: the message, at `sm`.
/// - title: optional heading; switches to the titled (action-below) layout.
/// - icon: tone glyph; defaults to the tone's own.
/// - action: optional control (trailing on the single row, below the body
///   in the titled layout).
/// - onDismiss: optional trailing `×`; the parent owns the effect.
///
/// Variants:
/// See [MxBannerTone]; single-row vs titled by [title].
class MxActionCallout extends StatelessWidget {
  const MxActionCallout({
    super.key,
    required this.tone,
    required this.text,
    this.icon,
    this.title,
    this.action,
    this.onDismiss,
    this.dismissSemanticLabel,
  });

  final MxBannerTone tone;
  final String text;
  final IconData? icon;

  /// Optional heading above the body. Present it and the callout becomes the
  /// kit's titled variant: the action drops **below** the body instead of
  /// sitting inline, so a multi-line celebratory notice reads as a block.
  final String? title;
  final Widget? action;

  /// When set, a trailing dismiss (`×`) is shown; the parent owns what it
  /// does (e.g. hide the callout).
  final VoidCallback? onDismiss;
  final String? dismissSemanticLabel;

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
      MxBannerTone.accent => (
        colors.accentSoft,
        colors.onAccentSoft,
        Symbols.celebration_rounded,
      ),
    };
    final title = this.title;

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
      // `title` promotes to non-null in the titled branch, so the block
      // takes it as a plain String (no assertion).
      child: title == null
          ? _singleRow(context, foreground, toneIcon)
          : _titledBlock(context, foreground, toneIcon, title),
    );
  }

  /// No title → the kit's original centred single-row layout.
  Widget _singleRow(BuildContext context, Color foreground, IconData toneIcon) {
    final action = this.action;
    return Row(
      children: [
        MxIcon(icon: icon ?? toneIcon, color: foreground),
        const MxGap.s3(),
        Expanded(
          child: MxText(text, role: MxTextRole.caption, color: foreground),
        ),
        if (action != null) ...[const MxGap.s3(), action],
        ..._dismiss(foreground),
      ],
    );
  }

  /// Titled → heading above the body with the action on its own row below
  /// (kit `ActionCallout` titled variant; `create-deck.md` §7).
  Widget _titledBlock(
    BuildContext context,
    Color foreground,
    IconData toneIcon,
    String title,
  ) {
    final action = this.action;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MxIcon(icon: icon ?? toneIcon, color: foreground),
        const MxGap.s3(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              MxText(title, role: MxTextRole.subtitle, color: foreground),
              const MxGap.s1(),
              MxText(text, role: MxTextRole.caption, color: foreground),
              if (action != null) ...[const MxGap.s2(), action],
            ],
          ),
        ),
        ..._dismiss(foreground),
      ],
    );
  }

  List<Widget> _dismiss(Color foreground) {
    if (onDismiss == null) return const [];
    return [
      const MxGap.s2(),
      MxIconButton(
        icon: Symbols.close_rounded,
        small: true,
        semanticLabel: dismissSemanticLabel ?? '',
        onPressed: onDismiss,
      ),
    ];
  }
}

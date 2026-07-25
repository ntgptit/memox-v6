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
/// See [MxBannerTone] for tone, and [MxBanner.stacked] for the decision
/// layout.
class MxBanner extends StatelessWidget {
  const MxBanner({
    super.key,
    required this.tone,
    this.title,
    this.body,
    this.action,
  }) : stackedActions = null,
       assert(
         title != null || body != null,
         'MxBanner needs a title, a body, or both',
       );

  /// The decision layout: one regular-weight message, then a row of controls
  /// on its own line at the padding edge (kit
  /// `flashcard-editor/dup-warning`).
  ///
  /// A separate layout rather than a wide [action], because the two differ in
  /// more than arrangement: the message is body copy rather than a bold
  /// title, and the controls start at the container edge instead of indented
  /// past the glyph. The kit keeps this shape distinct for the same reason —
  /// its `ActionCallout` note calls the stacked two-button banner a different
  /// shape from the callout's trailing action.
  const MxBanner.stacked({
    super.key,
    required this.tone,
    required String message,
    required List<Widget> this.stackedActions,
  }) : title = null,
       body = message,
       action = null;

  final MxBannerTone tone;

  /// Optional, as in the kit: a banner carrying one short sentence uses
  /// [body] alone rather than shouting it in the title role.
  final String? title;
  final String? body;
  final Widget? action;

  /// Non-null only for [MxBanner.stacked].
  final List<Widget>? stackedActions;

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
    final stackedActions = this.stackedActions;

    // Both are non-null together by construction — `MxBanner.stacked` sets
    // the message as `body` — but reading them as a guarded pair keeps the
    // branch free of a non-null assertion.
    if (stackedActions != null && body != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppBorderRadii.control,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MxIcon(icon: icon, color: fg),
                const MxGap.s2(),
                Expanded(
                  child: MxText(body, role: MxTextRole.caption, color: fg),
                ),
              ],
            ),
            const MxGap.s3(),
            // `Align` is load-bearing: a banner is stretched by the column it
            // sits in, so a row of intrinsic-width controls centres itself in
            // the leftover space unless pinned to the edge.
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: stackedActions,
              ),
            ),
          ],
        ),
      );
    }

    // Kit `ActionCallout`: `padding: space-3 space-4`, `radius-control`. This
    // layout used `space-4` on all four sides and the card radius, making
    // every inline banner 8 logical taller than the kit's and rounding it
    // differently — found by row-band comparison on `MX-VIS-057`, where the
    // extra height pushed each band below the banner out of alignment. The
    // stacked layout above already had both right.
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadii.control,
      ),
      // Kit `ActionCallout` has two layouts, and which one applies is decided
      // by the title, not by the action:
      //
      // - untitled: one centered row, the action trailing the text.
      // - titled:   icon + a column of title / body / action, the action
      //             *inside* the column, below the body.
      //
      // Every titled banner used to take the untitled shape, so the action sat
      // beside the `Expanded` text and took its intrinsic width first. A wide
      // action then starved the message: the duplicate-card banner's two
      // buttons squeezed its text into a ~90px column that wrapped to one word
      // per line and grew the banner to four times its height.
      child: Row(
        crossAxisAlignment: title != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
                  // Kit `.banner__content` gap is space-05.
                  if (title != null) const MxGap.s05(),
                  MxText(body, role: MxTextRole.caption, color: fg),
                ],
                if (title != null && action != null) ...[
                  const MxGap.s2(),
                  ?action,
                ],
              ],
            ),
          ),
          if (title == null && action != null) ...[const MxGap.s3(), ?action],
        ],
      ),
    );
  }
}

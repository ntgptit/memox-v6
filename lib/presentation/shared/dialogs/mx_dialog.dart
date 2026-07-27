import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';

/// The one centered modal decision surface (kit `MxDialog`).
///
/// Purpose:
/// A single blocking decision — scrim over the app, a raised panel capped
/// at size-5xl with title (the accessible name), body and a right-aligned
/// action row. Content arrives by slot; no feature builds its own modal.
///
/// Use when:
/// Confirm, discard, rename — one decision at a time.
///
/// Do not use when:
/// Option sets or secondary content (`MxSheet`), non-blocking messages
/// (`MxBanner`).
///
/// Category:
/// dialog
///
/// Public API:
/// - title: the accessible dialog name.
/// - body: supporting content slot.
/// - actions: controls — right-aligned in the form layout, sharing one
///   full-width row in the icon layout (ghost cancel + primary/danger
///   confirm by convention).
/// - icon + tone: switch to the kit's icon `Dialog` layout, a centred
///   column with a tone tile above centred copy. The kit has two dialog
///   helpers and this build had only the form one, so every confirm
///   rendered its title above a bare glyph, left-aligned (`int-54`).
/// - `showMxDialog<T>(context, ...)`: presents over the token scrim and
///   returns the route result; barrier dismiss maps to `null`.
///
/// Variants:
/// form (default) and icon (pass [icon]).
///
/// States:
/// open, dismissed via barrier/Escape, action-resolved.
class MxDialog extends StatelessWidget {
  const MxDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.icon,
    this.tone = MxIconTileTone.primary,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  /// Present it and the panel takes the kit's icon `Dialog` layout.
  final IconData? icon;
  final MxIconTileTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.size5xl),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.spacing.gutter),
            padding: const EdgeInsets.all(AppSpacing.space6),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: AppBorderRadii.xxl,
              boxShadow: elevations.shadowLg,
            ),
            child: switch (icon) {
              null => _formLayout(context),
              final tile => _iconLayout(context, tile),
            },
          ),
        ),
      ),
    );
  }

  /// The kit's `FormDialog` shape: left-aligned copy over a right-aligned
  /// action row. Right for create/rename, which is what it was built for.
  Widget _formLayout(BuildContext context) {
    final styles = context.textStyles;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: styles.title.copyWith(color: colors.text)),
        const MxGap.s4(),
        DefaultTextStyle.merge(
          style: styles.body.copyWith(color: colors.text),
          child: body,
        ),
        const MxGap.s4(),
        // Wrap, not Row: on the 320-capped panel (and at 200% text
        // scale) the action pair wraps instead of overflowing — the
        // kit's documented dialog-action behavior.
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: actions,
          ),
        ),
      ],
    );
  }

  /// The kit's icon `Dialog`: a centred column — tone tile, the copy centred
  /// under it, then the actions sharing one full-width row.
  Widget _iconLayout(BuildContext context, IconData icon) {
    final styles = context.textStyles;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MxIconTile(icon: icon, tone: tone, large: true),
        const MxGap.s4(),
        Text(
          title,
          textAlign: TextAlign.center,
          style: styles.title.copyWith(color: colors.text),
        ),
        const MxGap.s2(),
        DefaultTextStyle.merge(
          style: styles.body.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
          child: body,
        ),
        const MxGap.s4(),
        // The kit's actions row is `flex-wrap: wrap`: the pair shares the row
        // when both fit and stacks when they do not. Expanded halves looked
        // right for `Back`/`Retry` and truncated the exit confirm's longer
        // pair to "Keep s…" / "Save a…" — natural widths wrap instead of
        // clipping, which is the behaviour the kit's CSS actually has.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.space3,
          runSpacing: AppSpacing.space3,
          children: actions,
        ),
      ],
    );
  }
}

/// Presents [MxDialog] over the token scrim; the route result is [T].
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required String title,
  required Widget body,
  required List<Widget> actions,
  IconData? icon,
  MxIconTileTone tone = MxIconTileTone.primary,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: context.colors.overlay,
    builder: (context) => MxDialog(
      title: title,
      body: body,
      actions: actions,
      icon: icon,
      tone: tone,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';

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
/// - actions: right-aligned controls (ghost cancel + primary/danger
///   confirm by convention).
/// - `showMxDialog<T>(context, ...)`: presents over the token scrim and
///   returns the route result; barrier dismiss maps to `null`.
///
/// States:
/// open, dismissed via barrier/Escape, action-resolved.
class MxDialog extends StatelessWidget {
  const MxDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final styles = context.textStyles;

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
            child: Column(
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
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents [MxDialog] over the token scrim; the route result is [T].
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required String title,
  required Widget body,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: context.colors.overlay,
    builder: (context) => MxDialog(title: title, body: body, actions: actions),
  );
}

import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';

/// Fraction of the screen the sheet may cover (kit: keep the top visible).
const double _sheetMaxHeightFraction = 0.88;

/// The one bottom sheet (kit `MxSheet`).
///
/// Purpose:
/// A surface rising from the bottom edge for option sets, short forms or
/// secondary content: scrim, drag handle, optional title and a
/// height-capped scrollable body honouring the bottom safe area.
///
/// Use when:
/// Card/deck action menus, pickers, short secondary flows.
///
/// Do not use when:
/// A single blocking decision (`MxDialog`) or a full screen.
///
/// Category:
/// dialog
///
/// Public API:
/// - title: optional sheet heading (section-title role).
/// - child: the sheet content (scrolls inside the 88% height cap).
/// - `showMxSheet<T>(context, ...)`: presents over the token scrim with
///   the raised ground and top 2xl radii; returns the route result.
///
/// States:
/// open, drag/barrier dismissed, action-resolved.
class MxSheet extends StatelessWidget {
  const MxSheet({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final title = this.title;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space6,
          AppSpacing.space6,
          AppSpacing.space6,
          AppSpacing.space2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSpacing.space9,
                height: AppSpacing.space1,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: AppBorderRadii.full,
                ),
              ),
            ),
            const MxGap.s4(),
            if (title != null) ...[
              Text(
                title,
                style: styles.sectionTitle.copyWith(color: colors.text),
              ),
              const MxGap.s3(),
            ],
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

/// Presents [MxSheet] over the token scrim; the route result is [T].
Future<T?> showMxSheet<T>(
  BuildContext context, {
  String? title,
  required Widget child,
}) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: colors.surfaceRaised,
    barrierColor: colors.overlay,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * _sheetMaxHeightFraction,
    ),
    shape: const RoundedRectangleBorder(borderRadius: AppBorderRadii.sheetTop),
    builder: (context) => MxSheet(title: title, child: child),
  );
}

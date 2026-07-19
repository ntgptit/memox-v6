import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';

/// The one progress indicator (kit `MxProgress`).
///
/// Purpose:
/// Ongoing-work feedback: a 4px linear bar (determinate or indeterminate)
/// or an inline spinner — track/fill straight from the tokens, always
/// announced.
///
/// Use when:
/// Imports, submissions, session progress. For a message use `MxBanner`;
/// for a blocking wait pair it inside `MxDialog`/`MxSheet`.
///
/// Category:
/// feedback
///
/// Public API:
/// - value: 0..1 fraction; omit for the indeterminate bar.
/// - `MxProgress.spinner(...)`: the inline rotating ring.
/// - semanticLabel: required localized announcement.
///
/// States:
/// determinate, indeterminate, spinner.
class MxProgress extends StatelessWidget {
  const MxProgress({super.key, this.value, required this.semanticLabel})
    : _spinner = false;

  const MxProgress.spinner({super.key, required this.semanticLabel})
    : value = null,
      _spinner = true;

  /// Progress fraction in `[0, 1]`; `null` renders indeterminate motion.
  final double? value;
  final String semanticLabel;
  final bool _spinner;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = this.value;

    if (_spinner) {
      return Semantics(
        label: semanticLabel,
        child: SizedBox(
          width: AppIconSizes.md,
          height: AppIconSizes.md,
          child: CircularProgressIndicator(
            strokeWidth: AppStrokes.emphasis,
            color: colors.primary,
            backgroundColor: colors.surfaceMuted,
          ),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppBorderRadii.full,
        child: LinearProgressIndicator(
          value: value,
          minHeight: AppSpacing.space1,
          color: colors.primary,
          backgroundColor: colors.surfaceMuted,
        ),
      ),
    );
  }
}

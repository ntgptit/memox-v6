import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';

/// Sticky form footer (kit `flashcard-editor` footer): the single
/// primary action zone pinned under the scrolling form, separated by a
/// top hairline so it reads as fixed chrome.
///
/// Purpose:
/// Keeps a form's Save (and its companions) one-thumb reachable while
/// the form scrolls independently.
///
/// Use when:
/// A form screen with a sticky primary action (paired with a
/// non-scrollable shell whose body scrolls its own content).
///
/// Do not use when:
/// Inline flows whose CTA belongs at the content end.
///
/// Category:
/// layout
///
/// Public API:
/// - children: stacked footer rows (toggle row, primary button).
class MxFormFooter extends StatelessWidget {
  const MxFormFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.only(
        top: AppSpacing.space4,
        bottom: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(
          top: BorderSide(color: colors.divider, width: AppStrokes.hairline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

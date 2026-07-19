import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// The primary screen action (kit `MxFab`).
///
/// Purpose:
/// One floating action per screen — extended with a label, or round when
/// icon-only — on the brand fill with the FAB shadow.
///
/// Use when:
/// The screen's single primary creation/start action.
///
/// Do not use when:
/// Secondary actions, more than one per screen, or destructive actions.
///
/// Category:
/// button
///
/// Public API:
/// - icon: the `Symbols.*` glyph.
/// - onPressed: tap handler.
/// - label: extended-FAB copy; omitting it with `round` gives the circular
///   icon-only form (`round` requires no label).
/// - semanticLabel: required when no visible label exists.
///
/// States:
/// extended / round; hovered/pressed/focused via `MxTappable`.
class MxFab extends StatelessWidget {
  const MxFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.semanticLabel,
  }) : assert(
         label != null || semanticLabel != null,
         'icon-only FABs must provide semanticLabel',
       );

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final styles = context.textStyles;
    final label = this.label;
    final round = label == null;

    return MxTappable(
      onTap: onPressed,
      borderRadius: round ? AppBorderRadii.full : AppBorderRadii.xl,
      semanticLabel: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Container(
          height: AppSpacing.fabSize,
          constraints: const BoxConstraints(minWidth: AppSpacing.fabSize),
          padding: round
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: round ? AppBorderRadii.full : AppBorderRadii.xl,
            boxShadow: elevations.shadowFab,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MxIcon(icon: icon, color: colors.onPrimary),
              if (label != null) ...[
                const MxGap.s2(),
                Text(
                  label,
                  maxLines: 1,
                  style: styles.button.copyWith(color: colors.onPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Full-screen empty/result state (kit `EmptyState` helper).
///
/// Purpose:
/// The one composition for "nothing here yet" and terminal-result
/// screens: a large tinted icon tile, a short title, supporting copy
/// and an optional action block, centered in the remaining space.
///
/// Use when:
/// A list or content surface has no content to show, or a flow ends in
/// a full-screen outcome.
///
/// Do not use when:
/// Inline notices inside content (`MxBanner`) or transient feedback.
///
/// Category:
/// feedback
///
/// Public API:
/// - icon: the tile glyph.
/// - title: short headline (kit: lg/extrabold/tight).
/// - body: supporting copy (base, secondary, normal line height).
/// - action: optional action block, constrained to the kit action
///   width (`--memox-size-3xl`).
/// - tone: tile tone (default primary).
class MxEmptyState extends StatelessWidget {
  const MxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.tone = MxIconTileTone.primary,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final MxIconTileTone tone;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final colors = context.colors;
    final body = this.body;
    final action = this.action;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space7,
          horizontal: AppSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxIconTile(icon: icon, tone: tone, large: true),
            const MxGap.s4(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.size3xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: styles.emptyStateTitle.copyWith(color: colors.text),
                  ),
                  if (body != null) ...[
                    const MxGap.s2(),
                    MxText(
                      body,
                      lineHeight: MxLineHeight.normal,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const MxGap.s4(),
              SizedBox(width: AppSizes.size3xl, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

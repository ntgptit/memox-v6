import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Kit action-column widths for [MxEmptyState.action].
enum MxEmptyStateActionWidth { standard, wide }

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
/// - action: optional action block, constrained to [actionWidth].
/// - actionWidth: standard (`--memox-size-3xl`) or wide
///   (`--memox-size-4xl`, full-screen deck actions).
/// - tone: tile tone (default primary).
/// - reserveNavZone: mirror of the kit `.app__body` bottom reservation
///   (bottom-nav-height + s6). Default true; screens that render a
///   real bottom nav pass false — the nav itself already owns the zone.
class MxEmptyState extends StatelessWidget {
  const MxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.actionWidth = MxEmptyStateActionWidth.standard,
    this.tone = MxIconTileTone.primary,
    this.reserveNavZone = true,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final MxEmptyStateActionWidth actionWidth;
  final MxIconTileTone tone;
  final bool reserveNavZone;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final colors = context.colors;
    final body = this.body;
    final action = this.action;

    // Kit note: proven at 200% font / short viewports — the state
    // scrolls rather than clipping, centering only when room allows.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              // The kit `.app__body` reserves the bottom-nav zone
              // (bottom-nav-height + s6) on every screen, so the centered
              // group sits above the geometric middle exactly as the shots do.
              padding: EdgeInsets.only(
                top: AppSpacing.space7,
                left: AppSpacing.space4,
                right: AppSpacing.space4,
                bottom: reserveNavZone
                    ? AppSpacing.space7 +
                          AppSpacing.bottomNavHeight +
                          AppSpacing.space6
                    : AppSpacing.space7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MxIconTile(icon: icon, tone: tone, large: true),
                  const MxGap.s4(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.size3xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: styles.emptyStateTitle.copyWith(
                            color: colors.text,
                          ),
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
                    SizedBox(
                      width: switch (actionWidth) {
                        MxEmptyStateActionWidth.standard => AppSizes.size3xl,
                        MxEmptyStateActionWidth.wide => AppSizes.size4xl,
                      },
                      child: action,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

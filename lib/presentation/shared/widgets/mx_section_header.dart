import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Labels a group of cards (kit `MxSectionHeader` / `.section-head`).
///
/// Purpose:
/// One header row above every card group — title (+ optional caption) on
/// the leading side, at most one tappable text action trailing, styled and
/// spaced by the kit contract.
///
/// Use when:
/// Introducing a group of cards/rows with an optional "See all"-style
/// action.
///
/// Do not use when:
/// As the top app bar (`MxContextualAppBar`), a card title, or above a
/// single item; never with multiple actions and never as a page-heading
/// landmark on its own.
///
/// Category:
/// layout
///
/// Public API:
/// - title: one-line group title (section-title role, may ellipsize).
/// - caption: optional short support copy at text-secondary.
/// - actionLabel: localized trailing action copy (also its semantics).
/// - onAction: tap/Enter/Space handler; the action renders only when both
///   label and handler are provided.
///
/// States:
/// title only, title+caption, with trailing action (hover/press/focus via
/// the shared tappable).
class MxSectionHeader extends StatelessWidget {
  const MxSectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? caption;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final caption = this.caption;
    final actionLabel = this.actionLabel;
    final showAction = actionLabel != null && onAction != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.sectionTitle.copyWith(color: colors.text),
              ),
              if (caption != null) ...[
                const MxGap.s05(),
                MxText(caption, role: MxTextRole.caption),
              ],
            ],
          ),
        ),
        if (showAction) ...[
          const MxGap.s3(),
          MxTappable(
            onTap: onAction,
            semanticLabel: actionLabel,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space1,
              ),
              child: ExcludeSemantics(
                child: Text(
                  actionLabel,
                  maxLines: 1,
                  style: styles.button.copyWith(color: colors.accent),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

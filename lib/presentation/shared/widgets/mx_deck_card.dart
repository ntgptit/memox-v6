import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';

/// One deck row card (kit shared `DeckCard`): tinted icon tile, bold
/// title, secondary meta line and an optional trailing slot.
///
/// Purpose:
/// The single deck-list row treatment at every library level, so deck
/// rows read identically on root, nested and search surfaces.
///
/// Use when:
/// Rendering a deck in any list.
///
/// Do not use when:
/// Non-deck rows (`MxList` + custom rows) or full detail headers.
///
/// Category:
/// card
///
/// Public API:
/// - icon: the tile glyph (kit default deck glyph: `style`).
/// - tone: tile tone (kit default: accent).
/// - title: deck name (base/bold, clamps to 2 lines).
/// - meta: secondary line (counts, single line).
/// - status / statusTone: optional coloured study status appended to the
///   meta line (kit deck-card meta: `N cards · 48 due`), toned due /
///   new / up-to-date.
/// - trailing: optional trailing widget (badge, action).
/// - onTap: opens the deck.
class MxDeckCard extends StatelessWidget {
  const MxDeckCard({
    super.key,
    required this.icon,
    this.tone = MxIconTileTone.accent,
    required this.title,
    required this.meta,
    this.status,
    this.statusTone,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final MxIconTileTone tone;
  final String title;
  final String meta;
  final String? status;
  final MxDeckStatusTone? statusTone;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final trailing = this.trailing;
    final status = this.status;
    final secondary = styles.caption.copyWith(color: colors.textSecondary);
    final statusColor = switch (statusTone) {
      MxDeckStatusTone.due => colors.warning,
      MxDeckStatusTone.isNew => colors.accent,
      MxDeckStatusTone.upToDate || null => colors.success,
    };

    return MxCard(
      padding: MxCardPadding.sm,
      onTap: onTap,
      semanticLabel: title,
      child: Row(
        children: [
          MxIconTile(icon: icon, tone: tone),
          const MxGap.s4(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: styles.body.copyWith(
                    fontWeight: styles.boldWeight,
                    color: colors.text,
                  ),
                ),
                const MxGap.s1(),
                Text.rich(
                  TextSpan(
                    style: secondary,
                    children: [
                      TextSpan(text: meta),
                      if (status != null) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: status,
                          style: secondary.copyWith(
                            color: statusColor,
                            fontWeight: styles.boldWeight,
                          ),
                        ),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const MxGap.s4(), trailing],
        ],
      ),
    );
  }
}

/// The study status colour on a deck card's meta line: overdue reviews
/// (warning), unstudied cards (accent), or all-caught-up (success).
enum MxDeckStatusTone { due, isNew, upToDate }

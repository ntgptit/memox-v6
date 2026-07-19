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
/// - meta: secondary line (counts/status, single line).
/// - trailing: optional trailing widget (badge, action).
/// - onTap: opens the deck.
class MxDeckCard extends StatelessWidget {
  const MxDeckCard({
    super.key,
    required this.icon,
    this.tone = MxIconTileTone.accent,
    required this.title,
    required this.meta,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final MxIconTileTone tone;
  final String title;
  final String meta;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final trailing = this.trailing;

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
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.caption.copyWith(color: colors.textSecondary),
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

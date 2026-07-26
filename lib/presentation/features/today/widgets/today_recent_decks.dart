import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_summary_row.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_badge.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_list.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_header.dart';

/// Today's Recent-decks section (kit `dashboard/decks`).
///
/// The same [DeckSummaryRow] the Library renders, with the two things the kit
/// adds only here: the mastery bar and a trailing due badge. Sharing the row
/// is the point — the kit's note on `DeckCard` says it was standardized *from*
/// this section so the two screens cannot drift.
///
/// No right-aligned "See all" beside the header: the FAB floats bottom-right
/// and must not sit over another control, so the link closes the list instead
/// (kit comment on `dashboard/decks-head`).
class TodayRecentDecks extends StatelessWidget {
  const TodayRecentDecks({
    super.key,
    required this.decks,
    required this.onOpenDeck,
    required this.onSeeAll,
  });

  final List<DeckSummary> decks;
  final void Function(DeckSummary deck) onOpenDeck;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxSectionHeader(title: l10n.todayRecentDecksTitle),
        const MxGap.s3(),
        MxList(
          children: <Widget>[
            for (final summary in decks)
              DeckSummaryRow(
                summary: summary,
                showMastery: true,
                trailing: summary.dueCount > 0
                    ? MxBadge(label: l10n.deckDueBadgeLabel(summary.dueCount))
                    // The kit marks a deck with nothing due with a check
                    // rather than a zero: a "0" in a due-count badge reads as
                    // a count that failed to load.
                    : MxBadge.icon(
                        icon: Symbols.check_rounded,
                        semanticLabel: l10n.deckUpToDateLabel,
                        tone: MxBadgeTone.success,
                        soft: true,
                      ),
                onTap: () => onOpenDeck(summary),
              ),
          ],
        ),
        const MxGap.s3(),
        Align(
          alignment: Alignment.center,
          child: MxLink(label: l10n.todaySeeAllDecksLabel, onTap: onSeeAll),
        ),
      ],
    );
  }
}

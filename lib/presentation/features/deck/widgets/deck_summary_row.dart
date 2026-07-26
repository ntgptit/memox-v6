import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_quick_study_action.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_deck_card.dart';

/// One deck row on a list surface — the kit's shared `DeckCard`.
///
/// The Library root, the deck-detail Parent branch and Today's Recent-decks
/// section show the same card for the same thing, so the status rule lives
/// here once instead of being restated per screen. It was private to the
/// Library screen until the Parent branch needed it too.
class DeckSummaryRow extends StatelessWidget {
  const DeckSummaryRow({
    super.key,
    required this.summary,
    required this.onTap,
    this.trailing,
    this.showMastery = false,
  });

  final DeckSummary summary;

  /// Replaces the kit's default list-surface trailing — the quick-study bolt
  /// — for surfaces the kit gives a different one. Today's rows carry a due
  /// badge instead, because Today already has exactly one primary action and
  /// a per-row start would be a second.
  final Widget? trailing;

  /// Draws the mastery bar under the meta line. The kit passes deck progress
  /// on the Dashboard only; Library rows omit it.
  final bool showMastery;

  /// How opening this deck navigates. The Library root replaces the route
  /// and the Parent branch pushes onto it, so that a nested deck can be
  /// backed out of into its parent rather than out to the Library — the
  /// row itself must not decide.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Kit deck-card status: due outranks new outranks up-to-date, and a
    // deck with no cards shows only its count.
    final (status, statusTone) = switch (summary) {
      _ when summary.dueCount > 0 => (
        l10n.cardsDueLabel(summary.dueCount),
        MxDeckStatusTone.due,
      ),
      _ when summary.newCount > 0 => (
        l10n.cardsNewLabel(summary.newCount),
        MxDeckStatusTone.isNew,
      ),
      _ when summary.cardCount > 0 => (
        l10n.deckUpToDateLabel,
        MxDeckStatusTone.upToDate,
      ),
      _ => (null, null),
    };

    // Kit shared DeckCard: default deck glyph `style`, accent tile,
    // "N cards" meta with the toned study status.
    return MxDeckCard(
      icon: Symbols.style_rounded,
      title: summary.deck.name,
      meta: l10n.cardsCountLabel(summary.cardCount),
      status: status,
      statusTone: statusTone,
      progress: showMastery ? summary.masteryFraction : null,
      progressSemanticLabel: showMastery
          ? l10n.deckMasteryLabel(summary.masteredCount, summary.studiableCount)
          : null,
      // Kit deck row: a bolt that starts a session for this deck without
      // opening it. The screen showing these rows mounts
      // `listenForQuickStudyStart` once so the start navigates.
      //
      // A nested control turns the row from a leaf semantics node into a
      // parent one, which moves its accessible name from text content onto
      // `aria-label`. Anything locating a deck row must therefore match on
      // the accessible name, not on rendered text.
      trailing: trailing ?? DeckQuickStudyAction(deckId: summary.deck.id),
      onTap: onTap,
    );
  }
}

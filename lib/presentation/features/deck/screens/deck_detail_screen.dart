import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_list.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_summary_row.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/widgets/create_deck_dialog.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_failure_states.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_list_controls.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/library_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_loading_skeletons.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_quick_study_action.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_settings_sheet.dart';
import 'package:memox_v6/presentation/features/deck/widgets/delete_deck_dialog.dart';
import 'package:memox_v6/presentation/features/deck/widgets/move_deck_dialog.dart';
import 'package:memox_v6/presentation/features/deck/widgets/rename_deck_dialog.dart';
import 'package:memox_v6/presentation/features/deck/widgets/reset_deck_progress_dialog.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_lifecycle_viewmodel.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/card_settings_sheet.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/move_card_sheet.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_confirm_dialog.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_breadcrumb.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_fab.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Open Deck (WBS 5.2.4B; `open-deck.md`): Empty/Leaf/Parent derived
/// from the reactive content streams — transitions update in place and
/// nothing keeps a stored mode.
class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // guard:allow-screen-watch -- reason: the kit nested app bar carries
    // the watched deck's name as its title (empty-deck/appbar).
    final l10n = AppLocalizations.of(context);
    final deck = ref.watch(deckDetailProvider(deckId: deckId));

    return MxScaffold(
      appBar: MxContextualAppBar(
        title: deck.value?.name ?? '',
        onBack: () => context.backFromDeck(),
        backLabel: l10n.backLabel,
        actions: <Widget>[
          // The kit's not-found bar carries no actions — there is nothing
          // left to search or configure once the deck is gone.
          if (deck.value != null) ...<Widget>[
            // Kit `subdeck-list`/`flashcard-list` app bar: search sits left of
            // the overflow. It opens the same library-wide search the Library
            // root does — narrowing to this deck is the Deck picker inside
            // search's own filter sheet (`filter-search-results.md` §3), which
            // is not built, so the label stays unscoped rather than promising
            // a scope the screen cannot deliver.
            MxIconButton.toolbar(
              icon: Symbols.search_rounded,
              semanticLabel: l10n.searchLabel,
              onPressed: () => context.pushSearch(),
            ),
            if (deck.value case final d?)
              MxIconButton.toolbar(
                icon: Symbols.more_vert_rounded,
                semanticLabel: l10n.deckSettingsLabel,
                onPressed: () => _openDeckSettings(context, d),
              ),
          ],
        ],
      ),
      scrollable: false,
      fab: _CreateNestedDeckFab(deckId: deckId),
      body: _DeckDetailBody(deckId: deckId),
    );
  }
}

/// Opens the deck-settings sheet, then the dialog for the chosen lifecycle
/// action (WBS 6.1). The deck is captured from the app bar's watched value, so
/// each dialog gets the current id + name.
Future<void> _openDeckSettings(BuildContext context, Deck deck) async {
  final action = await showDeckSettingsSheet(
    context,
    hasParent: deck.parentId != null,
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case DeckSettingsAction.rename:
      await showRenameDeckDialog(
        context,
        deckId: deck.id,
        currentName: deck.name,
      );
    case DeckSettingsAction.move:
      await showMoveDeckSheet(context, deckId: deck.id, deckName: deck.name);
    case DeckSettingsAction.resetProgress:
      await showResetDeckProgressDialog(
        context,
        deckId: deck.id,
        deckName: deck.name,
      );
    case DeckSettingsAction.delete:
      await showDeleteDeckDialog(context, deckId: deck.id, deckName: deck.name);
  }
}

class _DeckDetailBody extends ConsumerWidget {
  const _DeckDetailBody({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deck = ref.watch(deckDetailProvider(deckId: deckId));

    // Mounted once for the screen. The deck-level Study CTA used to host
    // this listener; with it gone the row bolts still need somewhere for
    // their success to navigate from, and it must not be per row.
    listenForQuickStudyStart(ref, context);

    return MxAsyncBuilder<Deck?>(
      value: deck,
      // The very first frame is a skeleton too, not a spinner. Opening a
      // deck from a list otherwise flashes a centred spinner for one frame
      // and then swaps to placeholder rows — two different loading
      // treatments for one navigation. The deck-row shape is the right
      // stand-in here because the branch is not known until its content
      // resolves, which is the same reason the child stream uses it.
      loading: (context) => const DeckRowsSkeleton(),
      error: (context, failure) => DeckLoadErrorState(
        title: l10n.deckLoadErrorTitle,
        onRetry: () => ref.invalidate(deckDetailProvider(deckId: deckId)),
      ),
      data: (context, value) => value == null
          ? DeckNotFoundState(l10n: l10n)
          : _DeckContent(deck: value),
    );
  }
}

class _DeckContent extends ConsumerWidget {
  const _DeckContent({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final children = ref.watch(deckChildrenProvider(deckId: deck.id));
    final cards = ref.watch(deckCardsProvider(deckId: deck.id));

    return MxAsyncBuilder<List<Deck>>(
      value: children,
      // The branch is not known yet, so this renders the deck-row shape the
      // kit uses for both the Library root and the parent branch.
      loading: (context) => const DeckRowsSkeleton(),
      error: (context, failure) => DeckLoadErrorState(
        title: l10n.deckLoadErrorTitle,
        onRetry: () => ref.invalidate(deckChildrenProvider(deckId: deck.id)),
      ),
      data: (context, childDecks) => MxAsyncBuilder<List<Flashcard>>(
        value: cards,
        // Children have resolved by now, so the branch is derivable: any
        // child deck means the parent branch (`subdeck-list--loading`),
        // none means leaf-or-empty (`flashcard-list--loading`).
        loading: (context) => childDecks.isEmpty
            ? const CardRowsSkeleton()
            : const DeckRowsSkeleton(),
        error: (context, failure) => DeckLoadErrorState(
          title: childDecks.isEmpty
              ? l10n.cardLoadErrorTitle
              : l10n.deckLoadErrorTitle,
          onRetry: () => ref.invalidate(deckCardsProvider(deckId: deck.id)),
        ),
        data: (context, directCards) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The Empty branch draws neither trail nor FAB: it is a focused
            // "decide what goes in here" surface whose actions are inline,
            // and the kit `empty-deck` shot shows both absent. The Parent
            // and Leaf shots show both present.
            if (childDecks.isNotEmpty || directCards.isNotEmpty)
              _DeckBreadcrumb(deckId: deck.id),
            Expanded(
              child: _DeckBranch(
                deck: deck,
                childDecks: childDecks,
                directCards: directCards,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The nested-deck breadcrumb header (WBS 6.2). Renders `Library › … ›` above
/// the deck content for a nested deck; a root deck (only itself in the chain)
/// shows nothing — the app-bar back is its up-navigation. The ancestor crumbs
/// navigate up; the current deck is the bold, non-interactive page crumb.
class _DeckBreadcrumb extends ConsumerWidget {
  const _DeckBreadcrumb({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chain = ref.watch(deckBreadcrumbProvider(deckId: deckId)).value;
    // Hide only until the chain resolves. A root deck still shows
    // `Library › <deck>`: both kit deck shots draw the trail at every level,
    // and the crumb is the only way back to the Library from a deck reached
    // by a push rather than a tab change (owner, 2026-07-25).
    if (chain == null || chain.isEmpty) return const SizedBox.shrink();

    final items = <MxBreadcrumbItem>[
      MxBreadcrumbItem(
        label: l10n.libraryTitle,
        onTap: () => context.goLibrary(),
      ),
      // The current deck (last in the chain) gets no onTap — MxBreadcrumb
      // renders the final crumb as the bold, non-interactive page label.
      for (final deck in chain)
        MxBreadcrumbItem(
          label: deck.name,
          onTap: deck.id == deckId
              ? null
              : () => context.pushDeckDetail(deck.id),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxBreadcrumb(items: items),
        const MxGap.s2(),
      ],
    );
  }
}

/// The §5 branching: Parent when children exist, Leaf when cards
/// exist, Empty otherwise. Mixed content cannot be persisted (4.3).
class _DeckBranch extends StatelessWidget {
  const _DeckBranch({
    required this.deck,
    required this.childDecks,
    required this.directCards,
  });

  final Deck deck;
  final List<Deck> childDecks;
  final List<Flashcard> directCards;

  @override
  Widget build(BuildContext context) {
    // The empty branch centers in the fixed shell; content branches
    // own their scrolling (the shell is non-scrollable).
    if (childDecks.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MxGap.s4(),
            _ParentBranch(deck: deck, childDecks: childDecks),
            const MxGap.s6(),
          ],
        ),
      );
    }
    if (directCards.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MxGap.s4(),
            _LeafBranch(deckId: deck.id, directCards: directCards),
            const MxGap.s6(),
          ],
        ),
      );
    }
    return _EmptyBranch(deck: deck);
  }
}

class _EmptyBranch extends StatelessWidget {
  const _EmptyBranch({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Kit `empty-deck--default`: the shared EmptyState with the wide
    // (size-4xl) action column and the import link centered below.
    return MxEmptyState(
      icon: Symbols.inbox_rounded,
      title: l10n.emptyDeckTitle,
      body: l10n.emptyDeckBody,
      actionWidth: MxEmptyStateActionWidth.wide,
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxButton(
            label: l10n.addCardLabel,
            icon: Symbols.add_rounded,
            block: true,
            onPressed: () => context.pushNewCard(deck.id),
          ),
          const MxGap.s3(),
          MxButton(
            label: l10n.createNestedDeckLabel,
            icon: Symbols.account_tree_rounded,
            variant: MxButtonVariant.secondary,
            block: true,
            onPressed: () => showCreateDeckDialog(
              context,
              parentDeckId: deck.id,
              parentDeckName: deck.name,
            ),
          ),
          const MxGap.s1(),
          // Import activates with the content-transfer flow (WBS 8.x).
          Center(
            child: MxLink(
              label: l10n.importCardsLabel,
              icon: Symbols.upload_file_rounded,
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the card-settings sheet, then runs the chosen lifecycle action
/// (WBS 6.5). Delete confirms first; hide/show and delete command the store,
/// and the Leaf stream reflects the change.
Future<void> _openCardSettings(
  BuildContext context,
  WidgetRef ref, {
  required String deckId,
  required Flashcard card,
}) async {
  // Capture the notifier before the sheet await — the row's WidgetRef must
  // not be used across the async gap.
  final notifier = ref.read(cardLifecycleCommandViewmodelProvider.notifier);
  final action = await showCardSettingsSheet(context, isHidden: card.isHidden);
  if (!context.mounted || action == null) return;
  switch (action) {
    case CardSettingsAction.edit:
      context.pushEditCard(deckId, card.id);
    case CardSettingsAction.move:
      await showMoveCardSheet(context, cardId: card.id);
    case CardSettingsAction.toggleHidden:
      await notifier.setCardHidden(cardId: card.id, hidden: !card.isHidden);
    case CardSettingsAction.delete:
      final l10n = AppLocalizations.of(context);
      final confirmed = await showMxConfirmDialog(
        context,
        icon: Symbols.delete_rounded,
        tone: MxConfirmTone.error,
        title: l10n.deleteCardTitle,
        text: l10n.deleteCardBody,
        confirmLabel: l10n.deleteCardConfirmLabel,
        cancelLabel: l10n.keepCardLabel,
        danger: true,
      );
      if (confirmed) await notifier.deleteCard(cardId: card.id);
  }
}

class _LeafBranch extends ConsumerWidget {
  const _LeafBranch({required this.deckId, required this.directCards});

  final String deckId;
  final List<Flashcard> directCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxText(
          l10n.cardCountSummary(directCards.length),
          role: MxTextRole.caption,
        ),
        const MxGap.s3(),
        for (final card in directCards)
          // Tapping a card opens its lifecycle actions (WBS 6.5).
          MxTappable(
            semanticLabel: card.term,
            onTap: () =>
                _openCardSettings(context, ref, deckId: deckId, card: card),
            child: Row(
              children: [
                const MxGap.s3(),
                const MxIcon(icon: Symbols.style),
                const MxGap.s3(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MxText(card.term, role: MxTextRole.subtitle),
                      MxText(
                        card.primaryMeaning,
                        role: MxTextRole.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (card.isHidden) ...[
                  const MxIcon(icon: Symbols.visibility_off_rounded),
                  const MxGap.s2(),
                ],
                const MxIcon(icon: Symbols.more_vert_rounded),
                const MxGap.s3(),
              ],
            ),
          ),
        const MxGap.s6(),
        // Add card lands with the 5.3 flashcard flow.
        MxButton(label: l10n.addCardLabel, block: true, onPressed: null),
      ],
    );
  }
}

class _ParentBranch extends ConsumerWidget {
  const _ParentBranch({required this.deck, required this.childDecks});

  final Deck deck;
  final List<Deck> childDecks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(deckChildSummariesProvider(deckId: deck.id));
    // Counters arrive with the summaries; until they resolve the branch
    // still lists the decks it already has, so it never blanks on refresh.
    final controls = ref.watch(libraryControlsViewmodelProvider(deck.id));
    final loaded =
        summaries.asData?.value ??
        <DeckSummary>[
          for (final child in childDecks)
            DeckSummary(deck: child, cardCount: 0),
        ];
    final rows =
        loaded
            .where(
              (row) => switch (controls.status) {
                LibraryStatusFilter.all => true,
                LibraryStatusFilter.due => row.dueCount > 0,
                LibraryStatusFilter.isNew => row.newCount > 0,
              },
            )
            .toList()
          ..sort(
            (a, b) => controls.sort == LibrarySort.az
                ? a.deck.normalizedName.compareTo(b.deck.normalizedName)
                : b.deck.normalizedName.compareTo(a.deck.normalizedName),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kit `SubdeckList.jsx` renders the Library's own FilterRow over the
        // child list (`crumbs + filter + list`), keyed to this deck so its
        // filter and sort are independent of the Library's.
        //
        // The kit SHOT for this state draws a `DECKS · N cards · N due`
        // section here instead, with no chips. Owner ruling (2026-07-25):
        // the JSX is the source of truth, so this row follows it and the
        // state waits on the shot being regenerated.
        DeckListControls(scopeId: deck.id),
        const MxGap.s3(),
        MxList(
          children: <Widget>[
            for (final row in rows)
              DeckSummaryRow(
                summary: row,
                // Push, so Back walks up to this parent rather than out to
                // the Library.
                onTap: () => context.pushDeckDetail(row.deck.id),
              ),
          ],
        ),
      ],
    );
  }
}

/// Create-a-nested-deck, in the shell FAB the kit puts it in rather than a
/// full-width button at the end of the list (owner, 2026-07-25).
///
/// It is its own consumer so the screen shell stays template-only, and it
/// only appears once the deck has resolved — there is no parent to nest
/// under before that.
class _CreateNestedDeckFab extends ConsumerWidget {
  const _CreateNestedDeckFab({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deck = ref.watch(deckDetailProvider(deckId: deckId)).value;
    if (deck == null) return const SizedBox.shrink();

    // Hidden on the Empty branch, which offers Create nested deck inline —
    // see the branch note in `_DeckContent`.
    final hasChildren =
        ref.watch(deckChildrenProvider(deckId: deckId)).value?.isNotEmpty ??
        false;
    final hasCards =
        ref.watch(deckCardsProvider(deckId: deckId)).value?.isNotEmpty ?? false;
    if (!hasChildren && !hasCards) return const SizedBox.shrink();

    return MxFab(
      icon: Symbols.add_rounded,
      semanticLabel: l10n.createDeckLabel,
      onPressed: () => showCreateDeckDialog(
        context,
        parentDeckId: deck.id,
        parentDeckName: deck.name,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/widgets/create_deck_dialog.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
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
      ),
      scrollable: false,
      body: _DeckDetailBody(deckId: deckId),
    );
  }
}

class _DeckDetailBody extends ConsumerWidget {
  const _DeckDetailBody({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deck = ref.watch(deckDetailProvider(deckId: deckId));

    return MxAsyncBuilder<Deck?>(
      value: deck,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, value) =>
          value == null ? _DeckNotFound(l10n: l10n) : _DeckContent(deck: value),
    );
  }
}

class _DeckNotFound extends StatelessWidget {
  const _DeckNotFound({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s8(),
        MxText(l10n.deckNotFoundMessage, role: MxTextRole.body),
        const MxGap.s4(),
        MxButton(
          label: l10n.backToLibraryLabel,
          onPressed: () => context.goLibrary(),
        ),
      ],
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
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, childDecks) => MxAsyncBuilder<List<Flashcard>>(
        value: cards,
        loadingLabel: l10n.loadingLabel,
        errorTitle: l10n.somethingWentWrongMessage,
        data: (context, directCards) => _DeckBranch(
          deck: deck,
          childDecks: childDecks,
          directCards: directCards,
        ),
      ),
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
            _LeafBranch(directCards: directCards),
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
          // Add card activates with the 5.3 flashcard flow.
          MxButton(
            label: l10n.addCardLabel,
            icon: Symbols.add_rounded,
            block: true,
            onPressed: null,
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

class _LeafBranch extends StatelessWidget {
  const _LeafBranch({required this.directCards});

  final List<Flashcard> directCards;

  @override
  Widget build(BuildContext context) {
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
          Row(
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
              const MxGap.s3(),
            ],
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
    final l10n = AppLocalizations.of(context);
    final subtreeCards = ref.watch(deckSubtreeCardsProvider(deckId: deck.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxText(
          l10n.parentDeckSummary(childDecks.length, subtreeCards.value ?? 0),
          role: MxTextRole.caption,
        ),
        const MxGap.s3(),
        for (final child in childDecks)
          MxTappable(
            semanticLabel: child.name,
            onTap: () => context.pushDeckDetail(child.id),
            child: Row(
              children: [
                const MxGap.s3(),
                const MxIcon(icon: Symbols.folder),
                const MxGap.s3(),
                Expanded(child: MxText(child.name, role: MxTextRole.subtitle)),
                const MxIcon(icon: Symbols.chevron_right),
                const MxGap.s3(),
              ],
            ),
          ),
        const MxGap.s6(),
        MxButton(
          label: l10n.createDeckLabel,
          block: true,
          onPressed: () => showCreateDeckDialog(
            context,
            parentDeckId: deck.id,
            parentDeckName: deck.name,
          ),
        ),
      ],
    );
  }
}

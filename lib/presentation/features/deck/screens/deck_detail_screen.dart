import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Open Deck (WBS 5.2.4B; `open-deck.md`): Empty/Leaf/Parent derived
/// from the reactive content streams — transitions update in place and
/// nothing keeps a stored mode.
class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return MxScaffold(scrollable: true, body: _DeckDetailBody(deckId: deckId));
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s4(),
        Row(
          children: [
            MxIconButton(
              icon: Symbols.arrow_back,
              semanticLabel: l10n.backLabel,
              onPressed: () => context.backFromDeck(),
            ),
            const MxGap.s2(),
            Expanded(
              child: MxText(
                deck.name,
                role: MxTextRole.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const MxGap.s4(),
        MxAsyncBuilder<List<Deck>>(
          value: children,
          loadingLabel: l10n.loadingLabel,
          errorTitle: l10n.somethingWentWrongMessage,
          data: (context, childDecks) => MxAsyncBuilder<List<Flashcard>>(
            value: cards,
            loadingLabel: l10n.loadingLabel,
            errorTitle: l10n.somethingWentWrongMessage,
            data: (context, directCards) =>
                _DeckBranch(childDecks: childDecks, directCards: directCards),
          ),
        ),
        const MxGap.s6(),
      ],
    );
  }
}

/// The §5 branching: Parent when children exist, Leaf when cards
/// exist, Empty otherwise. Mixed content cannot be persisted (4.3).
class _DeckBranch extends StatelessWidget {
  const _DeckBranch({required this.childDecks, required this.directCards});

  final List<Deck> childDecks;
  final List<Flashcard> directCards;

  @override
  Widget build(BuildContext context) {
    if (childDecks.isNotEmpty) {
      return _ParentBranch(childDecks: childDecks);
    }
    if (directCards.isNotEmpty) {
      return _LeafBranch(directCards: directCards);
    }
    return const _EmptyBranch();
  }
}

class _EmptyBranch extends StatelessWidget {
  const _EmptyBranch();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s6(),
        MxText(l10n.emptyDeckTitle, role: MxTextRole.headline),
        const MxGap.s2(),
        MxText(l10n.emptyDeckBody, role: MxTextRole.body),
        const MxGap.s6(),
        // Content-choice CTAs activate with 5.2.5 (add card lands with
        // the 5.3 flashcard flow, nested create with the 5.2.4C dialog).
        MxButton(label: l10n.addCardLabel, block: true, onPressed: null),
        const MxGap.s3(),
        MxButton(
          label: l10n.createNestedDeckLabel,
          variant: MxButtonVariant.secondary,
          block: true,
          onPressed: null,
        ),
      ],
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

class _ParentBranch extends StatelessWidget {
  const _ParentBranch({required this.childDecks});

  final List<Deck> childDecks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxText(
          l10n.nestedDeckCountSummary(childDecks.length),
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
        // Nested create lands with the 5.2.4C dialog.
        MxButton(label: l10n.createDeckLabel, block: true, onPressed: null),
      ],
    );
  }
}

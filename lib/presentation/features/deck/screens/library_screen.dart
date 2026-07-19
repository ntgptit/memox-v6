import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/library_viewmodel.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Library root (WBS 5.2.4A): the reactive root-deck list of the
/// active pair, the transferred first-run success callout with the new
/// deck highlighted, and per-row navigation into deck detail.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MxScaffold(scrollable: true, body: _LibraryBody());
  }
}

class _LibraryBody extends ConsumerWidget {
  const _LibraryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roots = ref.watch(libraryRootDecksProvider);
    final calloutDeckId = ref.watch(firstDeckCalloutViewmodelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s4(),
        MxText(l10n.libraryTitle, role: MxTextRole.headline),
        const MxGap.s4(),
        if (calloutDeckId != null) ...[
          _FirstDeckCallout(deckId: calloutDeckId),
          const MxGap.s4(),
        ],
        MxAsyncBuilder<List<Deck>>(
          value: roots,
          loadingLabel: l10n.loadingLabel,
          errorTitle: l10n.somethingWentWrongMessage,
          data: (context, decks) => decks.isEmpty
              ? MxText(l10n.emptyLibraryMessage, role: MxTextRole.body)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final deck in decks)
                      _DeckRow(
                        deck: deck,
                        highlighted: deck.id == calloutDeckId,
                      ),
                  ],
                ),
        ),
        const MxGap.s6(),
      ],
    );
  }
}

class _FirstDeckCallout extends ConsumerWidget {
  const _FirstDeckCallout({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return MxBanner(
      tone: MxBannerTone.success,
      title: l10n.firstDeckReadyTitle,
      body: l10n.firstDeckReadyBody,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxTappable(
            semanticLabel: l10n.openDeckLabel,
            onTap: () {
              ref
                  .read(firstDeckCalloutViewmodelProvider.notifier)
                  .dismissCallout();
              context.goDeckDetail(deckId);
            },
            child: MxText(l10n.openDeckLabel, role: MxTextRole.subtitle),
          ),
          const MxGap.s3(),
          MxIconButton(
            icon: Symbols.close,
            small: true,
            semanticLabel: l10n.dismissLabel,
            onPressed: () => ref
                .read(firstDeckCalloutViewmodelProvider.notifier)
                .dismissCallout(),
          ),
        ],
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.highlighted});

  final Deck deck;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final description = deck.description;

    return MxTappable(
      semanticLabel: deck.name,
      onTap: () => context.goDeckDetail(deck.id),
      child: Row(
        children: [
          const MxGap.s3(),
          MxIcon(icon: highlighted ? Symbols.new_releases : Symbols.folder),
          const MxGap.s3(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MxText(deck.name, role: MxTextRole.subtitle),
                if (description != null)
                  MxText(
                    description,
                    role: MxTextRole.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const MxIcon(icon: Symbols.chevron_right),
          const MxGap.s3(),
        ],
      ),
    );
  }
}

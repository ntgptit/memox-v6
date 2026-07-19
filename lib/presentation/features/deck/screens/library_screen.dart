import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/library_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/widgets/create_deck_dialog.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_bottom_nav.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_badge.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_deck_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Library root (WBS 5.2.4A, kit shell per 3.15B): the reactive
/// root-deck list of the active pair inside the shared chrome
/// (contextual app bar + bottom nav), the kit LIB-04 empty state, the
/// transferred first-run success callout and per-row deck navigation.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MxScaffold(
      appBar: MxContextualAppBar(title: l10n.libraryTitle),
      bottomNav: MxBottomNav(
        items: [
          MxBottomNavItem(
            id: RouteNames.home,
            label: l10n.navTodayLabel,
            icon: Symbols.today_rounded,
          ),
          MxBottomNavItem(
            id: RouteNames.library,
            label: l10n.libraryTitle,
            icon: Symbols.style_rounded,
          ),
          MxBottomNavItem(
            id: RouteNames.stats,
            label: l10n.navStatsLabel,
            icon: Symbols.insights_rounded,
          ),
          MxBottomNavItem(
            id: RouteNames.profile,
            label: l10n.navProfileLabel,
            icon: Symbols.person_rounded,
          ),
        ],
        value: RouteNames.library,
        onChanged: (id) => switch (id) {
          RouteNames.home => context.goHome(),
          RouteNames.stats => context.goStats(),
          RouteNames.profile => context.goProfile(),
          _ => null,
        },
      ),
      scrollable: false,
      body: const _LibraryBody(),
    );
  }
}

class _LibraryBody extends ConsumerWidget {
  const _LibraryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roots = ref.watch(libraryRootDecksProvider);
    final calloutDeckId = ref.watch(firstDeckCalloutViewmodelProvider);

    return MxAsyncBuilder<List<DeckSummary>>(
      value: roots,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, summaries) => summaries.isEmpty
          ? const _LibraryEmptyState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MxGap.s4(),
                  for (final summary in summaries) ...[
                    _DeckRow(
                      summary: summary,
                      isNew: summary.deck.id == calloutDeckId,
                    ),
                    const MxGap.s3(),
                  ],
                  if (calloutDeckId != null) ...[
                    const MxGap.s2(),
                    _FirstDeckCallout(deckId: calloutDeckId),
                  ],
                  const MxGap.s6(),
                  MxButton(
                    label: l10n.createDeckLabel,
                    block: true,
                    onPressed: () => showCreateDeckDialog(context),
                  ),
                  const MxGap.s6(),
                ],
              ),
            ),
    );
  }
}

/// Kit `library--empty` (LIB-04): the shared empty state with the
/// create/import action column on the kit action width.
class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MxEmptyState(
      icon: Symbols.style_rounded,
      title: l10n.libraryEmptyTitle,
      body: l10n.libraryEmptyBody,
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxButton(
            label: l10n.createDeckLabel,
            icon: Symbols.stacks_rounded,
            block: true,
            onPressed: () => showCreateDeckDialog(context),
          ),
          const MxGap.s3(),
          MxButton(
            label: l10n.importCardsLabel,
            icon: Symbols.upload_file_rounded,
            variant: MxButtonVariant.secondary,
            block: true,
            // Handoff target: card import is content-transfer scope
            // (WBS 8.x); the CTA activates when that flow lands.
            onPressed: null,
          ),
        ],
      ),
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
  const _DeckRow({required this.summary, required this.isNew});

  final DeckSummary summary;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Kit shared DeckCard: default deck glyph `style`, accent tile,
    // "N cards" meta, soft "New" badge on the just-created deck.
    return MxDeckCard(
      icon: Symbols.style_rounded,
      title: summary.deck.name,
      meta: l10n.cardsCountLabel(summary.cardCount),
      trailing: isNew ? MxBadge(label: l10n.newBadgeLabel, soft: true) : null,
      onTap: () => context.goDeckDetail(summary.deck.id),
    );
  }
}

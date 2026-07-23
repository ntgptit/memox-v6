import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/library_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/widgets/create_deck_dialog.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_deck_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_fab.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_list.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_select_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_chip.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Library root (WBS 5.2.4A, kit shell per 3.15B): the reactive
/// root-deck list of the active pair inside the shared chrome
/// (contextual app bar; the tab bar belongs to `AppTabShell`), the kit
/// LIB-04 empty state and per-row deck navigation.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // No `bottomNav` here: Library is a branch of `AppTabShell`, which
    // owns the persistent tab bar for every root destination. The FAB is
    // its own consumer so the shell stays template-only.
    return MxScaffold(
      appBar: MxContextualAppBar(
        title: l10n.libraryTitle,
        actions: <Widget>[
          MxIconButton.toolbar(
            icon: Symbols.search_rounded,
            semanticLabel: l10n.searchLabel,
            onPressed: () => context.pushSearch(),
          ),
        ],
      ),
      scrollable: false,
      fab: const _LibraryFab(),
      body: const _LibraryBody(),
    );
  }
}

/// Create FAB, shown only once the library has decks — the empty state
/// carries its own create/import buttons instead (kit `library--loaded`).
class _LibraryFab extends ConsumerWidget {
  const _LibraryFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasDecks =
        ref.watch(libraryRootDecksProvider).asData?.value.isNotEmpty ?? false;
    if (!hasDecks) return const SizedBox.shrink();
    return MxFab(
      icon: Symbols.add_rounded,
      semanticLabel: l10n.createDeckLabel,
      onPressed: () => showCreateDeckDialog(context),
    );
  }
}

class _LibraryBody extends ConsumerWidget {
  const _LibraryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roots = ref.watch(libraryRootDecksProvider);

    return MxAsyncBuilder<List<DeckSummary>>(
      value: roots,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, summaries) {
        if (summaries.isEmpty) return const _LibraryEmptyState();
        final controls = ref.watch(libraryControlsViewmodelProvider);
        final visible =
            summaries
                .where(
                  (s) => switch (controls.status) {
                    LibraryStatusFilter.all => true,
                    LibraryStatusFilter.due => s.dueCount > 0,
                    LibraryStatusFilter.isNew => s.newCount > 0,
                  },
                )
                .toList()
              ..sort((a, b) {
                final byName = StringUtils.lowerCased(
                  a.deck.name,
                ).compareTo(StringUtils.lowerCased(b.deck.name));
                return controls.sort == LibrarySort.az ? byName : -byName;
              });
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MxGap.s4(),
              const _LibraryControls(),
              const MxGap.s4(),
              // A ternary (not `if/else`) keeps the guard's no-else rule.
              visible.isEmpty
                  ? _NoMatch(message: l10n.libraryNoMatchLabel)
                  : MxList(
                      children: [
                        for (final summary in visible)
                          _DeckRow(summary: summary),
                      ],
                    ),
              const MxGap.s6(),
            ],
          ),
        );
      },
    );
  }
}

/// Shown when the active filter hides every deck.
class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MxGap.s6(),
        MxText(
          message,
          role: MxTextRole.body,
          textAlign: TextAlign.center,
          color: context.colors.textSecondary,
        ),
        const MxGap.s6(),
      ],
    );
  }
}

/// Kit `library/controls` (FilterRow): scope · filters · sort. The scope
/// chip is static until multi-pair scoping lands; filters and sort drive
/// [LibraryControlsViewmodel].
class _LibraryControls extends ConsumerWidget {
  const _LibraryControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controls = ref.watch(libraryControlsViewmodelProvider);
    final notifier = ref.read(libraryControlsViewmodelProvider.notifier);
    final filtered = controls.status != LibraryStatusFilter.all;

    return Row(
      children: [
        MxChip(label: l10n.libraryScopeAllLabel),
        const Spacer(),
        MxChip(
          label: filtered
              ? l10n.libraryFiltersActiveLabel(1)
              : l10n.libraryFiltersLabel,
          icon: Symbols.tune_rounded,
          selected: filtered,
          onTap: () =>
              _openStatusSheet(context, l10n, controls.status, notifier),
        ),
        const MxGap.s2(),
        MxChip(
          label: controls.sort == LibrarySort.az
              ? l10n.librarySortAzLabel
              : l10n.librarySortZaLabel,
          icon: Symbols.swap_vert_rounded,
          onTap: notifier.toggleSort,
        ),
      ],
    );
  }

  Future<void> _openStatusSheet(
    BuildContext context,
    AppLocalizations l10n,
    LibraryStatusFilter current,
    LibraryControlsViewmodel notifier,
  ) async {
    final picked = await showMxSelectSheet<LibraryStatusFilter>(
      context,
      title: l10n.libraryFilterTitle,
      selected: current,
      options: [
        MxSelectOption(
          key: LibraryStatusFilter.all,
          icon: Symbols.stacks_rounded,
          label: l10n.libraryScopeAllLabel,
        ),
        MxSelectOption(
          key: LibraryStatusFilter.due,
          icon: Symbols.schedule_rounded,
          label: l10n.libraryFilterDueLabel,
        ),
        MxSelectOption(
          key: LibraryStatusFilter.isNew,
          icon: Symbols.fiber_new_rounded,
          label: l10n.libraryFilterNewLabel,
        ),
      ],
    );
    if (picked != null) notifier.setStatus(picked);
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
      reserveNavZone: false,
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

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.summary});

  final DeckSummary summary;

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
      onTap: () => context.goDeckDetail(summary.deck.id),
    );
  }
}

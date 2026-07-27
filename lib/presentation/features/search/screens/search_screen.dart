import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/search/search_result.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/search/viewmodels/search_viewmodel.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_chip.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Library search (WBS 10.2; `search-library-content.md`): a query field over
/// the ranked read-model. A blank query shows a neutral prompt (recent searches
/// are a follow-up); a query with hits lists ranked Deck/Card results and a tap
/// opens the object in its deck; no hits shows guidance.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MxScaffold(
      appBar: MxContextualAppBar(
        title: l10n.searchLabel,
        onBack: () => Navigator.of(context).pop(),
        backLabel: l10n.backLabel,
      ),
      scrollable: false,
      body: const _SearchBody(),
    );
  }
}

/// Result-type filter for the search list (WBS 10.2; `filter-search-results.md`).
enum SearchResultFilter { all, decks, cards }

bool _matchesFilter(SearchResultFilter filter, SearchResult result) {
  return switch (filter) {
    SearchResultFilter.all => true,
    SearchResultFilter.decks => result.type == SearchResultType.deck,
    SearchResultFilter.cards => result.type == SearchResultType.card,
  };
}

class _SearchBody extends HookConsumerWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final input = useMxTextValue();
    final query = StringUtils.trimmed(input.value);
    final filter = useState(SearchResultFilter.all);

    void recordSubmitted(String value) {
      final committed = StringUtils.trimmed(value);
      if (committed.isEmpty) return;
      ref
          .read(recentSearchesCommandViewmodelProvider.notifier)
          .record(committed);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s4(),
        MxTextField(
          controller: input.controller,
          label: l10n.searchLabel,
          boxed: true,
          placeholder: l10n.searchPlaceholder,
          onChanged: (_) {},
          onSubmitted: recordSubmitted,
        ),
        const MxGap.s4(),
        if (query.isNotEmpty) ...[
          _FilterChips(
            selected: filter.value,
            onSelect: (value) => filter.value = value,
          ),
          const MxGap.s3(),
        ],
        Expanded(
          child: query.isEmpty
              ? _Recent(onSelect: (value) => input.controller.text = value)
              : _Results(
                  query: query,
                  filter: filter.value,
                  onClearFilter: () => filter.value = SearchResultFilter.all,
                ),
        ),
      ],
    );
  }
}

class _Recent extends ConsumerWidget {
  const _Recent({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recent = ref.watch(recentSearchesProvider).value ?? const <String>[];
    if (recent.isEmpty) {
      return _Prompt(message: l10n.searchPromptMessage);
    }

    return ListView(
      children: [
        Row(
          children: [
            const MxGap.s3(),
            Expanded(
              child: MxText(
                l10n.recentSearchesLabel,
                role: MxTextRole.overline,
              ),
            ),
            MxTappable(
              semanticLabel: l10n.clearRecentSearchesLabel,
              onTap: () => ref
                  .read(recentSearchesCommandViewmodelProvider.notifier)
                  .clearRecent(),
              child: MxText(
                l10n.clearRecentSearchesLabel,
                role: MxTextRole.caption,
              ),
            ),
            const MxGap.s3(),
          ],
        ),
        const MxGap.s2(),
        for (final query in recent)
          Row(
            children: [
              Expanded(
                child: MxTappable(
                  semanticLabel: query,
                  onTap: () => onSelect(query),
                  child: Row(
                    children: [
                      const MxGap.s3(),
                      const MxIcon(icon: Symbols.history_rounded),
                      const MxGap.s4(),
                      Expanded(child: MxText(query, role: MxTextRole.body)),
                    ],
                  ),
                ),
              ),
              // §3: "Row có query và remove action" — the kit draws it as the
              // row's trailing `close` (`search/recent-remove-*`). Clearing
              // the whole history was the only way to drop one query.
              MxIconButton(
                icon: Symbols.close_rounded,
                small: true,
                semanticLabel: l10n.removeRecentSearchLabel(query),
                onPressed: () => ref
                    .read(recentSearchesCommandViewmodelProvider.notifier)
                    .removeRecent(query),
              ),
              const MxGap.s3(),
            ],
          ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelect});

  final SearchResultFilter selected;
  final ValueChanged<SearchResultFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: MxGap.s2Value,
      runSpacing: MxGap.s2Value,
      children: [
        MxChip(
          label: l10n.searchFilterAll,
          selected: selected == SearchResultFilter.all,
          onTap: () => onSelect(SearchResultFilter.all),
        ),
        MxChip(
          label: l10n.searchFilterDecks,
          selected: selected == SearchResultFilter.decks,
          onTap: () => onSelect(SearchResultFilter.decks),
        ),
        MxChip(
          label: l10n.searchFilterCards,
          selected: selected == SearchResultFilter.cards,
          onTap: () => onSelect(SearchResultFilter.cards),
        ),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: MxText(message, role: MxTextRole.caption));
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.query,
    required this.filter,
    required this.onClearFilter,
  });

  final String query;
  final SearchResultFilter filter;

  /// Drops back to the unfiltered list (`filter-search-results.md` §6:
  /// "Clear phục hồi query không filter").
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final results = ref.watch(searchResultsProvider(query: query));

    return MxAsyncBuilder<List<SearchResult>>(
      value: results,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      // `recover-search-failure.md` §3: the primary CTA on a recoverable
      // search failure is Retry, and §1's objective is recovering "mà không
      // buộc user nhập lại" — without making the learner type the query
      // again. There was no retry at all, so a failed search could only be
      // escaped by editing the query, which is exactly the re-entry the flow
      // exists to avoid.
      //
      // Re-running is an invalidate rather than new state: the provider is
      // keyed by query, so this reruns the latest query and nothing more
      // (§4 "Rerun chỉ dùng latest query/filter token"). The failure is
      // scoped to this list, so the field, filter and recent context are
      // still on screen — §1's "Error giữ query, filters và recent context".
      onRetry: () => ref.invalidate(searchResultsProvider(query: query)),
      retryLabel: l10n.tryAgainLabel,
      data: (context, hits) {
        final shown = hits.where((hit) => _matchesFilter(filter, hit)).toList();
        // `filter-search-results.md` §4: "No-results-with-filters nêu
        // Clear/adjust filters". Results the chip hid are not a no-match, but
        // both rendered the same "nothing matched" line — so a learner whose
        // query found only cards while `Decks` was selected was told their
        // query found nothing, with no clear offered and no hint that `All`
        // was the way back.
        if (shown.isEmpty && hits.isNotEmpty) {
          return MxEmptyState(
            icon: Symbols.filter_alt_off,
            tone: MxIconTileTone.warning,
            title: l10n.searchFilteredEmptyTitle,
            body: l10n.searchFilteredEmptyMessage,
            reserveNavZone: false,
            action: MxButton(
              onPressed: onClearFilter,
              label: l10n.clearSearchFilterLabel,
              variant: MxButtonVariant.secondary,
              block: true,
            ),
          );
        }
        // The kit's `search/no-results`: a warning-toned empty state that
        // names the query back. This was the same centred caption the
        // blank-query prompt uses, so "you haven't searched yet" and "your
        // search found nothing" were the same picture (KIT-26-02).
        if (shown.isEmpty) {
          return MxEmptyState(
            icon: Symbols.search_off,
            tone: MxIconTileTone.warning,
            title: l10n.searchNoResultsTitle,
            body: l10n.searchNoResultsMessage(query),
            reserveNavZone: false,
          );
        }
        return ListView(
          children: [
            for (final hit in shown) _ResultRow(result: hit, query: query),
          ],
        );
      },
    );
  }
}

class _ResultRow extends HookConsumerWidget {
  const _ResultRow({required this.result, required this.query});

  final SearchResult result;

  /// The query whose result list this row belongs to, so the return can
  /// refresh exactly that list.
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // §4: "Double tap chỉ tạo một navigation". The pushed route takes a
    // frame to cover the row, and a second tap inside that frame stacked a
    // second copy of the destination that Back then had to be pressed twice
    // to leave.
    final opening = useRef(false);

    Future<void> open() async {
      if (opening.value) return;
      opening.value = true;
      // Hand off to the owning object's contract (open-search-result.md §2): a
      // deck opens its detail, a card opens the card editor in its deck.
      switch (result.type) {
        case SearchResultType.deck:
          await context.pushDeckDetail(result.deckId);
        case SearchResultType.card:
          await context.pushEditCard(result.deckId, result.id);
      }
      opening.value = false;
      // §4: "Sau edit/delete, return refresh affected result/index". Search
      // stays mounted under the pushed route and the list is a future cached
      // per query, so a card renamed in the editor came back to a row still
      // carrying its old term — and a card deleted there came back to a row
      // that opened an object no longer in the store.
      if (!context.mounted) return;
      ref.invalidate(searchResultsProvider(query: query));
    }

    final icon = result.type == SearchResultType.deck
        ? Symbols.folder
        : Symbols.style;
    // `hide-flashcard.md` §1 keeps a hidden Card findable, and search is where
    // a learner goes to find one back — so the hit carries its state rather
    // than looking like any other row. §4 wants that state read, not just seen.
    final l10n = AppLocalizations.of(context);
    return MxTappable(
      semanticLabel: result.isHidden
          ? l10n.cardHiddenSemantics(result.displayText)
          : result.displayText,
      onTap: open,
      child: Row(
        children: [
          const MxGap.s3(),
          MxIcon(icon: icon),
          const MxGap.s4(),
          Expanded(child: MxText(result.displayText, role: MxTextRole.body)),
          if (result.isHidden) ...[
            const MxGap.s2(),
            MxText(
              l10n.cardHiddenBadge,
              role: MxTextRole.caption,
              color: context.colors.textSecondary,
            ),
          ],
          const MxGap.s3(),
        ],
      ),
    );
  }
}

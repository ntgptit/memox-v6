import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/search/search_result.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/search/viewmodels/search_viewmodel.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
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

class _SearchBody extends HookConsumerWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final input = useMxTextValue();
    final query = StringUtils.trimmed(input.value);

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
        ),
        const MxGap.s4(),
        Expanded(
          child: query.isEmpty
              ? _Prompt(message: l10n.searchPromptMessage)
              : _Results(query: query),
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
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final results = ref.watch(searchResultsProvider(query: query));

    return MxAsyncBuilder<List<SearchResult>>(
      value: results,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, hits) {
        if (hits.isEmpty) {
          return _Prompt(message: l10n.searchNoResultsMessage);
        }
        return ListView(
          children: [for (final hit in hits) _ResultRow(result: hit)],
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final SearchResult result;

  void _open(BuildContext context) {
    // Hand off to the owning object's contract (open-search-result.md §2): a
    // deck opens its detail, a card opens the card editor in its deck.
    switch (result.type) {
      case SearchResultType.deck:
        context.pushDeckDetail(result.deckId);
      case SearchResultType.card:
        context.pushEditCard(result.deckId, result.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = result.type == SearchResultType.deck
        ? Symbols.folder
        : Symbols.style;
    return MxTappable(
      semanticLabel: result.displayText,
      onTap: () => _open(context),
      child: Row(
        children: [
          const MxGap.s3(),
          MxIcon(icon: icon),
          const MxGap.s4(),
          Expanded(child: MxText(result.displayText, role: MxTextRole.body)),
          const MxGap.s3(),
        ],
      ),
    );
  }
}

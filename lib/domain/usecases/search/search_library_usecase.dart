import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/deck/deck_name.dart';
import 'package:memox_v6/domain/flashcard/card_text.dart';
import 'package:memox_v6/domain/search/search_repository.dart';
import 'package:memox_v6/domain/search/search_result.dart';

/// Searches Library content (WBS 10.1; `search-library-content.md`).
///
/// A blank query returns nothing (the recent/suggestions surface owns that
/// state, not no-results). Otherwise it normalizes the query per each source's
/// own rule — card term and deck name normalize differently — and returns the
/// read-model's ranked results (`search-rank-v1`). Read-only: nothing is
/// mutated. Meaning/translation matching is a recorded follow-up (those columns
/// are not normalized-stored).
class SearchLibraryUseCase {
  const SearchLibraryUseCase({required SearchRepository search})
    : _search = search;

  final SearchRepository _search;

  Future<List<SearchResult>> search({
    required String languagePairId,
    required String query,
  }) {
    final trimmed = StringUtils.trimmed(query);
    if (trimmed.isEmpty) return Future.value(const <SearchResult>[]);
    return _search.searchLibrary(
      languagePairId,
      cardQuery: normalizeCardTerm(trimmed),
      deckQuery: normalizeDeckName(trimmed),
    );
  }
}

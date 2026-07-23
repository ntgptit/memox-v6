import 'package:memox_v6/domain/search/search_result.dart';

/// Library search read-model port (WBS 10.1; `search-library-content.md`).
///
/// Deterministic + read-only: the same normalized query, pair and index
/// version yield the same ordered ids (`search-rank-v1`). Card term and deck
/// name normalize differently, so the caller supplies each its own normalized
/// query. Hidden/deleted content is excluded by the read-model.
abstract interface class SearchRepository {
  Future<List<SearchResult>> searchLibrary(
    String languagePairId, {
    required String cardQuery,
    required String deckQuery,
  });
}

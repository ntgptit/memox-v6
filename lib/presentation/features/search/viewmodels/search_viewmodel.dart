import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/search/search_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_viewmodel.g.dart';

/// Ranked Library search results for [query] (WBS 10.2;
/// `search-library-content.md`). Keyed by the query so a newer query's results
/// supersede an in-flight older one — stale responses never publish. A blank
/// query resolves to no results (the read-model owns that).
@riverpod
Future<List<SearchResult>> searchResults(
  Ref ref, {
  required String query,
}) async {
  final pair = await ref.watch(selectLanguagePairUseCaseProvider).activePair();
  if (pair == null) return const <SearchResult>[];
  return ref
      .watch(searchLibraryUseCaseProvider)
      .search(languagePairId: pair.id, query: query);
}

import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/search/search_result.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_viewmodel.g.dart';

/// The recent search queries, newest-first (WBS 10.2;
/// `manage-recent-searches.md`). One-shot; the command invalidates it.
@riverpod
Future<List<String>> recentSearches(Ref ref) {
  return ref.watch(recentSearchesUseCaseProvider).current();
}

/// Records committed queries and clears the recent list (WBS 10.2). Kept alive
/// because callers only read it; on success it invalidates
/// [recentSearchesProvider] so the list refreshes.
@Riverpod(keepAlive: true)
class RecentSearchesCommandViewmodel extends _$RecentSearchesCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> record(String query) async {
    final result = await runMxAction(() async {
      await ref.read(recentSearchesUseCaseProvider).record(query);
    });
    if (result is! AsyncError) ref.invalidate(recentSearchesProvider);
  }

  Future<void> clearRecent() async {
    final result = await runMxAction(() async {
      await ref.read(recentSearchesUseCaseProvider).clear();
    });
    if (result is! AsyncError) ref.invalidate(recentSearchesProvider);
  }
}

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

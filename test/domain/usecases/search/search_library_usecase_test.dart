import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/search/search_repository.dart';
import 'package:memox_v6/domain/search/search_result.dart';
import 'package:memox_v6/domain/usecases/search/search_library_usecase.dart';

/// WBS 10.1 — the search use case skips a blank query and normalizes per source
/// before delegating to the read-model (search-library-content.md §1).
void main() {
  test('a blank query returns nothing and never hits the read-model', () async {
    final repo = _FakeSearch();
    final usecase = SearchLibraryUseCase(search: repo);

    expect(await usecase.search(languagePairId: 'lp1', query: '   '), isEmpty);
    expect(repo.calls, 0);
  });

  test('a query is trimmed and normalized per source', () async {
    final repo = _FakeSearch();
    final usecase = SearchLibraryUseCase(search: repo);

    await usecase.search(languagePairId: 'lp1', query: '  Hello ');

    expect(repo.calls, 1);
    expect(repo.pair, 'lp1');
    // Both normalizations lower/case-fold + trim to 'hello' for ASCII input.
    expect(repo.cardQuery, 'hello');
    expect(repo.deckQuery, 'hello');
  });
}

class _FakeSearch implements SearchRepository {
  int calls = 0;
  String? pair;
  String? cardQuery;
  String? deckQuery;

  @override
  Future<List<SearchResult>> searchLibrary(
    String languagePairId, {
    required String cardQuery,
    required String deckQuery,
  }) async {
    calls++;
    pair = languagePairId;
    this.cardQuery = cardQuery;
    this.deckQuery = deckQuery;
    return const [];
  }
}

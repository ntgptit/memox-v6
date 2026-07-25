import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/domain/search/search_repository.dart';
import 'package:memox_v6/domain/search/search_result.dart';

/// Drift-backed [SearchRepository] (WBS 10.1). The ranked ordering lives in the
/// `searchLibraryContent` query; this maps its rows to domain results.
class DriftSearchRepository implements SearchRepository {
  DriftSearchRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<SearchResult>> searchLibrary(
    String languagePairId, {
    required String cardQuery,
    required String deckQuery,
  }) async {
    final rows = await _database.deckDao
        .searchLibraryContent(cardQuery, languagePairId, deckQuery)
        .get();
    return rows.map((row) {
      return SearchResult(
        id: row.id,
        type: row.resultType == 'card'
            ? SearchResultType.card
            : SearchResultType.deck,
        displayText: row.displayText,
        deckId: row.deckId,
      );
    }).toList();
  }
}

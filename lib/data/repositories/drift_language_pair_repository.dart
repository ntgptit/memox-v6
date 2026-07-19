import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/content_mapper.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';

/// Drift-backed [LanguagePairRepository] (WBS 4.6A).
class DriftLanguagePairRepository implements LanguagePairRepository {
  DriftLanguagePairRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> createPair(LanguagePair pair) {
    return mapSqliteConflicts(entity: 'language_pairs', () async {
      await _database.languagePairDao.insertLanguagePair(
        pair.id,
        pair.learningLanguageCode,
        pair.nativeLanguageCode,
        pair.normalizedPairKey,
        pair.createdAt.millisecondsSinceEpoch,
        pair.updatedAt.millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<LanguagePair?> findById(String id) async {
    final row = await _database.languagePairDao
        .findLanguagePairById(id)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<LanguagePair?> findByNormalizedKey(String normalizedPairKey) async {
    final row = await _database.languagePairDao
        .findLanguagePairByKey(normalizedPairKey)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> deleteById(String id) {
    return mapSqliteConflicts(entity: 'language_pairs', () async {
      await _database.languagePairDao.deleteLanguagePair(id);
    });
  }

  @override
  Stream<List<LanguagePair>> watchAll() {
    return _database.languagePairDao.watchAllLanguagePairs().watch().map(
      (rows) => rows.map((row) => row.toDomain()).toList(),
    );
  }
}

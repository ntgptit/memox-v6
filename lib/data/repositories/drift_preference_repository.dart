import 'dart:convert';

import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/progress_mapper.dart';
import 'package:memox_v6/domain/preferences/preference_entry.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';

/// Drift-backed [PreferenceRepository] (WBS 4.6B). Encoding lives here;
/// decoding (with the invalid-payload null fallback) lives in the
/// mapper.
class DriftPreferenceRepository implements PreferenceRepository {
  DriftPreferenceRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> save(
    String key, {
    required Object? value,
    required int schemaVersion,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'preferences', () async {
      await _database.preferenceDao.upsertPreference(
        key,
        jsonEncode(value),
        schemaVersion,
        updatedAt.millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<PreferenceEntry?> read(String key) async {
    final row = await _database.preferenceDao
        .findPreference(key)
        .getSingleOrNull();
    return row?.toDomainOrNull();
  }

  @override
  Stream<PreferenceEntry?> watch(String key) {
    return _database.preferenceDao
        .watchPreference(key)
        .watchSingleOrNull()
        .map((row) => row?.toDomainOrNull());
  }

  @override
  Future<void> remove(String key) {
    return mapSqliteConflicts(entity: 'preferences', () async {
      await _database.preferenceDao.deletePreference(key);
    });
  }
}

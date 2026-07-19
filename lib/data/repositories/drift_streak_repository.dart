import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/progress_mapper.dart';
import 'package:memox_v6/domain/study_streak/streak_day.dart' as domain;
import 'package:memox_v6/domain/study_streak/streak_repository.dart';

/// Drift-backed [StreakRepository] (WBS 4.6B).
class DriftStreakRepository implements StreakRepository {
  DriftStreakRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> recordDay(domain.StreakDay day, {required DateTime recordedAt}) {
    return mapSqliteConflicts(entity: 'streak_days', () async {
      await _database.streakDao.recordStreakDay(
        day.id,
        day.localDate,
        day.timezoneId,
        day.qualifiedSource,
        recordedAt.millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<List<domain.StreakDay>> daysBetween(
    String fromLocalDate,
    String toLocalDate,
  ) async {
    final rows = await _database.streakDao
        .listStreakDaysBetween(fromLocalDate, toLocalDate)
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<int> countDays() {
    return _database.streakDao.countStreakDays().getSingle();
  }
}

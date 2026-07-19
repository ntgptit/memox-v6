import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/sqlite_error_mapper.dart';
import 'package:memox_v6/data/mappers/progress_mapper.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/domain/study_goal/goal_day_progress.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';

/// Drift-backed [StudyGoalRepository] (WBS 4.6B).
class DriftStudyGoalRepository implements StudyGoalRepository {
  DriftStudyGoalRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> createGoal(DailyGoal goal) {
    return mapSqliteConflicts(entity: 'daily_goals', () async {
      await _database.studyGoalDao.insertGoal(
        goal.id,
        goal.isEnabled ? 1 : 0,
        goal.targetCardCount,
        goal.effectiveFromLocalDate,
        goal.timezoneId,
        goal.createdAt.millisecondsSinceEpoch,
        goal.updatedAt.millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<void> updateGoal(
    String goalId, {
    required bool isEnabled,
    required int targetCardCount,
    required DateTime updatedAt,
  }) {
    return mapSqliteConflicts(entity: 'daily_goals', () async {
      await _database.studyGoalDao.updateGoal(
        isEnabled ? 1 : 0,
        targetCardCount,
        updatedAt.millisecondsSinceEpoch,
        goalId,
      );
    });
  }

  @override
  Future<DailyGoal?> latestGoal() async {
    final row = await _database.studyGoalDao.findLatestGoal().getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> recordDayProgress(GoalDayProgress progress) {
    return mapSqliteConflicts(entity: 'goal_day_progress', () async {
      await _database.studyGoalDao.upsertDayProgress(
        progress.id,
        progress.localDate,
        progress.timezoneId,
        progress.goalId,
        progress.qualifiedCardCount,
        progress.targetSnapshot,
        progress.isMet ? 1 : 0,
        progress.updatedAt.millisecondsSinceEpoch,
        progress.updatedAt.millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<GoalDayProgress?> dayProgress(String localDate) async {
    final row = await _database.studyGoalDao
        .findDayProgress(localDate)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Stream<GoalDayProgress?> watchDayProgress(String localDate) {
    return _database.studyGoalDao
        .watchDayProgress(localDate)
        .watchSingleOrNull()
        .map((row) => row?.toDomain());
  }
}

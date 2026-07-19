import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'streak_dao.g.dart';

/// Study Streak DAO (WBS 4.4B).
///
/// All SQL lives in `queries/streaks.drift`; recording a day is
/// idempotent through the unique local_date.
@DriftAccessor(include: {'../queries/streaks.drift'})
class StreakDao extends DatabaseAccessor<AppDatabase> with _$StreakDaoMixin {
  StreakDao(super.attachedDatabase);
}

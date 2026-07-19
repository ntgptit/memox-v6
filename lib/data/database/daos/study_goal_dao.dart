import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'study_goal_dao.g.dart';

/// Study Goal aggregate DAO (WBS 4.4B): goal configuration plus the
/// per-local-day progress bucket.
///
/// All SQL lives in `queries/study_goals.drift`.
@DriftAccessor(include: {'../queries/study_goals.drift'})
class StudyGoalDao extends DatabaseAccessor<AppDatabase>
    with _$StudyGoalDaoMixin {
  StudyGoalDao(super.attachedDatabase);
}

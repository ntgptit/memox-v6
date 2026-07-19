import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'learning_progress_dao.g.dart';

/// Learning Progress aggregate DAO (WBS 4.4B).
///
/// All SQL lives in `queries/learning_progress.drift`. The DAO is
/// mechanical: box/interval decisions come from the domain policy via
/// the repository layer; `updateProgressGuarded` only enforces
/// optimistic concurrency through the revision guard.
@DriftAccessor(include: {'../queries/learning_progress.drift'})
class LearningProgressDao extends DatabaseAccessor<AppDatabase>
    with _$LearningProgressDaoMixin {
  LearningProgressDao(super.attachedDatabase);
}

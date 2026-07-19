import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'study_attempt_dao.g.dart';

/// Study Attempt evidence DAO (WBS 4.4B).
///
/// All SQL lives in `queries/study_attempts.drift`. Append-only by
/// design: the query file defines no UPDATE or DELETE.
@DriftAccessor(include: {'../queries/study_attempts.drift'})
class StudyAttemptDao extends DatabaseAccessor<AppDatabase>
    with _$StudyAttemptDaoMixin {
  StudyAttemptDao(super.attachedDatabase);
}

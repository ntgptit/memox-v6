import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'study_session_dao.g.dart';

/// Study Session lifecycle DAO (WBS 4.4C).
///
/// All SQL lives in `queries/study_sessions.drift`. The single-active
/// partial index guards inserts; `updateSessionStateGuarded` makes
/// state transitions optimistic-concurrent via the revision guard.
@DriftAccessor(include: {'../queries/study_sessions.drift'})
class StudySessionDao extends DatabaseAccessor<AppDatabase>
    with _$StudySessionDaoMixin {
  StudySessionDao(super.attachedDatabase);
}

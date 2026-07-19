import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'session_checkpoint_dao.g.dart';

/// Session checkpoint and relearn-queue DAO (WBS 4.4C).
///
/// All SQL lives in `queries/session_checkpoints.drift`: one resumable
/// checkpoint per session (upsert-in-place) plus the deduplicated
/// relearn queue with its learning-retry counter.
@DriftAccessor(include: {'../queries/session_checkpoints.drift'})
class SessionCheckpointDao extends DatabaseAccessor<AppDatabase>
    with _$SessionCheckpointDaoMixin {
  SessionCheckpointDao(super.attachedDatabase);
}

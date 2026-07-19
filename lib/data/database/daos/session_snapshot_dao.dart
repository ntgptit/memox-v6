import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'session_snapshot_dao.g.dart';

/// Session snapshot DAO (WBS 4.4C): the per-session card snapshot and
/// deterministic per-round presentation order.
///
/// All SQL lives in `queries/session_snapshots.drift`.
@DriftAccessor(include: {'../queries/session_snapshots.drift'})
class SessionSnapshotDao extends DatabaseAccessor<AppDatabase>
    with _$SessionSnapshotDaoMixin {
  SessionSnapshotDao(super.attachedDatabase);
}

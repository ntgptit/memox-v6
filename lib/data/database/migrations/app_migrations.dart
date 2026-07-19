import 'package:drift/drift.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart';

/// Guided migration structure for the shared database (WBS 4.7;
/// `docs/database/migration-policy.md`).
///
/// - Every released schema version commits a snapshot under
///   `drift_schemas/` (rule 1); step-by-step upgrades for v2+ land in
///   [_upgrade], guided by those snapshots and verified against the
///   generated helpers in `test/data/database/generated_migrations/`.
/// - Integrity is validated before the database is used after an
///   upgrade (rule 3): a failed foreign-key check surfaces as a typed
///   corruption failure instead of silently serving a broken store.
MigrationStrategy buildAppMigration(AppDatabase database) {
  return MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: _upgrade,
    beforeOpen: (details) async {
      // FK contracts in schema v1 are load-bearing; SQLite leaves them
      // off per connection unless asked.
      await database.customStatement('PRAGMA foreign_keys = ON');
      if (details.hadUpgrade) {
        await _verifyIntegrity(database);
      }
    },
  );
}

Future<void> _upgrade(Migrator migrator, int from, int to) async {
  // Schema v1 is the first released version. Future versions add drift
  // step-by-step migrations here; never infer business-policy
  // migrations from the schema version alone (policy rule 6).
}

Future<void> _verifyIntegrity(AppDatabase database) async {
  final violations = await database
      .customSelect('PRAGMA foreign_key_check')
      .get();
  if (violations.isEmpty) return;
  throw DataCorruptionFailure(
    entity: 'database',
    field: 'foreign_key_check',
    value: violations.length,
  );
}

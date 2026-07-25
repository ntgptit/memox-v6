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
    onUpgrade: (migrator, from, to) => _upgrade(database, migrator, from, to),
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

Future<void> _upgrade(
  AppDatabase database,
  Migrator migrator,
  int from,
  int to,
) async {
  // Step-by-step, never a jump: each released version's step runs in order
  // so a store on v1 reaches v2 by the same path a future v1 → v3 store
  // will. Never infer business-policy migrations from the schema version
  // alone (policy rule 6) — see the v2 note below for what that forbids.
  if (from < 2) {
    await _upgradeToV2(database, migrator);
  }
}

/// v2 (WBS 5.4.4): give `SrsSchedule`'s two timestamps a column.
///
/// Both are added nullable and are **not** backfilled. `srs_activated_at`
/// means "when this card first entered Box 1", and for a row written under v1
/// that instant was never recorded — no column held it. The nearest available
/// value, `updated_at`, is the *last* review rather than the first
/// activation, so writing it here would not be a migration but a fabrication,
/// and every statistic later built on activation age would inherit it.
///
/// Existing rows therefore keep NULL, which readers disambiguate with `box`:
/// Box 0 has never been activated, while `box >= 1` with a NULL activation is
/// a pre-v2 row whose activation instant is unknown. That is the honest
/// state, and migration-policy.md rule 6 requires it — inventing the value
/// would be exactly the business-policy inference the rule forbids.
Future<void> _upgradeToV2(AppDatabase database, Migrator migrator) async {
  await migrator.addColumn(
    database.learningProgress,
    database.learningProgress.srsActivatedAt,
  );
  await migrator.addColumn(
    database.learningProgress,
    database.learningProgress.lastReviewedAt,
  );
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

import 'package:drift/drift.dart';
import 'package:memox_v6/core/database/database_opener.dart';
import 'package:memox_v6/data/database/daos/deck_dao.dart';
import 'package:memox_v6/data/database/daos/flashcard_dao.dart';
import 'package:memox_v6/data/database/daos/language_pair_dao.dart';
import 'package:memox_v6/data/database/daos/learning_progress_dao.dart';
import 'package:memox_v6/data/database/daos/preference_dao.dart';
import 'package:memox_v6/data/database/daos/session_checkpoint_dao.dart';
import 'package:memox_v6/data/database/daos/session_snapshot_dao.dart';
import 'package:memox_v6/data/database/daos/streak_dao.dart';
import 'package:memox_v6/data/database/daos/study_attempt_dao.dart';
import 'package:memox_v6/data/database/daos/study_goal_dao.dart';
import 'package:memox_v6/data/database/daos/study_session_dao.dart';

part 'app_database.g.dart';

/// Production database file name (without extension).
const String appDatabaseName = 'memox';

/// The one shared Drift database (WBS 4.1/4.2; ADR-004).
///
/// Schema v1 (`docs/database/schema-v1.md`) is defined SQL-first in
/// `.drift` files under `tables/` — never as Dart `Table` classes — so
/// the DDL stays reviewable against the accepted design. Web and Android
/// share this schema through the platform openers in `core/database`.
@DriftDatabase(
  include: {
    'tables/content.drift',
    'tables/progress.drift',
    'tables/sessions.drift',
    'tables/constraints.drift',
  },
  daos: [
    LanguagePairDao,
    DeckDao,
    FlashcardDao,
    LearningProgressDao,
    StudyAttemptDao,
    PreferenceDao,
    StudyGoalDao,
    StreakDao,
    StudySessionDao,
    SessionSnapshotDao,
    SessionCheckpointDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the production database through the platform opener.
  AppDatabase.open() : super(openAppDatabaseExecutor(name: appDatabaseName));

  /// Test/tooling constructor over an explicit executor (in-memory
  /// databases, migration fixtures).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // FK contracts in schema v1 are load-bearing; SQLite leaves them
      // off per connection unless asked.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

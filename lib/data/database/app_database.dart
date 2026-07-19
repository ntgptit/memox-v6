import 'package:drift/drift.dart';
import 'package:memox_v6/core/database/database_opener.dart';

part 'app_database.g.dart';

/// Production database file name (without extension).
const String appDatabaseName = 'memox';

/// The one shared Drift database (WBS 4.1; ADR-004).
///
/// Schema v1 tables land with WBS 4.2 (`docs/database/schema-v1.md` is the
/// accepted design); this runtime owns opening, versioning and lifecycle.
/// Web and Android share this schema through the platform openers in
/// `core/database`.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  /// Opens the production database through the platform opener.
  AppDatabase.open() : super(openAppDatabaseExecutor(name: appDatabaseName));

  /// Test/tooling constructor over an explicit executor (in-memory
  /// databases, migration fixtures).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

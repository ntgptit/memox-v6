import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';

/// Tier-1 database opener contract (WBS 1.10).
///
/// Runs the shared lifecycle contract against any executor factory: the
/// in-memory harness exercises it in unit tests today, and the same
/// group runs against the real Android/Web openers when the Tier-1
/// platform smoke (5.7.4/16.1) collects its evidence.
void runDatabaseLifecycleContract(
  String description,
  QueryExecutor Function() buildExecutor,
) {
  group(description, () {
    test('opens at schema v1 and answers queries', () async {
      final database = AppDatabase.forTesting(buildExecutor());
      addTearDown(database.close);

      final probe = await database
          .customSelect('SELECT 1 AS probe')
          .getSingle();
      expect(probe.read<int>('probe'), 1);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 1);
    });

    test('enforces foreign keys on the connection', () async {
      final database = AppDatabase.forTesting(buildExecutor());
      addTearDown(database.close);

      await expectLater(
        database.customStatement(
          'INSERT INTO decks (id, language_pair_id, parent_id, name, '
          "normalized_name, created_at, updated_at) "
          "VALUES ('d1', 'missing', NULL, 'a', 'a', 0, 0)",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('closes idempotently and rejects use after close', () async {
      final database = AppDatabase.forTesting(buildExecutor());

      await database.customSelect('SELECT 1').getSingle();
      await database.close();
      await database.close();

      expect(
        () => database.customSelect('SELECT 1').getSingle(),
        throwsA(isA<StateError>()),
      );
    });
  });
}

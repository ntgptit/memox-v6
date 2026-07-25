import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('schema snapshots (migration-policy rule 1)', () {
    // Only the current version can be checked against a fresh `createAll`;
    // an older snapshot is reached by upgrading into it, which is what the
    // v1 -> v2 group below does.
    test('a freshly created database matches the v2 snapshot', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await verifier.migrateAndValidate(database, 2);
    });
  });

  group('v1 -> v2 upgrade (WBS 5.4.4)', () {
    test('adds the two SRS timestamp columns', () async {
      final connection = await verifier.startAt(1);
      final database = AppDatabase.forTesting(connection.executor);
      addTearDown(database.close);

      await verifier.migrateAndValidate(database, 2);
    });

    test('a v1 row survives the upgrade with NULL timestamps', () async {
      final connection = await verifier.startAt(1);
      final database = AppDatabase.forTesting(connection.executor);
      addTearDown(database.close);

      // A card mid-ladder under v1: activated at some point nobody recorded,
      // because v1 had no column to record it in.
      await database.customStatement(
        'INSERT INTO language_pairs (id, learning_language_code, '
        'native_language_code, normalized_pair_key, created_at, updated_at) '
        "VALUES ('lp1', 'en', 'vi', 'en|vi', 0, 0)",
      );
      await database.customStatement(
        'INSERT INTO decks (id, language_pair_id, parent_id, name, '
        'normalized_name, created_at, updated_at) '
        "VALUES ('d1', 'lp1', NULL, 'a', 'a', 0, 0)",
      );
      await database.customStatement(
        'INSERT INTO flashcards (id, deck_id, term, normalized_term, '
        "primary_meaning, created_at, updated_at) "
        "VALUES ('c1', 'd1', 't', 't', 'm', 0, 0)",
      );
      await database.customStatement(
        'INSERT INTO learning_progress (id, card_id, box, due_at, '
        'repetition_count, lapse_count, created_at, updated_at) '
        "VALUES ('p1', 'c1', 3, 100, 4, 1, 0, 0)",
      );

      await verifier.migrateAndValidate(database, 2);

      final row = await database
          .customSelect(
            'SELECT box, srs_activated_at, last_reviewed_at '
            "FROM learning_progress WHERE id = 'p1'",
          )
          .getSingle();

      // The row keeps its place on the ladder...
      expect(row.read<int>('box'), 3);
      // ...and both new columns stay NULL. The migration does not guess an
      // activation instant from `updated_at`: that is the last review, not
      // the first activation, and fabricating it would be inferring business
      // policy from a schema version (migration-policy.md rule 6). Box 3 with
      // a NULL activation reads as "activated before v2, instant unknown" —
      // which is true — where Box 0 with NULL means "never activated".
      expect(row.read<int?>('srs_activated_at'), isNull);
      expect(row.read<int?>('last_reviewed_at'), isNull);
    });
  });

  group('integrity fixtures (migration-policy rule 3)', () {
    test('a seeded store passes foreign-key and integrity checks', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await database.customStatement(
        'INSERT INTO language_pairs (id, learning_language_code, '
        'native_language_code, normalized_pair_key, created_at, updated_at) '
        "VALUES ('lp1', 'en', 'vi', 'en|vi', 0, 0)",
      );
      await database.customStatement(
        'INSERT INTO decks (id, language_pair_id, parent_id, name, '
        'normalized_name, created_at, updated_at) '
        "VALUES ('d1', 'lp1', NULL, 'a', 'a', 0, 0)",
      );
      await database.customStatement(
        'INSERT INTO flashcards (id, deck_id, term, normalized_term, primary_meaning, '
        "created_at, updated_at) VALUES ('c1', 'd1', 't', 't', 'm', 0, 0)",
      );

      final fkViolations = await database
          .customSelect('PRAGMA foreign_key_check')
          .get();
      expect(fkViolations, isEmpty);

      final integrity = await database
          .customSelect('PRAGMA integrity_check')
          .getSingle();
      expect(integrity.read<String>('integrity_check'), 'ok');
    });
  });
}

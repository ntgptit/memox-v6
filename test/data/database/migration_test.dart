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

  group('schema v1 snapshot (migration-policy rule 1)', () {
    test('a freshly created database matches the exported snapshot', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await verifier.migrateAndValidate(database, 1);
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
        'INSERT INTO flashcards (id, deck_id, term, primary_meaning, '
        "created_at, updated_at) VALUES ('c1', 'd1', 't', 'm', 0, 0)",
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

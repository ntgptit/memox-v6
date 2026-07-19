import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertPair(String id, String key) {
    return database.customStatement(
      'INSERT INTO language_pairs (id, learning_language_code, '
      'native_language_code, normalized_pair_key, created_at, '
      'updated_at) VALUES (?, ?, ?, ?, 0, 0)',
      [id, 'en', 'vi', key],
    );
  }

  Future<void> insertDeck(String id, {String? parentId, String name = 'a'}) {
    return database.customStatement(
      'INSERT INTO decks (id, language_pair_id, parent_id, name, '
      'normalized_name, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, 0, 0)',
      [id, 'lp1', parentId, name, name],
    );
  }

  Future<void> insertCard(String id, {String deckId = 'd1'}) {
    return database.customStatement(
      'INSERT INTO flashcards (id, deck_id, term, primary_meaning, '
      'created_at, updated_at) VALUES (?, ?, ?, ?, 0, 0)',
      [id, deckId, 'term', 'meaning'],
    );
  }

  group('content schema DDL', () {
    test('creates every content table of schema v1', () async {
      final rows = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final tables = rows.map((row) => row.read<String>('name')).toSet();

      expect(
        tables,
        containsAll(<String>{
          'language_pairs',
          'decks',
          'flashcards',
          'flashcard_translations',
          'tags',
          'flashcard_tags',
          'card_audio_refs',
        }),
      );
    });

    test('normalized language pair key is unique', () async {
      await insertPair('lp1', 'en|vi');

      expect(() => insertPair('lp2', 'en|vi'), throwsA(isA<SqliteException>()));
    });

    test('foreign keys are enforced on the connection', () async {
      expect(() => insertDeck('d1'), throwsA(isA<SqliteException>()));
    });

    test('sibling deck names collide per parent, not across parents', () async {
      await insertPair('lp1', 'en|vi');
      await insertDeck('root1', name: 'travel');
      await insertDeck('root2', parentId: 'root1', name: 'travel');

      await expectLater(
        insertDeck('root3', name: 'travel'),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertDeck('root4', parentId: 'root1', name: 'travel'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('translation order is unique per card and language', () async {
      await insertPair('lp1', 'en|vi');
      await insertDeck('d1');
      await insertCard('c1');

      Future<void> insertTranslation(String id) {
        return database.customStatement(
          'INSERT INTO flashcard_translations (id, card_id, language_code, '
          'translation_text, display_order, created_at, updated_at) '
          "VALUES (?, 'c1', 'vi', 'nghĩa', 0, 0, 0)",
          [id],
        );
      }

      await insertTranslation('t1');

      expect(() => insertTranslation('t2'), throwsA(isA<SqliteException>()));
    });

    test('deleting a card cascades its tag joins and audio refs', () async {
      await insertPair('lp1', 'en|vi');
      await insertDeck('d1');
      await insertCard('c1');
      await database.customStatement(
        "INSERT INTO tags (id, name, normalized_name, created_at, "
        "updated_at) VALUES ('tag1', 'Verbs', 'verbs', 0, 0)",
      );
      await database.customStatement(
        "INSERT INTO flashcard_tags (card_id, tag_id, created_at) "
        "VALUES ('c1', 'tag1', 0)",
      );
      await database.customStatement(
        "INSERT INTO card_audio_refs (id, card_id, language_code, asset_id, "
        "provider, created_at, updated_at) "
        "VALUES ('a1', 'c1', 'en', 'asset-1', 'tts-v1', 0, 0)",
      );

      await database.customStatement("DELETE FROM flashcards WHERE id = 'c1'");

      final joins = await database
          .customSelect('SELECT COUNT(*) AS n FROM flashcard_tags')
          .getSingle();
      final refs = await database
          .customSelect('SELECT COUNT(*) AS n FROM card_audio_refs')
          .getSingle();
      expect(joins.read<int>('n'), 0);
      expect(refs.read<int>('n'), 0);
    });
  });
}

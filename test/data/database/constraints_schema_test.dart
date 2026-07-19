import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    await database.customStatement(
      'INSERT INTO language_pairs (id, learning_language_code, '
      'native_language_code, normalized_pair_key, created_at, updated_at) '
      "VALUES ('lp1', 'en', 'vi', 'en|vi', 0, 0)",
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertDeck(String id, {String? parentId, String? name}) {
    return database.customStatement(
      'INSERT INTO decks (id, language_pair_id, parent_id, name, '
      'normalized_name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, 0)',
      [id, 'lp1', parentId, name ?? id, name ?? id],
    );
  }

  Future<void> insertCard(String id, String deckId) {
    return database.customStatement(
      'INSERT INTO flashcards (id, deck_id, term, normalized_term, '
      'primary_meaning, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, 0)',
      [id, deckId, 'term-$id', 'term-$id', 'meaning-$id'],
    );
  }

  Matcher throwsAbortWith(String tag) {
    return throwsA(
      isA<SqliteException>().having(
        (error) => error.message,
        'message',
        contains(tag),
      ),
    );
  }

  group('deck exclusivity', () {
    test('a card-holding deck rejects child decks, in both orders', () async {
      await insertDeck('cards');
      await insertCard('c1', 'cards');

      await expectLater(
        insertDeck('child', parentId: 'cards'),
        throwsAbortWith('deck-mixed-content'),
      );

      await insertDeck('parent');
      await insertDeck('sub', parentId: 'parent');

      await expectLater(
        insertCard('c2', 'parent'),
        throwsAbortWith('deck-mixed-content'),
      );
    });

    test('soft-deleted cards no longer count as deck content', () async {
      await insertDeck('cards');
      await insertCard('c1', 'cards');

      await database.customStatement(
        "UPDATE flashcards SET deleted_at = 1 WHERE id = 'c1'",
      );

      await insertDeck('child', parentId: 'cards');

      await expectLater(
        database.customStatement(
          "UPDATE flashcards SET deleted_at = NULL WHERE id = 'c1'",
        ),
        throwsAbortWith('deck-mixed-content'),
      );
    });

    test('moves re-check exclusivity on the destination', () async {
      await insertDeck('cards');
      await insertCard('c1', 'cards');
      await insertDeck('tree');
      await insertDeck('leaf', parentId: 'tree');

      await expectLater(
        database.customStatement(
          "UPDATE decks SET parent_id = 'cards' WHERE id = 'leaf'",
        ),
        throwsAbortWith('deck-mixed-content'),
      );
      await expectLater(
        database.customStatement(
          "UPDATE flashcards SET deck_id = 'tree' WHERE id = 'c1'",
        ),
        throwsAbortWith('deck-mixed-content'),
      );
    });

    test(
      'a violating write inside a transaction rolls back atomically',
      () async {
        await insertDeck('parent');
        await insertDeck('sub', parentId: 'parent');

        await expectLater(
          database.transaction(() async {
            await insertDeck('sibling', parentId: 'sub');
            await insertCard('c1', 'parent');
          }),
          throwsAbortWith('deck-mixed-content'),
        );

        final rows = await database
            .customSelect(
              "SELECT COUNT(*) AS n FROM decks WHERE id = 'sibling'",
            )
            .getSingle();
        expect(rows.read<int>('n'), 0);
      },
    );
  });

  group('deck tree stays acyclic', () {
    test('self-parenting is rejected on insert and move', () async {
      await expectLater(
        insertDeck('loop', parentId: 'loop'),
        throwsAbortWith('deck-cycle'),
      );

      await insertDeck('a');
      await expectLater(
        database.customStatement(
          "UPDATE decks SET parent_id = 'a' WHERE id = 'a'",
        ),
        throwsAbortWith('deck-cycle'),
      );
    });

    test('a deck may not move under its own descendant', () async {
      await insertDeck('a');
      await insertDeck('b', parentId: 'a');
      await insertDeck('c', parentId: 'b');

      await expectLater(
        database.customStatement(
          "UPDATE decks SET parent_id = 'c' WHERE id = 'a'",
        ),
        throwsAbortWith('deck-cycle'),
      );
      await expectLater(
        database.customStatement(
          "UPDATE decks SET parent_id = 'b' WHERE id = 'a'",
        ),
        throwsAbortWith('deck-cycle'),
      );
    });

    test('legitimate reparenting still works', () async {
      await insertDeck('a');
      await insertDeck('b', parentId: 'a');
      await insertDeck('c', parentId: 'b');

      await database.customStatement(
        "UPDATE decks SET parent_id = 'a' WHERE id = 'c'",
      );

      final row = await database
          .customSelect("SELECT parent_id FROM decks WHERE id = 'c'")
          .getSingle();
      expect(row.read<String>('parent_id'), 'a');
    });
  });
}

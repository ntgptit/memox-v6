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
    await database.customStatement(
      'INSERT INTO decks (id, language_pair_id, parent_id, name, '
      'normalized_name, created_at, updated_at) '
      "VALUES ('d1', 'lp1', NULL, 'a', 'a', 0, 0)",
    );
    await database.customStatement(
      'INSERT INTO flashcards (id, deck_id, term, primary_meaning, '
      "created_at, updated_at) VALUES ('c1', 'd1', 't', 'm', 0, 0)",
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertSession(String id, {String state = 'active'}) {
    return database.customStatement(
      'INSERT INTO study_sessions (id, session_type, deck_id, scope, state, '
      "started_at, created_at, updated_at) VALUES (?, 'newLearning', 'd1', "
      "'leaf', ?, 0, 0, 0)",
      [id, state],
    );
  }

  Future<void> insertSessionCard(
    String id, {
    String cardId = 'c1',
    int order = 0,
  }) {
    return database.customStatement(
      'INSERT INTO study_session_cards (id, session_id, card_id, '
      'display_order, term_snapshot, meaning_snapshot, content_version, '
      'progress_box_snapshot, progress_revision, created_at) '
      "VALUES (?, 's1', ?, ?, 't', 'm', 1, 0, 0, 0)",
      [id, cardId, order],
    );
  }

  group('session schema DDL', () {
    test('creates every session runtime table of schema v1', () async {
      final rows = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final tables = rows.map((row) => row.read<String>('name')).toSet();

      expect(
        tables,
        containsAll(<String>{
          'study_sessions',
          'study_session_cards',
          'study_checkpoints',
          'study_round_orders',
          'session_relearn_items',
        }),
      );
    });

    test('only one active session may exist', () async {
      await insertSession('s1');

      await expectLater(insertSession('s2'), throwsA(isA<SqliteException>()));

      await insertSession('s3', state: 'completed');
    });

    test('session type, scope and state are constrained', () async {
      await expectLater(
        database.customStatement(
          'INSERT INTO study_sessions (id, session_type, deck_id, scope, '
          "state, started_at, created_at, updated_at) VALUES ('s1', "
          "'cramming', 'd1', 'leaf', 'active', 0, 0, 0)",
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        database.customStatement(
          'INSERT INTO study_sessions (id, session_type, deck_id, scope, '
          "state, started_at, created_at, updated_at) VALUES ('s1', "
          "'practice', 'd1', 'leaf', 'paused', 0, 0, 0)",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('session cards are unique per card and per order slot', () async {
      await insertSession('s1');
      await insertSessionCard('sc1');

      await expectLater(
        insertSessionCard('sc2', order: 1),
        throwsA(isA<SqliteException>()),
      );
      await database.customStatement(
        'INSERT INTO flashcards (id, deck_id, term, primary_meaning, '
        "created_at, updated_at) VALUES ('c2', 'd1', 't2', 'm2', 0, 0)",
      );
      await expectLater(
        insertSessionCard('sc3', cardId: 'c2', order: 0),
        throwsA(isA<SqliteException>()),
      );
    });

    test('one checkpoint per session; one order per round', () async {
      await insertSession('s1');

      Future<void> insertCheckpoint(String id) {
        return database.customStatement(
          'INSERT INTO study_checkpoints (id, session_id, updated_at) '
          "VALUES (?, 's1', 0)",
          [id],
        );
      }

      Future<void> insertRoundOrder(String id) {
        return database.customStatement(
          'INSERT INTO study_round_orders (id, session_id, round_index, '
          "seed, card_order_json, created_at) VALUES (?, 's1', 0, 42, "
          "'[]', 0)",
          [id],
        );
      }

      await insertCheckpoint('cp1');
      await insertRoundOrder('ro1');

      await expectLater(
        insertCheckpoint('cp2'),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertRoundOrder('ro2'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('relearn items deduplicate a failed card per session', () async {
      await insertSession('s1');

      Future<void> insertRelearnItem(String id) {
        return database.customStatement(
          'INSERT INTO session_relearn_items (id, session_id, card_id, '
          "created_at) VALUES (?, 's1', 'c1', 0)",
          [id],
        );
      }

      await insertRelearnItem('r1');

      expect(() => insertRelearnItem('r2'), throwsA(isA<SqliteException>()));
    });

    test('attempts now reference sessions through an enforced FK', () async {
      Future<void> insertAttempt(String id, String? sessionId) {
        return database.customStatement(
          'INSERT INTO study_attempts (id, idempotency_key, card_id, '
          'session_id, mode_id, outcome, evidence_json, created_at) '
          "VALUES (?, ?, 'c1', ?, 'guess', 'correct', '{}', 0)",
          [id, 'key-$id', sessionId],
        );
      }

      await insertAttempt('a1', null);

      await expectLater(
        insertAttempt('a2', 'missing-session'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting a session cascades its runtime children', () async {
      await insertSession('s1');
      await insertSessionCard('sc1');
      await database.customStatement(
        "INSERT INTO study_checkpoints (id, session_id, updated_at) "
        "VALUES ('cp1', 's1', 0)",
      );
      await database.customStatement(
        'INSERT INTO study_round_orders (id, session_id, round_index, seed, '
        "card_order_json, created_at) VALUES ('ro1', 's1', 0, 42, '[]', 0)",
      );
      await database.customStatement(
        'INSERT INTO session_relearn_items (id, session_id, card_id, '
        "created_at) VALUES ('r1', 's1', 'c1', 0)",
      );

      await database.customStatement(
        "DELETE FROM study_sessions WHERE id = 's1'",
      );

      for (final table in [
        'study_session_cards',
        'study_checkpoints',
        'study_round_orders',
        'session_relearn_items',
      ]) {
        final row = await database
            .customSelect('SELECT COUNT(*) AS n FROM $table')
            .getSingle();
        expect(row.read<int>('n'), 0, reason: table);
      }
    });
  });
}

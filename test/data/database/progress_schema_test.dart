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
      'native_language_code, normalized_pair_key, created_at, '
      "updated_at) VALUES ('lp1', 'en', 'vi', 'en|vi', 0, 0)",
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

  Future<void> insertProgress(
    String id, {
    String cardId = 'c1',
    int box = 0,
    int? dueAtUtc,
  }) {
    return database.customStatement(
      'INSERT INTO learning_progress (id, card_id, box, due_at, '
      'created_at, updated_at) VALUES (?, ?, ?, ?, 0, 0)',
      [id, cardId, box, dueAtUtc],
    );
  }

  group('progress schema DDL', () {
    test('creates every progress and rhythm table of schema v1', () async {
      final rows = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final tables = rows.map((row) => row.read<String>('name')).toSet();

      expect(
        tables,
        containsAll(<String>{
          'study_attempts',
          'learning_progress',
          'preferences',
          'daily_goals',
          'goal_day_progress',
          'streak_days',
        }),
      );
    });

    test('learning progress keeps one row per card', () async {
      await insertProgress('p1');

      expect(() => insertProgress('p2'), throwsA(isA<SqliteException>()));
    });

    test('box range and box/due-date shape are enforced', () async {
      await expectLater(
        insertProgress('p1', box: 9),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertProgress('p2', box: 0, dueAtUtc: 10),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertProgress('p3', box: 3),
        throwsA(isA<SqliteException>()),
      );

      await insertProgress('p4', box: 8);
    });

    test('progress defaults carry the baseline policy identity', () async {
      await insertProgress('p1');

      final row = await database
          .customSelect(
            'SELECT policy_id, policy_version, revision FROM '
            "learning_progress WHERE id = 'p1'",
          )
          .getSingle();
      expect(row.read<String>('policy_id'), 'leitner-8-box-v1');
      expect(row.read<int>('policy_version'), 1);
      expect(row.read<int>('revision'), 0);
    });

    test('attempt idempotency keys are unique', () async {
      Future<void> insertAttempt(String id) {
        return database.customStatement(
          'INSERT INTO study_attempts (id, idempotency_key, card_id, '
          'mode_id, outcome, evidence_json, created_at) '
          "VALUES (?, 'key-1', 'c1', 'guess', 'correct', '{}', 0)",
          [id],
        );
      }

      await insertAttempt('a1');

      expect(() => insertAttempt('a2'), throwsA(isA<SqliteException>()));
    });

    test('local dates are unique for goal buckets and streak days', () async {
      await database.customStatement(
        'INSERT INTO daily_goals (id, target_card_count, '
        'effective_from_local_date, timezone_id, created_at, '
        "updated_at) VALUES ('g1', 10, '2026-07-19', 'Asia/Ho_Chi_Minh', "
        '0, 0)',
      );

      Future<void> insertBucket(String id) {
        return database.customStatement(
          'INSERT INTO goal_day_progress (id, local_date, timezone_id, '
          'goal_id, target_snapshot, created_at, updated_at) '
          "VALUES (?, '2026-07-19', 'Asia/Ho_Chi_Minh', 'g1', 10, 0, 0)",
          [id],
        );
      }

      Future<void> insertStreakDay(String id) {
        return database.customStatement(
          'INSERT INTO streak_days (id, local_date, timezone_id, '
          'qualified_source, created_at) '
          "VALUES (?, '2026-07-19', 'Asia/Ho_Chi_Minh', 'metrics-v1', 0)",
          [id],
        );
      }

      await insertBucket('b1');
      await insertStreakDay('s1');

      await expectLater(insertBucket('b2'), throwsA(isA<SqliteException>()));
      await expectLater(insertStreakDay('s2'), throwsA(isA<SqliteException>()));
    });

    test('deleting a card removes its progress row', () async {
      await insertProgress('p1');

      await database.customStatement("DELETE FROM flashcards WHERE id = 'c1'");

      final rows = await database
          .customSelect('SELECT COUNT(*) AS n FROM learning_progress')
          .getSingle();
      expect(rows.read<int>('n'), 0);
    });
  });
}

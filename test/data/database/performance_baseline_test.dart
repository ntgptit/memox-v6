import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';
import 'package:memox_v6/data/database/query_limits.dart';
import 'package:memox_v6/data/dev/dev_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  /// Concatenated `EXPLAIN QUERY PLAN` detail for [sql].
  Future<String> plan(String sql) async {
    final rows = await database.customSelect('EXPLAIN QUERY PLAN $sql').get();
    return rows.map((row) => row.read<String>('detail')).join('\n');
  }

  group('query plans use their indexes (no full scans on hot paths)', () {
    test('card paging per deck searches idx_flashcards_deck', () async {
      final detail = await plan(
        'SELECT * FROM flashcards '
        "WHERE deck_id = 'd1' AND deleted_at IS NULL "
        'ORDER BY created_at, id LIMIT 25 OFFSET 0',
      );
      expect(detail, contains('idx_flashcards_deck'));
    });

    test('the due queue searches the due-date index', () async {
      final detail = await plan(
        'SELECT learning_progress.* FROM learning_progress '
        'INNER JOIN flashcards ON flashcards.id = learning_progress.card_id '
        'WHERE learning_progress.due_at IS NOT NULL '
        'AND learning_progress.due_at <= 0 '
        'AND flashcards.deleted_at IS NULL AND flashcards.is_hidden = 0 '
        'ORDER BY learning_progress.due_at, learning_progress.id '
        'LIMIT 25 OFFSET 0',
      );
      expect(detail, contains('idx_learning_progress_due'));
    });

    test('deck listings search the sibling-name partial indexes', () async {
      final roots = await plan(
        "SELECT * FROM decks WHERE language_pair_id = 'lp' "
        'AND parent_id IS NULL ORDER BY normalized_name, id',
      );
      expect(roots, contains('idx_decks_root_sibling_name'));

      final children = await plan(
        "SELECT * FROM decks WHERE parent_id = 'root' "
        'ORDER BY normalized_name, id',
      );
      expect(children, contains('idx_decks_child_sibling_name'));
    });

    test('attempt replay lookup uses the unique idempotency index', () async {
      final detail = await plan(
        "SELECT * FROM study_attempts WHERE idempotency_key = 'k'",
      );
      expect(detail.toUpperCase(), contains('USING'));
      expect(detail, contains('idempotency_key'));
    });
  });

  group('pagination and stream limits', () {
    test('page-size policy clamps into 1..maxPageSize', () {
      expect(QueryLimits.clampPageSize(0), 1);
      expect(QueryLimits.clampPageSize(25), 25);
      expect(QueryLimits.clampPageSize(1000), QueryLimits.maxPageSize);
      expect(QueryLimits.defaultPageSize <= QueryLimits.maxPageSize, isTrue);
    });

    test(
      'dense-library paging honors LIMIT and stays inside the budget',
      () async {
        await DevFixtures(database).seed(DevFixtureState.dense);

        final stopwatch = Stopwatch()..start();
        final page = await database.flashcardDao
            .pageFlashcardsByDeck('fix-deck-0', QueryLimits.defaultPageSize, 0)
            .get();
        stopwatch.stop();

        expect(page.length, QueryLimits.defaultPageSize);
        // Generous unit-test budget: the packet's real latency budget is
        // 50ms per page on-device; here we only catch order-of-magnitude
        // regressions without becoming flaky.
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      },
    );

    test(
      'deck streams emit bounded first snapshots on a dense library',
      () async {
        await DevFixtures(database).seed(DevFixtureState.dense);

        final first = await database.flashcardDao
            .watchFlashcardsByDeck('fix-deck-1')
            .watch()
            .first;
        expect(first.length, 25);
      },
    );
  });
}

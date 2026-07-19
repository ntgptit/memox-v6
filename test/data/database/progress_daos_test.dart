import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Travel',
      'travel',
      0,
      0,
    );
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd1',
      't',
      't',
      'm',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('LearningProgressDao', () {
    test('revision guard accepts the expected revision only', () async {
      await database.learningProgressDao.insertProgress(
        'p1',
        'c1',
        0,
        null,
        0,
        0,
      );

      final stale = await database.learningProgressDao.updateProgressGuarded(
        1,
        100,
        1,
        0,
        null,
        1,
        'c1',
        7,
      );
      expect(stale, 0);

      final applied = await database.learningProgressDao.updateProgressGuarded(
        1,
        100,
        1,
        0,
        null,
        1,
        'c1',
        0,
      );
      expect(applied, 1);

      final row = await database.learningProgressDao
          .findProgressByCard('c1')
          .getSingle();
      expect(row.box, 1);
      expect(row.revision, 1);
      expect(row.dueAt, 100);
    });

    test('due paging excludes future, hidden and deleted cards', () async {
      await database.flashcardDao.insertFlashcard(
        'c2',
        'd1',
        't2',
        't2',
        'm2',
        0,
        0,
      );
      await database.flashcardDao.insertFlashcard(
        'c3',
        'd1',
        't3',
        't3',
        'm3',
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p1',
        'c1',
        1,
        50,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p2',
        'c2',
        1,
        60,
        0,
        0,
      );
      await database.learningProgressDao.insertProgress(
        'p3',
        'c3',
        1,
        999,
        0,
        0,
      );

      await database.flashcardDao.setFlashcardHidden(1, 1, 'c2');

      final due = await database.learningProgressDao
          .pageDueProgress(100, 10, 0)
          .get();
      expect(due.map((row) => row.cardId), ['c1']);

      final count = await database.learningProgressDao
          .countDueProgress(100)
          .getSingle();
      expect(count, 1);
    });
  });

  group('StudyAttemptDao', () {
    test('finds by idempotency key and pages newest-first', () async {
      await database.studyAttemptDao.insertAttempt(
        'a1',
        'k1',
        'c1',
        null,
        'guess',
        'correct',
        '{}',
        1,
        10,
      );
      await database.studyAttemptDao.insertAttempt(
        'a2',
        'k2',
        'c1',
        null,
        'guess',
        'wrong',
        '{}',
        1,
        20,
      );

      final byKey = await database.studyAttemptDao
          .findAttemptByIdempotencyKey('k2')
          .getSingle();
      expect(byKey.outcome, 'wrong');

      final page = await database.studyAttemptDao
          .pageAttemptsForCard('c1', 1, 0)
          .get();
      expect(page.single.id, 'a2');
    });
  });

  group('PreferenceDao', () {
    test('upsert overwrites in place and watch sees it', () async {
      await database.preferenceDao.upsertPreference(
        'appearance',
        '{"mode":"dark"}',
        1,
        10,
      );
      await database.preferenceDao.upsertPreference(
        'appearance',
        '{"mode":"light"}',
        1,
        20,
      );

      final row = await database.preferenceDao
          .findPreference('appearance')
          .getSingle();
      expect(row.valueJson, '{"mode":"light"}');
      expect(row.updatedAt, 20);

      final all = await database
          .customSelect('SELECT COUNT(*) AS n FROM preferences')
          .getSingle();
      expect(all.read<int>('n'), 1);
    });
  });

  group('StudyGoalDao', () {
    test('day bucket upserts by local date and reports met state', () async {
      await database.studyGoalDao.insertGoal(
        'g1',
        1,
        10,
        '2026-07-19',
        'Asia/Ho_Chi_Minh',
        0,
        0,
      );

      await database.studyGoalDao.upsertDayProgress(
        'b1',
        '2026-07-19',
        'Asia/Ho_Chi_Minh',
        'g1',
        4,
        10,
        0,
        0,
        5,
      );
      await database.studyGoalDao.upsertDayProgress(
        'b2',
        '2026-07-19',
        'Asia/Ho_Chi_Minh',
        'g1',
        10,
        10,
        1,
        0,
        6,
      );

      final bucket = await database.studyGoalDao
          .findDayProgress('2026-07-19')
          .getSingle();
      expect(bucket.id, 'b1');
      expect(bucket.qualifiedCardCount, 10);
      expect(bucket.isMet, 1);

      final latest = await database.studyGoalDao.findLatestGoal().getSingle();
      expect(latest.id, 'g1');
    });
  });

  group('StreakDao', () {
    test('recording a day is idempotent and ranges list in order', () async {
      await database.streakDao.recordStreakDay(
        's1',
        '2026-07-18',
        'Asia/Ho_Chi_Minh',
        'metrics-v1',
        0,
      );
      await database.streakDao.recordStreakDay(
        's2',
        '2026-07-19',
        'Asia/Ho_Chi_Minh',
        'metrics-v1',
        0,
      );
      await database.streakDao.recordStreakDay(
        's3',
        '2026-07-19',
        'Asia/Ho_Chi_Minh',
        'metrics-v1',
        0,
      );

      final count = await database.streakDao.countStreakDays().getSingle();
      expect(count, 2);

      final range = await database.streakDao
          .listStreakDaysBetween('2026-07-18', '2026-07-19')
          .get();
      expect(range.map((day) => day.localDate), ['2026-07-18', '2026-07-19']);
      expect(range.first.id, 's1');
    });
  });
}

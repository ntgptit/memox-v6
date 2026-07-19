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
    await database.flashcardDao.insertFlashcard('c1', 'd1', 't', 'm', 0, 0);
    await database.studySessionDao.insertSession(
      's1',
      'newLearning',
      'd1',
      'leaf',
      'active',
      1,
      0,
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('StudySessionDao', () {
    test('watchActiveSession sees the single active session', () async {
      final active = await database.studySessionDao
          .watchActiveSession()
          .getSingle();
      expect(active.id, 's1');
    });

    test('state transitions are revision-guarded and clear active', () async {
      final stale = await database.studySessionDao.updateSessionStateGuarded(
        'completed',
        100,
        100,
        's1',
        9,
      );
      expect(stale, 0);

      final applied = await database.studySessionDao.updateSessionStateGuarded(
        'completed',
        100,
        100,
        's1',
        0,
      );
      expect(applied, 1);

      final finalized = await database.studySessionDao
          .findSessionById('s1')
          .getSingle();
      expect(finalized.state, 'completed');
      expect(finalized.revision, 1);
      expect(finalized.finalizedAt, 100);

      final active = await database.studySessionDao
          .watchActiveSession()
          .getSingleOrNull();
      expect(active, isNull);
    });
  });

  group('SessionSnapshotDao', () {
    test('lists the card snapshot in display order', () async {
      await database.flashcardDao.insertFlashcard('c2', 'd1', 't2', 'm2', 0, 0);
      await database.sessionSnapshotDao.insertSessionCard(
        'sc2',
        's1',
        'c2',
        1,
        't2',
        'm2',
        1,
        0,
        0,
        0,
      );
      await database.sessionSnapshotDao.insertSessionCard(
        'sc1',
        's1',
        'c1',
        0,
        't',
        'm',
        1,
        0,
        0,
        0,
      );

      final cards = await database.sessionSnapshotDao
          .listSessionCards('s1')
          .get();
      expect(cards.map((card) => card.cardId), ['c1', 'c2']);

      final count = await database.sessionSnapshotDao
          .countSessionCards('s1')
          .getSingle();
      expect(count, 2);
    });

    test('round orders are found per round', () async {
      await database.sessionSnapshotDao.insertRoundOrder(
        'ro0',
        's1',
        0,
        42,
        '["c1"]',
        0,
      );
      await database.sessionSnapshotDao.insertRoundOrder(
        'ro1',
        's1',
        1,
        43,
        '["c1"]',
        0,
      );

      final round1 = await database.sessionSnapshotDao
          .findRoundOrder('s1', 1)
          .getSingle();
      expect(round1.seed, 43);
    });
  });

  group('SessionCheckpointDao', () {
    test('checkpoint upserts in place per session', () async {
      await database.sessionCheckpointDao.upsertCheckpoint(
        'cp1',
        's1',
        0,
        0,
        0,
        '[]',
        '{}',
        1,
        5,
      );
      await database.sessionCheckpointDao.upsertCheckpoint(
        'cp2',
        's1',
        2,
        1,
        3,
        '["c1"]',
        '{}',
        1,
        6,
      );

      final checkpoint = await database.sessionCheckpointDao
          .findCheckpoint('s1')
          .getSingle();
      expect(checkpoint.id, 'cp1');
      expect(checkpoint.stageIndex, 2);
      expect(checkpoint.cardPosition, 3);
      expect(checkpoint.failedSetJson, '["c1"]');
    });

    test('relearn queue deduplicates, bumps retries and clears', () async {
      await database.sessionCheckpointDao.addRelearnItem('r1', 's1', 'c1', 0);
      await database.sessionCheckpointDao.addRelearnItem('r2', 's1', 'c1', 1);
      await database.sessionCheckpointDao.bumpRelearnRetry('s1', 'c1');

      final items = await database.sessionCheckpointDao
          .listRelearnItems('s1')
          .get();
      expect(items.single.id, 'r1');
      expect(items.single.retryCount, 1);

      await database.sessionCheckpointDao.removeRelearnItem('s1', 'c1');
      expect(
        await database.sessionCheckpointDao.listRelearnItems('s1').get(),
        isEmpty,
      );
    });
  });
}

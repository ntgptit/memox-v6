import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';

/// WBS 5.4.1 — idempotent New-state initialise / safe repair
/// (`initialise-card-progress.md`).
void main() {
  late db.AppDatabase database;
  late DriftLearningProgressRepository repo;

  final now = DateTime.utc(2026, 7, 23);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftLearningProgressRepository(database);
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D', 'd', 0, 0);
  });

  tearDown(() => database.close());

  Future<int> progressCount(String cardId) async {
    final row = await database
        .customSelect(
          'SELECT COUNT(*) AS n FROM learning_progress WHERE card_id = ?',
          variables: [Variable<String>(cardId)],
        )
        .getSingle();
    return row.read<int>('n');
  }

  test('repairs a card missing its progress to a New state', () async {
    // A raw card row (no progress) — the DAO insert does not seed progress.
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd1',
      't',
      't',
      'm',
      0,
      0,
    );

    final p = await repo.ensureInitialProgress(
      id: 'progress-c1',
      cardId: 'c1',
      nowUtc: now,
    );

    expect(p.box, 0);
    expect(p.dueAt, isNull);
    expect(p.policyId, 'leitner-8-box-v1');
    expect(await progressCount('c1'), 1);
  });

  test(
    'is idempotent — returns the existing state without resetting it',
    () async {
      await database.flashcardDao.insertFlashcard(
        'c1',
        'd1',
        't',
        't',
        'm',
        0,
        0,
      );
      // A learned card: Box 5 with a due date (boxes 1..7 carry one).
      await database.learningProgressDao.insertProgress(
        'progress-c1',
        'c1',
        5,
        1000,
        0,
        0,
      );

      final p = await repo.ensureInitialProgress(
        id: 'progress-c1',
        cardId: 'c1',
        nowUtc: now,
      );

      expect(p.box, 5, reason: 'a learned card must not be reset to New');
      expect(await progressCount('c1'), 1);
    },
  );

  test('creates no orphan progress for a missing card', () async {
    // No card 'ghost' exists; the card_id FK must prevent an orphan row.
    await expectLater(
      repo.ensureInitialProgress(
        id: 'progress-ghost',
        cardId: 'ghost',
        nowUtc: now,
      ),
      throwsA(anything),
    );
    expect(await progressCount('ghost'), 0);
  });
}

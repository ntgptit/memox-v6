import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_candidates_usecase.dart';

/// WBS 5.4.2 — due/new scoped queue policy (`surface-due-cards.md` §§4,5,7).
void main() {
  late db.AppDatabase database;
  late DriftLearningProgressRepository repo;

  final now = DateTime.utc(2026, 7, 23, 12);
  final nowMs = now.millisecondsSinceEpoch;

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
  });

  tearDown(() => database.close());

  Future<void> deck(String id, {String? parent}) =>
      database.deckDao.insertDeck(id, 'lp1', parent, id, id, 0, 0);

  Future<void> card(
    String id,
    String deckId, {
    required int box,
    int? dueAt,
    bool hidden = false,
    bool deleted = false,
  }) async {
    await database.flashcardDao.insertFlashcard(id, deckId, id, id, 'm', 0, 0);
    await database.learningProgressDao.insertProgress(
      'p-$id',
      id,
      box,
      dueAt,
      0,
      0,
    );
    if (hidden) {
      await database.customStatement(
        "UPDATE flashcards SET is_hidden = 1 WHERE id = '$id'",
      );
    }
    if (deleted) {
      await database.customStatement(
        "UPDATE flashcards SET deleted_at = 1 WHERE id = '$id'",
      );
    }
  }

  test(
    // SRS8-013 (Box 1..7 dueAt == nowUtc → Due), 014 (Box 8 excluded from
    // queues), 015 (hidden due card excluded), 025 (deleted card excluded).
    'classifies new / due and excludes mastered, future, hidden, deleted',
    () async {
      await deck('d');
      await card('cn', 'd', box: 0); // new
      await card('cd', 'd', box: 3, dueAt: nowMs - 1000); // due (past)
      await card('cb', 'd', box: 3, dueAt: nowMs); // due (equal = due)
      await card('cf', 'd', box: 3, dueAt: nowMs + 1000); // future → not
      await card('cm', 'd', box: 8); // mastered → not
      await card('chh', 'd', box: 3, dueAt: nowMs - 1000, hidden: true);
      await card('cdel', 'd', box: 3, dueAt: nowMs - 1000, deleted: true);

      final q = await repo.studyCandidatesInScope(
        scopeDeckId: 'd',
        nowUtc: now,
      );

      expect(q.newCardIds, ['cn']);
      expect(q.dueCardIds.toSet(), {'cd', 'cb'});
      expect(q.dueCount, 2);
      expect(q.newCount, 1);
    },
  );

  test(
    'parent scope aggregates descendant leaves without double-count; leaf scope is direct',
    () async {
      await deck('p');
      await deck('l1', parent: 'p');
      await deck('l2', parent: 'p');
      await card('a', 'l1', box: 0); // new
      await card('b', 'l2', box: 3, dueAt: nowMs - 1); // due

      final parent = await repo.studyCandidatesInScope(
        scopeDeckId: 'p',
        nowUtc: now,
      );
      expect(parent.newCardIds, ['a']);
      expect(parent.dueCardIds, ['b']);
      // No double-count: two distinct cards, one each.
      expect(parent.newCount + parent.dueCount, 2);

      final leaf = await repo.studyCandidatesInScope(
        scopeDeckId: 'l1',
        nowUtc: now,
      );
      expect(leaf.newCardIds, ['a']);
      expect(leaf.dueCardIds, isEmpty);
    },
  );

  test('an empty deck yields no candidates', () async {
    await deck('d');
    final q = await repo.studyCandidatesInScope(scopeDeckId: 'd', nowUtc: now);
    expect(q.isEmpty, isTrue);
  });

  test(
    'the use case caps the new queue at the given limit; due is never capped',
    () async {
      await deck('d');
      await card('n1', 'd', box: 0);
      await card('n2', 'd', box: 0);
      await card('n3', 'd', box: 0);
      // Far-past due dates so they are due under the real SystemClock.
      await card('d1', 'd', box: 3, dueAt: 1);
      await card('d2', 'd', box: 3, dueAt: 2);

      final useCase = LoadStudyCandidatesUseCase(
        repository: repo,
        clock: const SystemClock(),
      );
      final q = await useCase.call('d', newLimit: 2);

      expect(q.newCardIds.length, 2);
      expect(q.dueCardIds.length, 2, reason: 'the due queue is never limited');
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';

import '../../support/restart_harness.dart';

/// WBS 5.4.4 child C — exactly-once terminal scheduling across a process
/// restart (`SRS8-011`).
///
/// The in-memory suite proves a replay is deduped inside one connection. That
/// leaves the question this file exists for: is the dedupe a property of the
/// *store*, or of the object graph that happens to still be alive? Those look
/// identical until the app is killed mid-session — a crash after a grade
/// commits, a phone reboot, a tab closed — and the client retries on the next
/// launch against a brand-new connection and a brand-new repository.
///
/// The restart harness is file-backed, so closing and reopening replays that
/// exactly: same store, nothing carried over in memory.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epoch = DateTime.utc(2026, 7, 19);

  StudyAttempt attempt(String id, {required String key}) => StudyAttempt(
    id: id,
    idempotencyKey: key,
    cardId: 'c1',
    sessionId: null,
    modeId: 'guess',
    outcome: 'correct',
    evidenceJson: '{}',
    isTerminal: true,
    createdAt: epoch,
  );

  Future<void> seed(db.AppDatabase database) async {
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
    await database.learningProgressDao.insertProgress(
      'p1',
      'c1',
      0,
      null,
      0,
      0,
    );
  }

  test('a replay after restart does not apply the grade twice', () async {
    final harness = RestartHarness.create();
    await seed(harness.database);

    await DriftLearningProgressRepository(
      harness.database,
    ).applyScheduledOutcome(
      attempt: attempt('a1', key: 'k1'),
      newBox: 1,
      newDueAt: epoch.add(const Duration(days: 1)),
      repetitionCount: 1,
      lapseCount: 0,
      srsActivatedAt: epoch,
      lastReviewedAt: epoch,
      expectedRevision: 0,
      updatedAt: epoch,
    );

    // The process dies here and the app comes back up.
    final reopened = await harness.restart();
    final afterRestart = DriftLearningProgressRepository(reopened);

    // A client that never learned the first call succeeded retries it. The
    // schedule differs deliberately: if the dedupe failed, the card would
    // land in Box 4 and the difference would be visible rather than
    // coincidentally identical.
    await afterRestart.applyScheduledOutcome(
      attempt: attempt('a2', key: 'k1'),
      newBox: 4,
      newDueAt: epoch.add(const Duration(days: 14)),
      repetitionCount: 2,
      lapseCount: 1,
      srsActivatedAt: epoch,
      lastReviewedAt: epoch.add(const Duration(days: 1)),
      expectedRevision: 1,
      updatedAt: epoch.add(const Duration(days: 1)),
    );

    final stored = await afterRestart.findByCard('c1');
    expect(stored?.box, 1, reason: 'the replay must not re-grade the card');
    expect(stored?.revision, 1);
    expect(stored?.repetitionCount, 1);
    expect(stored?.lapseCount, 0);

    // And exactly one piece of evidence exists — the retry did not append a
    // second attempt row for the same key.
    final attempts = await reopened.studyAttemptDao
        .pageAttemptsForCard('c1', 10, 0)
        .get();
    expect(attempts, hasLength(1));
    expect(attempts.single.id, 'a1');
  });

  test('a genuinely new grade after restart still applies', () async {
    final harness = RestartHarness.create();
    await seed(harness.database);

    await DriftLearningProgressRepository(
      harness.database,
    ).applyScheduledOutcome(
      attempt: attempt('a1', key: 'k1'),
      newBox: 1,
      newDueAt: epoch.add(const Duration(days: 1)),
      repetitionCount: 1,
      lapseCount: 0,
      srsActivatedAt: epoch,
      lastReviewedAt: epoch,
      expectedRevision: 0,
      updatedAt: epoch,
    );

    final reopened = await harness.restart();
    final afterRestart = DriftLearningProgressRepository(reopened);

    // The counterpart to the test above: dedupe must not become a blanket
    // "reject everything after a restart". A different key is a different
    // grade and has to land.
    await afterRestart.applyScheduledOutcome(
      attempt: attempt('a2', key: 'k2'),
      newBox: 2,
      newDueAt: epoch.add(const Duration(days: 4)),
      repetitionCount: 2,
      lapseCount: 0,
      srsActivatedAt: epoch,
      lastReviewedAt: epoch.add(const Duration(days: 1)),
      expectedRevision: 1,
      updatedAt: epoch.add(const Duration(days: 1)),
    );

    final stored = await afterRestart.findByCard('c1');
    expect(stored?.box, 2);
    expect(stored?.revision, 2);
    expect(stored?.srsActivatedAt, epoch);
    expect(stored?.lastReviewedAt, epoch.add(const Duration(days: 1)));
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';

/// WBS 5.7.2 — Today's Recent-decks rows: the Library counters plus mastery,
/// ordered by when each deck was last studied (`load-today-dashboard.md` §3).
void main() {
  late db.AppDatabase database;
  late DriftDeckRepository decks;

  const clock = _FixedClock(1000);

  Future<void> deck(String id, String name) => database.deckDao.insertDeck(
    id,
    'lp1',
    null,
    name,
    name.toLowerCase(),
    0,
    0,
  );

  /// One card in [deckId] at [box], optionally graded at [lastReviewedAt].
  Future<void> card(
    String id,
    String deckId, {
    int box = 0,
    int? dueAt,
    int? lastReviewedAt,
    bool hidden = false,
  }) async {
    await database.flashcardDao.insertFlashcard(id, deckId, id, id, id, 0, 0);
    if (hidden) {
      await database.customStatement(
        'UPDATE flashcards SET is_hidden = 1 WHERE id = ?',
        <Object?>[id],
      );
    }
    await database.learningProgressDao.insertProgress(
      'p_$id',
      id,
      box,
      dueAt,
      0,
      0,
    );
    if (lastReviewedAt != null) {
      await database.customStatement(
        'UPDATE learning_progress SET last_reviewed_at = ? WHERE card_id = ?',
        <Object?>[lastReviewedAt, id],
      );
    }
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    decks = DriftDeckRepository(database, clock);
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

  test('orders by the most recent grade, newest first', () async {
    await deck('old', 'Old');
    await deck('newest', 'Newest');
    await deck('middle', 'Middle');
    await card('c1', 'old', box: 2, dueAt: 5000, lastReviewedAt: 100);
    await card('c2', 'newest', box: 2, dueAt: 5000, lastReviewedAt: 900);
    await card('c3', 'middle', box: 2, dueAt: 5000, lastReviewedAt: 500);

    final rows = await decks.recentSummaries('lp1', limit: 3);

    expect(rows.map((row) => row.deck.id).toList(), <String>[
      'newest',
      'middle',
      'old',
    ]);
  });

  // A deck's own last-studied instant is the newest of its cards', not the
  // oldest — the whole ordering inverts if the aggregate is wrong.
  test('a deck is as recent as its most recently graded card', () async {
    await deck('a', 'A');
    await deck('b', 'B');
    await card('a1', 'a', box: 2, dueAt: 5000, lastReviewedAt: 10);
    await card('a2', 'a', box: 2, dueAt: 5000, lastReviewedAt: 900);
    await card('b1', 'b', box: 2, dueAt: 5000, lastReviewedAt: 500);

    final rows = await decks.recentSummaries('lp1', limit: 3);

    expect(rows.first.deck.id, 'a');
  });

  // A learner who has created decks but not started studying still has a
  // library; hiding it would say the opposite.
  test('never-studied decks sort last, by name, and are still shown', () async {
    await deck('zulu', 'Zulu');
    await deck('alpha', 'Alpha');
    await deck('studied', 'Studied');
    await card('s1', 'studied', box: 2, dueAt: 5000, lastReviewedAt: 100);
    await card('z1', 'zulu');
    await card('a1', 'alpha');

    final rows = await decks.recentSummaries('lp1', limit: 3);

    expect(rows.map((row) => row.deck.id).toList(), <String>[
      'studied',
      'alpha',
      'zulu',
    ]);
  });

  test('mastery counts Box 8 against the studiable cards', () async {
    await deck('d', 'D');
    await card('m1', 'd', box: 8);
    await card('m2', 'd', box: 8);
    await card('m3', 'd', box: 3, dueAt: 5000);
    await card('m4', 'd', box: 0);

    final row = (await decks.recentSummaries('lp1', limit: 3)).single;

    expect(row.masteredCount, 2);
    expect(row.studiableCount, 4);
    expect(row.masteryFraction, 0.5);
  });

  // A hidden card can never be mastered, so counting it in the denominator
  // would put 100% permanently out of reach.
  test('hidden cards leave the mastery denominator', () async {
    await deck('d', 'D');
    await card('v1', 'd', box: 8);
    await card('h1', 'd', box: 0, hidden: true);

    final row = (await decks.recentSummaries('lp1', limit: 3)).single;

    expect(row.studiableCount, 1);
    expect(row.masteryFraction, 1.0);
    // The meta line still says how many cards the deck holds.
    expect(row.cardCount, 2);
  });

  test('the limit bounds the section', () async {
    for (var i = 0; i < 5; i++) {
      await deck('d$i', 'Deck $i');
      await card('c$i', 'd$i', box: 2, dueAt: 5000, lastReviewedAt: 100 + i);
    }

    expect((await decks.recentSummaries('lp1', limit: 3)).length, 3);
  });

  // The strip's "library mastered" reads the same Box-8 rule as the deck bars,
  // across the whole pair rather than one deck.
  group('library mastery', () {
    late DriftLearningProgressRepository progress;

    setUp(() {
      progress = DriftLearningProgressRepository(database);
    });

    test('counts Box 8 across every deck of the pair', () async {
      await deck('a', 'A');
      await deck('b', 'B');
      await card('a1', 'a', box: 8);
      await card('a2', 'a', box: 3, dueAt: 5000);
      await card('b1', 'b', box: 8);
      await card('b2', 'b', box: 0);

      final mastery = await progress.countLibraryMastery('lp1');

      expect(mastery.masteredCount, 2);
      expect(mastery.studiableCount, 4);
      expect(mastery.fraction, 0.5);
    });

    test('hidden cards leave the denominator here too', () async {
      await deck('a', 'A');
      await card('a1', 'a', box: 8);
      await card('a2', 'a', box: 0, hidden: true);

      final mastery = await progress.countLibraryMastery('lp1');

      expect(mastery.studiableCount, 1);
      expect(mastery.fraction, 1.0);
    });

    test('an empty library reads zero, not a division by zero', () async {
      final mastery = await progress.countLibraryMastery('lp1');

      expect(mastery.studiableCount, 0);
      expect(mastery.fraction, 0);
    });
  });

  test('due-ness is measured at read time, like the library rows', () async {
    await deck('d', 'D');
    await card('due', 'd', box: 2, dueAt: 900);
    await card('later', 'd', box: 2, dueAt: 5000);

    final row = (await decks.recentSummaries('lp1', limit: 3)).single;

    expect(row.dueCount, 1, reason: 'clock is 1000; only due=900 has arrived');
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._epochMs);

  final int _epochMs;

  @override
  DateTime nowUtc() =>
      DateTime.fromMillisecondsSinceEpoch(_epochMs, isUtc: true);
}

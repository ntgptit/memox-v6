import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/usecases/flashcard/create_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/hide_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';

/// WBS 5.4.2 / `TEST-WBS-5.4.2-01` — `surface-due-cards.md` §§4, 5, 7, 9.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 7, 25, 12);
  final clock = FakeClock(now);

  late db.AppDatabase database;
  late DriftFlashcardRepository cards;
  late DriftDeckRepository decks;
  late DriftLearningProgressRepository progress;
  late LoadStudyQueueCountsUseCase counts;

  /// Creates a card in [deckId]; it lands in Box 0 (New) per 5.4.1.
  Future<String> createCard(String deckId, String term) async {
    final create = CreateFlashcardUseCase(
      cards: cards,
      decks: decks,
      idGenerator: SequentialIdGenerator(prefix: term),
      clock: clock,
    );
    final result =
        await create(deckId: deckId, term: term, primaryMeaning: 'nghĩa')
            as FlashcardCreated;
    return result.card.id;
  }

  /// Moves a card to a learned box with an explicit due instant —
  /// standing in for what 5.4.3/5.4.4 will write.
  Future<void> schedule(String cardId, int box, DateTime? dueAt) async {
    await database.learningProgressDao.updateProgressGuarded(
      box,
      dueAt?.millisecondsSinceEpoch,
      1,
      0,
      null,
      null,
      null,
      now.millisecondsSinceEpoch,
      cardId,
      0,
    );
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    cards = DriftFlashcardRepository(database);
    decks = DriftDeckRepository(database, const SystemClock());
    progress = DriftLearningProgressRepository(database);
    counts = LoadStudyQueueCountsUseCase(
      progress: progress,
      decks: decks,
      clock: clock,
    );

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    // ADR-001: a deck holds cards or child decks, never both — so only
    // the leaves below carry content.
    //   leaf, empty          root leaves
    //   parent > branch > grandchild   depth for the aggregate test
    //   parent > direct                a leaf sibling of `branch`
    await database.deckDao.insertDeck(
      'leaf',
      'lp1',
      null,
      'Leaf',
      'leaf',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'empty',
      'lp1',
      null,
      'Empty',
      'empty',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'parent',
      'lp1',
      null,
      'Parent',
      'parent',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'direct',
      'lp1',
      'parent',
      'Direct',
      'direct',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'branch',
      'lp1',
      'parent',
      'Branch',
      'branch',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'grandchild',
      'lp1',
      'branch',
      'Grand',
      'grand',
      0,
      0,
    );
  });

  tearDown(() => database.close());

  test('a fresh card is New, not Due — box carries the queue', () async {
    await createCard('leaf', 'alpha');

    final result = await counts.forDeck('leaf');

    expect(result.newCount, 1);
    expect(result.dueCount, 0);
    expect(result.hasNothingDue, isTrue);
    expect(result.hasNoEligibleCards, isFalse);
  });

  test('due is box 1..7 reached; box 8 is mastered and in no queue', () async {
    final due = await createCard('leaf', 'due');
    final later = await createCard('leaf', 'later');
    final mastered = await createCard('leaf', 'mastered');

    await schedule(due, 3, now.subtract(const Duration(days: 1)));
    await schedule(later, 3, now.add(const Duration(days: 1)));
    // Box 8 must carry a null due date to satisfy the schema CHECK.
    await schedule(mastered, 8, null);

    final result = await counts.forDeck('leaf');

    expect(result.dueCount, 1);
    expect(result.newCount, 0);
    expect(result.totalCount, 1);
  });

  test('due-at-equal-now counts as due', () async {
    final boundary = await createCard('leaf', 'boundary');
    await schedule(boundary, 1, now);

    expect((await counts.forDeck('leaf')).dueCount, 1);
  });

  // WBS 5.4.5 — boundary. The comparison is `due_at <= nowUtc`, so the
  // interesting cases are the two instants either side of equality, not
  // equality alone. One millisecond is the smallest step the stored epoch
  // can express, which makes this the tightest form of the assertion.
  group('the due boundary, to the millisecond (§7)', () {
    const tick = Duration(milliseconds: 1);

    test('one millisecond before now is due', () async {
      final card = await createCard('leaf', 'just-before');
      await schedule(card, 1, now.subtract(tick));

      expect((await counts.forDeck('leaf')).dueCount, 1);
    });

    test('one millisecond after now is not due', () async {
      final card = await createCard('leaf', 'just-after');
      await schedule(card, 1, now.add(tick));

      expect((await counts.forDeck('leaf')).dueCount, 0);
    });
  });

  // WBS 5.4.5 — timezone. `surface-due-cards.md` §9: "Due eligibility luôn
  // dùng UTC instant equality/before; timezone change không làm đổi persisted
  // `dueAt`." The use case documents this in a comment; nothing held it.
  //
  // Dart cannot repoint the process timezone mid-test, so the equivalent
  // check is to express the *same instant* with a different UTC offset. If
  // any step compared wall-clock fields instead of the instant, these two
  // readings would disagree.
  group('due eligibility is an instant comparison, not a wall clock (§9)', () {
    // 19:00+07:00 is the same moment as the fixture's 12:00Z.
    final sameInstantElsewhere = DateTime.parse('2026-07-25T19:00:00+07:00');

    test('the same instant in another offset classifies identically', () async {
      final card = await createCard('leaf', 'tz');
      await schedule(card, 1, now);

      final inUtc = (await counts.forDeck('leaf')).dueCount;

      clock.now = sameInstantElsewhere;
      final inOffset = (await counts.forDeck('leaf')).dueCount;

      expect(sameInstantElsewhere.isAtSameMomentAs(now), isTrue);
      expect(inOffset, inUtc);
      expect(inOffset, 1);

      clock.now = now;
    });

    test('reading in another offset does not move the stored due', () async {
      final card = await createCard('leaf', 'tz-stable');
      await schedule(card, 1, now.add(const Duration(days: 3)));

      final before = await progress.findByCard(card);

      clock.now = sameInstantElsewhere;
      await counts.forDeck('leaf');
      clock.now = now;

      // Asking what is due is a selection, not a mutation (§1), and a
      // timezone change is not an event the store should notice at all.
      final after = await progress.findByCard(card);
      expect(after?.dueAt, before?.dueAt);
      expect(after?.revision, before?.revision);
    });
  });

  test('a parent aggregates descendants without double-counting', () async {
    await createCard('direct', 'one');
    await createCard('grandchild', 'two');
    final deep = await createCard('grandchild', 'three');
    await schedule(deep, 2, now.subtract(const Duration(hours: 1)));

    // The root sees every descendant leaf exactly once, across two
    // different depths.
    final parent = await counts.forDeck('parent');
    expect(parent.newCount, 2);
    expect(parent.dueCount, 1);
    expect(parent.totalCount, 3);

    // A mid-level Parent aggregates only its own subtree.
    final branch = await counts.forDeck('branch');
    expect(branch.totalCount, 2);

    // A Leaf answers for its direct cards.
    final grandchild = await counts.forDeck('grandchild');
    expect(grandchild.totalCount, 2);
    expect(await counts.forDeck('direct').then((c) => c.totalCount), 1);
  });

  test('an empty deck answers zero, distinctly from nothing due', () async {
    final result = await counts.forDeck('empty');

    expect(result.totalCount, 0);
    expect(result.hasNoEligibleCards, isTrue);
    expect(result.hasNothingDue, isTrue);
  });

  test('hidden and deleted cards are excluded', () async {
    await createCard('leaf', 'visible');
    final hiddenId = await createCard('leaf', 'hidden');
    final deletedId = await createCard('leaf', 'deleted');

    final hide = HideFlashcardUseCase(cards: cards, clock: clock);
    await hide.setHidden(hiddenId, hidden: true);
    await database.flashcardDao.softDeleteFlashcard(
      now.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch,
      deletedId,
    );

    expect((await counts.forDeck('leaf')).totalCount, 1);
  });

  test('library scope spans every deck of the pair', () async {
    await createCard('leaf', 'alpha');
    await createCard('direct', 'beta');
    final due = await createCard('grandchild', 'gamma');
    await schedule(due, 4, now.subtract(const Duration(minutes: 1)));

    final result = await counts.forLibrary('lp1');

    expect(result.newCount, 2);
    expect(result.dueCount, 1);
  });

  test('reading the queues mutates nothing', () async {
    final cardId = await createCard('leaf', 'alpha');
    final before = await progress.findByCard(cardId);

    await counts.forDeck('leaf');
    await counts.forLibrary('lp1');

    final after = await progress.findByCard(cardId);
    expect(after!.box, before!.box);
    expect(after.dueAt, before.dueAt);
    expect(after.revision, before.revision);
    expect(after.updatedAt, before.updatedAt);
  });

  test('an unknown deck is typed rather than silently zero', () async {
    await expectLater(
      counts.forDeck('no-such-deck'),
      throwsA(
        isA<ValidationFailure>()
            .having((failure) => failure.field, 'field', 'deckId')
            .having((failure) => failure.code, 'code', 'unknown'),
      ),
    );
  });
}

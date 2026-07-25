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
import 'package:memox_v6/domain/usecases/learning_progress/initialise_card_progress_usecase.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';

/// WBS 5.4.1 / `TEST-WBS-5.4.1-01` — `initialise-card-progress.md` §7.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftFlashcardRepository cards;
  late DriftDeckRepository decks;
  late DriftLearningProgressRepository progress;
  late InitialiseCardProgressUseCase initialise;

  final clock = FakeClock(DateTime.utc(2026, 7, 25));

  Future<String> createCard({String term = 'hello'}) async {
    final create = CreateFlashcardUseCase(
      cards: cards,
      decks: decks,
      idGenerator: SequentialIdGenerator(prefix: term),
      clock: clock,
    );
    final result =
        await create(deckId: 'd1', term: term, primaryMeaning: 'xin chào')
            as FlashcardCreated;
    return result.card.id;
  }

  Future<int> progressRowCount() async {
    final rows = await database.select(database.learningProgress).get();
    return rows.length;
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    cards = DriftFlashcardRepository(database);
    decks = DriftDeckRepository(database, const SystemClock());
    progress = DriftLearningProgressRepository(database);
    initialise = InitialiseCardProgressUseCase(
      cards: cards,
      progress: progress,
      idGenerator: SequentialIdGenerator(prefix: 'progress'),
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
    await database.deckDao.insertDeck(
      'd1',
      'lp1',
      null,
      'Words',
      'words',
      0,
      0,
    );
  });

  tearDown(() => database.close());

  test('a repaired card starts New: box 0, no due date, policy v1', () async {
    final cardId = await createCard();
    await database.learningProgressDao.deleteProgressByCard(cardId);

    final state = await initialise(cardId);

    // §4 initial state contract, field by field.
    expect(state.cardId, cardId);
    expect(state.box, 0);
    expect(state.dueAt, isNull);
    expect(state.policyId, 'leitner-8-box-v1');
    expect(state.policyVersion, 1);
    expect(state.repetitionCount, 0);
    expect(state.lapseCount, 0);
    expect(state.revision, 0);
    expect(state.lastTerminalAttemptId, isNull);
    expect(state.createdAt, clock.nowUtc());

    // §4: initialising creates no Attempt.
    final attempts = await database.select(database.studyAttempts).get();
    expect(attempts, isEmpty);
  });

  test('a card created through the app already holds its New state', () async {
    final cardId = await createCard();

    // Create Card writes progress inline (§1: the card must not save
    // "successfully" without it), so this is a pure read.
    final state = await initialise(cardId);

    expect(state.box, 0);
    expect(state.dueAt, isNull);
    expect(await progressRowCount(), 1);
  });

  test('repeat initialise returns the same row and never a second', () async {
    final cardId = await createCard();
    await database.learningProgressDao.deleteProgressByCard(cardId);

    final first = await initialise(cardId);
    final second = await initialise(cardId);

    expect(second.id, first.id);
    expect(await progressRowCount(), 1);
  });

  test('a learned card is returned unchanged, never reset', () async {
    final cardId = await createCard();
    // Stand in for what 5.4.3/5.4.4 will write: Box 3 with a due date.
    final due = DateTime.utc(2026, 8, 1);
    await database.learningProgressDao.updateProgressGuarded(
      3,
      due.millisecondsSinceEpoch,
      4,
      1,
      null,
      null,
      null,
      clock.nowUtc().millisecondsSinceEpoch,
      cardId,
      0,
    );

    final state = await initialise(cardId);

    expect(state.box, 3);
    expect(state.dueAt, due);
    expect(state.repetitionCount, 4);
    expect(state.lapseCount, 1);
    // The revision is the tell: a reset-and-reinsert would lose it.
    expect(state.revision, 1);
    expect(await progressRowCount(), 1);
  });

  test('an unknown card is typed and writes no orphan progress', () async {
    await expectLater(
      initialise('no-such-card'),
      throwsA(
        isA<ValidationFailure>()
            .having((failure) => failure.field, 'field', 'cardId')
            .having((failure) => failure.code, 'code', 'unknown'),
      ),
    );

    expect(await progressRowCount(), 0);
  });

  test('concurrent initialise resolves to one row', () async {
    final cardId = await createCard();
    await database.learningProgressDao.deleteProgressByCard(cardId);

    final states = await Future.wait([
      initialise(cardId),
      initialise(cardId),
      initialise(cardId),
    ]);

    expect(await progressRowCount(), 1);
    expect(states.map((state) => state.id).toSet(), hasLength(1));
  });
}

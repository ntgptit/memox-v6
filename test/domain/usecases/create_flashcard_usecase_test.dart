import 'package:memox_v6/core/time/app_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/usecases/flashcard/create_flashcard_usecase.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late CreateFlashcardUseCase createFlashcard;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    createFlashcard = CreateFlashcardUseCase(
      cards: DriftFlashcardRepository(database),
      decks: DriftDeckRepository(database, const SystemClock()),
      idGenerator: SequentialIdGenerator(prefix: 'card'),
      clock: FakeClock(DateTime.utc(2026, 7, 19)),
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
    await database.deckDao.insertDeck('d2', 'lp1', null, 'More', 'more', 0, 0);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the card atomically with trimmed content and Box 0', () async {
    final result = await createFlashcard(
      deckId: 'd1',
      term: '  hello ',
      primaryMeaning: ' xin chào ',
    );

    result as FlashcardCreated;
    expect(result.card.id, 'card-1');
    expect(result.card.term, 'hello');
    expect(result.card.primaryMeaning, 'xin chào');

    final progress = await database.learningProgressDao
        .findProgressByCard('card-1')
        .getSingle();
    expect(progress.box, 0);
    expect(progress.dueAt, isNull);
  });

  test('required term and meaning are typed validation', () async {
    await expectLater(
      createFlashcard(deckId: 'd1', term: '  ', primaryMeaning: 'x'),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.field,
          'field',
          'term',
        ),
      ),
    );
    await expectLater(
      createFlashcard(deckId: 'd1', term: 'x', primaryMeaning: ' '),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.field,
          'field',
          'primaryMeaning',
        ),
      ),
    );
  });

  test('duplicate candidates surface across the pair before commit', () async {
    await createFlashcard(deckId: 'd1', term: 'hello', primaryMeaning: 'a');

    final result = await createFlashcard(
      deckId: 'd2',
      term: ' HELLO ',
      primaryMeaning: 'b',
    );

    result as DuplicateCandidatesFound;
    expect(result.candidates.single.term, 'hello');

    // Nothing was committed for the second attempt.
    final rows = await database
        .customSelect('SELECT COUNT(*) AS n FROM flashcards')
        .getSingle();
    expect(rows.read<int>('n'), 1);
  });

  test('an explicit keep-both retry proceeds past candidates', () async {
    await createFlashcard(deckId: 'd1', term: 'hello', primaryMeaning: 'a');

    final kept = await createFlashcard(
      deckId: 'd2',
      term: 'hello',
      primaryMeaning: 'b',
      allowDuplicate: true,
    );

    expect(kept, isA<FlashcardCreated>());
    final rows = await database
        .customSelect('SELECT COUNT(*) AS n FROM flashcards')
        .getSingle();
    expect(rows.read<int>('n'), 2);
  });

  test('soft-deleted cards are not duplicate candidates', () async {
    await createFlashcard(deckId: 'd1', term: 'hello', primaryMeaning: 'a');
    await database.flashcardDao.softDeleteFlashcard(1, 1, 'card-1');

    final result = await createFlashcard(
      deckId: 'd2',
      term: 'hello',
      primaryMeaning: 'b',
    );

    expect(result, isA<FlashcardCreated>());
  });

  test('retrying with the kept id is idempotent', () async {
    final first = await createFlashcard(
      deckId: 'd1',
      term: 'hello',
      primaryMeaning: 'a',
      retryCardId: 'retry-1',
    );
    final retried = await createFlashcard(
      deckId: 'd1',
      term: 'hello',
      primaryMeaning: 'a',
      retryCardId: 'retry-1',
    );

    expect((first as FlashcardCreated).card.id, 'retry-1');
    expect((retried as FlashcardCreated).card.id, 'retry-1');
    final rows = await database
        .customSelect('SELECT COUNT(*) AS n FROM flashcards')
        .getSingle();
    expect(rows.read<int>('n'), 1);
  });

  test('a parent deck rejects direct cards with the stable code', () async {
    await database.deckDao.insertDeck('sub', 'lp1', 'd1', 'Sub', 'sub', 0, 0);

    await expectLater(
      createFlashcard(deckId: 'd1', term: 'hello', primaryMeaning: 'a'),
      throwsA(
        isA<ConflictFailure>().having(
          (failure) => failure.code,
          'code',
          'deck-mixed-content',
        ),
      ),
    );
  });
}

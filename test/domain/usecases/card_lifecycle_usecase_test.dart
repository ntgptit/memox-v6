import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/flashcard/edit_flashcard_result.dart';
import 'package:memox_v6/domain/usecases/flashcard/create_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/delete_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/edit_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/hide_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_tags_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_translations_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/move_flashcard_usecase.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftFlashcardRepository cards;
  late DriftDeckRepository decks;
  late EditFlashcardUseCase edit;
  late HideFlashcardUseCase hide;
  late DeleteFlashcardUseCase delete;
  late MoveFlashcardUseCase move;

  final clock = FakeClock(DateTime.utc(2026, 7, 19));

  Future<String> createCard({
    String deckId = 'd1',
    String term = 'hello',
    String meaning = 'xin chào',
  }) async {
    final create = CreateFlashcardUseCase(
      cards: cards,
      decks: decks,
      idGenerator: SequentialIdGenerator(prefix: term),
      clock: clock,
    );
    final result =
        await create(deckId: deckId, term: term, primaryMeaning: meaning)
            as FlashcardCreated;
    return result.card.id;
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    cards = DriftFlashcardRepository(database);
    decks = DriftDeckRepository(database);
    edit = EditFlashcardUseCase(cards: cards, decks: decks, clock: clock);
    hide = HideFlashcardUseCase(cards: cards, clock: clock);
    delete = DeleteFlashcardUseCase(cards: cards, clock: clock);
    move = MoveFlashcardUseCase(cards: cards, decks: decks, clock: clock);

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.languagePairDao.insertLanguagePair(
      'lp2',
      'ko',
      'vi',
      'ko|vi',
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
      'child',
      'lp1',
      'parent',
      'Child',
      'child',
      0,
      0,
    );
    await database.deckDao.insertDeck(
      'other-pair',
      'lp2',
      null,
      'Korean',
      'korean',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('edit (edit-flashcard.md)', () {
    test(
      'edit preserves id/deck/progress and bumps the content version',
      () async {
        final cardId = await createCard();

        final result =
            await edit(
                  cardId: cardId,
                  term: '  hi there ',
                  primaryMeaning: 'chào',
                  expectedContentVersion: 1,
                )
                as FlashcardEdited;

        expect(result.card.id, cardId);
        expect(result.card.deckId, 'd1');
        expect(result.card.term, 'hi there');
        expect(result.card.contentVersion, 2);

        final progress = await database.learningProgressDao
            .findProgressByCard(cardId)
            .getSingleOrNull();
        expect(progress, isNotNull);
      },
    );

    test('a stale content version never last-write-wins', () async {
      final cardId = await createCard();

      await edit(
        cardId: cardId,
        term: 'first edit',
        primaryMeaning: 'chào',
        expectedContentVersion: 1,
      );

      await expectLater(
        edit(
          cardId: cardId,
          term: 'second editor',
          primaryMeaning: 'khác',
          expectedContentVersion: 1,
        ),
        throwsA(
          isA<ConflictFailure>().having((f) => f.code, 'code', 'stale-version'),
        ),
      );

      final row = await cards.findById(cardId);
      expect(row?.term, 'first edit');
    });

    test('duplicate candidates return for review without commit', () async {
      final cardId = await createCard();
      await createCard(deckId: 'd2', term: 'goodbye', meaning: 'tạm biệt');

      final result = await edit(
        cardId: cardId,
        term: ' GOODBYE ',
        primaryMeaning: 'chào',
        expectedContentVersion: 1,
      );

      result as EditDuplicateCandidatesFound;
      expect(result.candidates.single.term, 'goodbye');

      final unchanged = await cards.findById(cardId);
      expect(unchanged?.term, 'hello');

      // Explicit keep-both proceeds.
      final kept =
          await edit(
                cardId: cardId,
                term: ' GOODBYE ',
                primaryMeaning: 'chào',
                expectedContentVersion: 1,
                allowDuplicate: true,
              )
              as FlashcardEdited;
      expect(kept.card.term, 'GOODBYE');
    });

    test('editing back to the own term is not a self-duplicate', () async {
      final cardId = await createCard();

      final result = await edit(
        cardId: cardId,
        term: 'hello',
        primaryMeaning: 'chào lại',
        expectedContentVersion: 1,
      );
      expect(result, isA<FlashcardEdited>());
    });
  });

  group('hide (hide-flashcard.md)', () {
    test('hide/unhide toggles without touching content or progress', () async {
      final cardId = await createCard();

      await hide.setHidden(cardId, hidden: true);
      var card = await cards.findById(cardId);
      expect(card?.isHidden, isTrue);
      expect(card?.term, 'hello');
      expect(card?.contentVersion, 1);

      await hide.setHidden(cardId, hidden: false);
      card = await cards.findById(cardId);
      expect(card?.isHidden, isFalse);

      final progress = await database.learningProgressDao
          .findProgressByCard(cardId)
          .getSingleOrNull();
      expect(progress, isNotNull);
    });

    test('hiding an already hidden card is a no-op', () async {
      final cardId = await createCard();
      await hide.setHidden(cardId, hidden: true);
      final before = await cards.findById(cardId);

      await hide.setHidden(cardId, hidden: true);
      final after = await cards.findById(cardId);
      expect(after?.updatedAt, before?.updatedAt);
    });
  });

  group('delete (delete-flashcard.md)', () {
    test(
      'delete removes child content and progress with the tombstone',
      () async {
        final cardId = await createCard();
        final translations = ManageCardTranslationsUseCase(cards: cards);
        final tags = ManageCardTagsUseCase(cards: cards);
        await translations.addTranslation(
          translationId: 'tr1',
          cardId: cardId,
          languageCode: 'vi',
          rawText: 'chào bạn',
          now: clock.nowUtc(),
        );
        await tags.attachTagByLabel(
          cardId: cardId,
          rawLabel: 'topik',
          newTagId: 'tag1',
          now: clock.nowUtc(),
        );

        await delete.deleteCard(cardId);

        final card = await cards.findById(cardId);
        expect(card?.isDeleted, isTrue);
        expect(await cards.translationsOf(cardId), isEmpty);
        expect(await cards.tagsOf(cardId), isEmpty);
        final progress = await database.learningProgressDao
            .findProgressByCard(cardId)
            .getSingleOrNull();
        expect(progress, isNull);

        // The tag itself survives for other cards (TAG-005/006 scope).
        final tagRow = await database.flashcardDao
            .findTagByNormalizedName('topik')
            .getSingleOrNull();
        expect(tagRow, isNotNull);
      },
    );

    test('deleting the last card leaves the deck derivably Empty', () async {
      final cardId = await createCard();
      await delete.deleteCard(cardId);

      final remaining = await database.flashcardDao
          .countActiveFlashcardsInDeck('d1')
          .getSingle();
      expect(remaining, 0);
    });

    test('deleting an already deleted card is a no-op', () async {
      final cardId = await createCard();
      await delete.deleteCard(cardId);
      await delete.deleteCard(cardId);
      final card = await cards.findById(cardId);
      expect(card?.isDeleted, isTrue);
    });
  });

  group('move (move-flashcard.md)', () {
    test('move preserves identity, children and progress', () async {
      final cardId = await createCard();
      final translations = ManageCardTranslationsUseCase(cards: cards);
      await translations.addTranslation(
        translationId: 'tr1',
        cardId: cardId,
        languageCode: 'vi',
        rawText: 'chào bạn',
        now: clock.nowUtc(),
      );

      await move(cardId: cardId, targetDeckId: 'd2');

      final card = await cards.findById(cardId);
      expect(card?.deckId, 'd2');
      expect(card?.term, 'hello');
      expect((await cards.translationsOf(cardId)).single.text, 'chào bạn');
      final progress = await database.learningProgressDao
          .findProgressByCard(cardId)
          .getSingleOrNull();
      expect(progress, isNotNull);
    });

    test('the source deck is never accepted', () async {
      final cardId = await createCard();
      await expectLater(
        move(cardId: cardId, targetDeckId: 'd1'),
        throwsA(
          isA<ValidationFailure>().having((f) => f.code, 'code', 'same-deck'),
        ),
      );
    });

    test('a Parent target is rejected by deck exclusivity', () async {
      final cardId = await createCard();
      await expectLater(
        move(cardId: cardId, targetDeckId: 'parent'),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.code,
            'code',
            'deck-mixed-content',
          ),
        ),
      );
      final card = await cards.findById(cardId);
      expect(card?.deckId, 'd1');
    });

    test('a cross-pair target requires the review flow', () async {
      final cardId = await createCard();
      await expectLater(
        move(cardId: cardId, targetDeckId: 'other-pair'),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.code,
            'code',
            'cross-pair-move',
          ),
        ),
      );
    });

    test('an empty target becomes Leaf only after the commit', () async {
      final cardId = await createCard();
      await move(cardId: cardId, targetDeckId: 'd2');

      final counts = await database.flashcardDao
          .countActiveFlashcardsInDeck('d2')
          .getSingle();
      expect(counts, 1);
    });
  });
}

import 'package:memox_v6/core/time/app_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_language_pair_repository.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/new_card_content.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftLanguagePairRepository pairs;
  late DriftDeckRepository decks;
  late DriftFlashcardRepository cards;

  final epoch = DateTime.utc(2026, 7, 19);

  LanguagePair pair(String id, {String key = 'en|vi'}) => LanguagePair(
    id: id,
    learningLanguageCode: 'en',
    nativeLanguageCode: 'vi',
    normalizedPairKey: key,
    createdAt: epoch,
    updatedAt: epoch,
  );

  Deck deck(String id, {String? parentId, String name = 'travel'}) => Deck(
    id: id,
    languagePairId: 'lp1',
    parentId: parentId,
    name: name,
    normalizedName: name,
    createdAt: epoch,
    updatedAt: epoch,
  );

  Flashcard card(String id, {String deckId = 'd1'}) => Flashcard(
    id: id,
    deckId: deckId,
    term: 'hello',
    primaryMeaning: 'xin chào',
    contentVersion: 1,
    isHidden: false,
    deletedAt: null,
    createdAt: epoch,
    updatedAt: epoch,
  );

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    pairs = DriftLanguagePairRepository(database);
    decks = DriftDeckRepository(database, const SystemClock());
    cards = DriftFlashcardRepository(database);

    await pairs.createPair(pair('lp1'));
    await decks.createDeck(deck('d1'));
  });

  tearDown(() async {
    await database.close();
  });

  Matcher throwsConflict(String code) => throwsA(
    isA<ConflictFailure>().having((failure) => failure.code, 'code', code),
  );

  group('LanguagePairRepository', () {
    test('duplicate normalized keys surface as typed conflicts', () async {
      await expectLater(
        pairs.createPair(pair('lp2')),
        throwsConflict('duplicate'),
      );

      final found = await pairs.findByNormalizedKey('en|vi');
      expect(found?.id, 'lp1');
    });
  });

  group('DeckRepository', () {
    test('trigger aborts arrive as coded conflicts', () async {
      await decks.createDeck(deck('sub', parentId: 'd1', name: 'asia'));

      await expectLater(
        decks.move('d1', newParentId: 'sub', updatedAt: epoch),
        throwsConflict('deck-cycle'),
      );

      await expectLater(
        decks.createDeck(deck('dup', name: 'travel')),
        throwsConflict('duplicate'),
      );
    });
  });

  group('FlashcardRepository.createCard (atomic operation 1)', () {
    test('commits card, child content and Box 0 progress together', () async {
      await decks.createDeck(deck('leaf', parentId: 'd1', name: 'leaf'));
      await cards.createCard(NewCardContent(card: card('c1', deckId: 'leaf')));

      final stored = await cards.findById('c1');
      expect(stored?.term, 'hello');

      final progress = await database.learningProgressDao
          .findProgressByCard('c1')
          .getSingle();
      expect(progress.box, 0);
      expect(progress.dueAt, isNull);
    });

    test('is idempotent on the card id', () async {
      await decks.createDeck(deck('leaf', parentId: 'd1', name: 'leaf'));
      final content = NewCardContent(card: card('c1', deckId: 'leaf'));

      await cards.createCard(content);
      await cards.createCard(content);

      final count = await database.flashcardDao
          .countActiveFlashcardsInDeck('leaf')
          .getSingle();
      expect(count, 1);
    });

    test('an exclusivity abort rolls the whole creation back', () async {
      await decks.createDeck(deck('sub', parentId: 'd1', name: 'asia'));

      await expectLater(
        cards.createCard(NewCardContent(card: card('c1', deckId: 'd1'))),
        throwsConflict('deck-mixed-content'),
      );

      expect(await cards.findById('c1'), isNull);
      final progress = await database.learningProgressDao
          .findProgressByCard('c1')
          .getSingleOrNull();
      expect(progress, isNull);
    });

    test('lifecycle transitions stay conflict-guarded', () async {
      await decks.createDeck(deck('leaf', parentId: 'd1', name: 'leaf'));
      await cards.createCard(NewCardContent(card: card('c1', deckId: 'leaf')));

      await cards.softDelete('c1', deletedAt: epoch);
      final listed = await cards.pageByDeck('leaf', limit: 10, offset: 0);
      expect(listed, isEmpty);

      await cards.restore('c1', updatedAt: epoch);
      final restored = await cards.pageByDeck('leaf', limit: 10, offset: 0);
      expect(restored.single.id, 'c1');

      await expectLater(
        cards.move('c1', targetDeckId: 'd1', updatedAt: epoch),
        throwsConflict('deck-mixed-content'),
      );
    });
  });
}

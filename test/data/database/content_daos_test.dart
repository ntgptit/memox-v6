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
  });

  tearDown(() async {
    await database.close();
  });

  group('LanguagePairDao', () {
    test('round-trips by id and normalized key', () async {
      final byId = await database.languagePairDao
          .findLanguagePairById('lp1')
          .getSingle();
      final byKey = await database.languagePairDao
          .findLanguagePairByKey('en|vi')
          .getSingle();

      expect(byId.learningLanguageCode, 'en');
      expect(byKey.id, 'lp1');
    });
  });

  group('DeckDao', () {
    test('lists roots and children separately and reactively', () async {
      await database.deckDao.insertDeck(
        'd2',
        'lp1',
        'd1',
        'Asia',
        'asia',
        0,
        0,
      );

      final roots = await database.deckDao.watchRootDecks('lp1').get();
      final children = await database.deckDao.watchChildDecks('d1').get();

      expect(roots.map((deck) => deck.id), ['d1']);
      expect(children.map((deck) => deck.id), ['d2']);

      final stream = database.deckDao.watchRootDecks('lp1').watch();
      final futureEmission = stream.firstWhere((rows) => rows.length == 2);
      await database.deckDao.insertDeck(
        'd3',
        'lp1',
        null,
        'Work',
        'work',
        0,
        0,
      );
      final emission = await futureEmission;
      expect(emission.map((deck) => deck.id), containsAll(['d1', 'd3']));
    });

    test('rename and delete are effective', () async {
      await database.deckDao.renameDeck('Trips', 'trips', 1, 'd1');

      final renamed = await database.deckDao.findDeckById('d1').getSingle();
      expect(renamed.name, 'Trips');

      await database.deckDao.deleteDeck('d1');
      final gone = await database.deckDao.findDeckById('d1').getSingleOrNull();
      expect(gone, isNull);
    });
  });

  group('FlashcardDao', () {
    Future<void> insertCards(int count) async {
      for (var index = 0; index < count; index++) {
        await database.flashcardDao.insertFlashcard(
          'c$index',
          'd1',
          'term-$index',
          'meaning-$index',
          index,
          index,
        );
      }
    }

    test('pages active cards in stable order', () async {
      await insertCards(5);

      final firstPage = await database.flashcardDao
          .pageFlashcardsByDeck('d1', 2, 0)
          .get();
      final secondPage = await database.flashcardDao
          .pageFlashcardsByDeck('d1', 2, 2)
          .get();

      expect(firstPage.map((card) => card.id), ['c0', 'c1']);
      expect(secondPage.map((card) => card.id), ['c2', 'c3']);
    });

    test('soft-deleted cards leave listings and return on restore', () async {
      await insertCards(2);

      await database.flashcardDao.softDeleteFlashcard(5, 5, 'c0');

      var listed = await database.flashcardDao
          .watchFlashcardsByDeck('d1')
          .get();
      expect(listed.map((card) => card.id), ['c1']);

      final count = await database.flashcardDao
          .countActiveFlashcardsInDeck('d1')
          .getSingle();
      expect(count, 1);

      await database.flashcardDao.restoreFlashcard(6, 'c0');
      listed = await database.flashcardDao.watchFlashcardsByDeck('d1').get();
      expect(listed.length, 2);
    });

    test('editing content bumps the content version', () async {
      await insertCards(1);

      await database.flashcardDao.updateFlashcardContent(
        'term-x',
        'meaning-x',
        7,
        'c0',
      );

      final card = await database.flashcardDao
          .findFlashcardById('c0')
          .getSingle();
      expect(card.term, 'term-x');
      expect(card.contentVersion, 2);
    });

    test('owns translation, tag and audio child content', () async {
      await insertCards(1);

      await database.flashcardDao.insertTranslation(
        't1',
        'c0',
        'vi',
        'nghĩa',
        0,
        0,
        0,
      );
      await database.flashcardDao.insertTag('tag1', 'Verbs', 'verbs', 0, 0);
      await database.flashcardDao.attachTag('c0', 'tag1', 0);
      await database.flashcardDao.insertAudioRef(
        'a1',
        'c0',
        'en',
        'asset-1',
        'tts-v1',
        0,
        0,
      );

      final translations = await database.flashcardDao
          .listTranslationsForCard('c0')
          .get();
      final tags = await database.flashcardDao.listTagsForCard('c0').get();
      final refs = await database.flashcardDao.listAudioRefsForCard('c0').get();
      expect(translations.single.translationText, 'nghĩa');
      expect(tags.single.normalizedName, 'verbs');
      expect(refs.single.assetId, 'asset-1');

      await database.flashcardDao.detachTag('c0', 'tag1');
      expect(await database.flashcardDao.listTagsForCard('c0').get(), isEmpty);
    });

    test('moves stay guarded by the exclusivity triggers', () async {
      await insertCards(1);
      await database.deckDao.insertDeck(
        'tree',
        'lp1',
        null,
        'Tree',
        'tree',
        0,
        0,
      );
      await database.deckDao.insertDeck(
        'leaf',
        'lp1',
        'tree',
        'Leaf',
        'leaf',
        0,
        0,
      );

      await expectLater(
        database.flashcardDao.moveFlashcard('tree', 8, 'c0'),
        throwsA(isA<SqliteException>()),
      );

      await database.flashcardDao.moveFlashcard('leaf', 8, 'c0');
      final card = await database.flashcardDao
          .findFlashcardById('c0')
          .getSingle();
      expect(card.deckId, 'leaf');
    });
  });
}

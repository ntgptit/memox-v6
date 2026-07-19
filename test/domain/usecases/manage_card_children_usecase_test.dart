import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_audio_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_tags_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_translations_usecase.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftFlashcardRepository cards;
  late ManageCardTranslationsUseCase translations;
  late ManageCardTagsUseCase tags;
  late ManageCardAudioUseCase audio;

  final clock = FakeClock(DateTime.utc(2026, 7, 19));
  final t0 = DateTime.utc(2026, 7, 19);
  final t1 = DateTime.utc(2026, 7, 19, 1);

  Future<int> cardVersion(String cardId) async {
    final row = await database.flashcardDao
        .findFlashcardById(cardId)
        .getSingle();
    return row.updatedAt;
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    cards = DriftFlashcardRepository(database);
    translations = ManageCardTranslationsUseCase(cards: cards);
    tags = ManageCardTagsUseCase(
      cards: cards,
      idGenerator: SequentialIdGenerator(prefix: 'tag'),
      clock: clock,
    );
    audio = ManageCardAudioUseCase(cards: cards);

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
    await database.flashcardDao.insertFlashcard(
      'c1',
      'd1',
      'hello',
      'hello',
      'xin chào',
      0,
      0,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('translations (manage-card-translations.md)', () {
    test('add appends in order and bumps the card version', () async {
      await translations.addTranslation(
        translationId: 'tr1',
        cardId: 'c1',
        languageCode: 'vi',
        rawText: '  chào bạn ',
        now: t0,
      );
      await translations.addTranslation(
        translationId: 'tr2',
        cardId: 'c1',
        languageCode: 'vi',
        rawText: 'chào buổi sáng',
        now: t1,
      );

      final stored = await translations.translationsOf('c1');
      expect(stored.map((t) => t.text).toList(), [
        'chào bạn',
        'chào buổi sáng',
      ]);
      expect(stored.map((t) => t.displayOrder).toList(), [0, 1]);
      expect(await cardVersion('c1'), t1.millisecondsSinceEpoch);
    });

    test('a blank translation never persists', () async {
      await expectLater(
        translations.addTranslation(
          translationId: 'tr1',
          cardId: 'c1',
          languageCode: 'vi',
          rawText: '   ',
          now: t0,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await translations.translationsOf('c1'), isEmpty);
      expect(await cardVersion('c1'), 0);
    });

    test('a normalized duplicate of the primary meaning is blocked', () async {
      await expectLater(
        translations.addTranslation(
          translationId: 'tr1',
          cardId: 'c1',
          languageCode: 'vi',
          rawText: '  XIN CHÀO ',
          now: t0,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.code,
            'code',
            'duplicate-translation',
          ),
        ),
      );
    });

    test('composed and decomposed spellings collide as duplicates', () async {
      await translations.addTranslation(
        translationId: 'tr1',
        cardId: 'c1',
        languageCode: 'vi',
        rawText: 'chào', // composed U+00E0
        now: t0,
      );
      await expectLater(
        translations.addTranslation(
          translationId: 'tr2',
          cardId: 'c1',
          languageCode: 'vi',
          rawText: 'chào', // decomposed a + combining grave
          now: t1,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('edit rewrites text and re-checks duplicates', () async {
      await translations.addTranslation(
        translationId: 'tr1',
        cardId: 'c1',
        languageCode: 'vi',
        rawText: 'chào bạn',
        now: t0,
      );
      await translations.addTranslation(
        translationId: 'tr2',
        cardId: 'c1',
        languageCode: 'vi',
        rawText: 'chào cậu',
        now: t0,
      );

      await translations.editTranslation(
        translationId: 'tr2',
        cardId: 'c1',
        rawText: '  chào cả nhà ',
        now: t1,
      );
      final afterEdit = await translations.translationsOf('c1');
      expect(afterEdit[1].text, 'chào cả nhà');

      await expectLater(
        translations.editTranslation(
          translationId: 'tr2',
          cardId: 'c1',
          rawText: 'CHÀO BẠN',
          now: t1,
        ),
        throwsA(isA<ConflictFailure>()),
      );
      // Editing a row to its own text is not a self-duplicate.
      await translations.editTranslation(
        translationId: 'tr2',
        cardId: 'c1',
        rawText: 'chào cả nhà',
        now: t1,
      );
    });

    test('remove keeps surviving orders contiguous', () async {
      for (final (id, text) in [
        ('tr1', 'một'),
        ('tr2', 'hai'),
        ('tr3', 'ba'),
      ]) {
        await translations.addTranslation(
          translationId: id,
          cardId: 'c1',
          languageCode: 'vi',
          rawText: text,
          now: t0,
        );
      }

      await translations.removeTranslation(
        translationId: 'tr2',
        cardId: 'c1',
        now: t1,
      );

      final stored = await translations.translationsOf('c1');
      expect(stored.map((t) => t.id).toList(), ['tr1', 'tr3']);
      expect(stored.map((t) => t.displayOrder).toList(), [0, 1]);
      expect(await cardVersion('c1'), t1.millisecondsSinceEpoch);
    });

    test('reorder applies a complete permutation atomically', () async {
      for (final (id, text) in [
        ('tr1', 'một'),
        ('tr2', 'hai'),
        ('tr3', 'ba'),
      ]) {
        await translations.addTranslation(
          translationId: id,
          cardId: 'c1',
          languageCode: 'vi',
          rawText: text,
          now: t0,
        );
      }

      await translations.reorderTranslations(
        cardId: 'c1',
        orderedTranslationIds: ['tr3', 'tr1', 'tr2'],
        now: t1,
      );

      final stored = await translations.translationsOf('c1');
      expect(stored.map((t) => t.id).toList(), ['tr3', 'tr1', 'tr2']);
      expect(stored.map((t) => t.displayOrder).toList(), [0, 1, 2]);
    });

    test('a partial or foreign order is a typed failure', () async {
      await translations.addTranslation(
        translationId: 'tr1',
        cardId: 'c1',
        languageCode: 'vi',
        rawText: 'một',
        now: t0,
      );

      await expectLater(
        translations.reorderTranslations(
          cardId: 'c1',
          orderedTranslationIds: ['tr1', 'ghost'],
          now: t1,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('tags (TAG-001..006)', () {
    test('composed/decomposed and case variants resolve to one tag '
        'keeping the first display spelling', () async {
      // Composed U+00E0, title case.
      final first = await tags.attachTagByLabel(
        cardId: 'c1',
        rawLabel: ' Chào ',
        newTagId: 'tag1',
        now: t0,
      );
      expect(first.name, 'Chào');

      // Decomposed (a + combining grave) + different casing resolves
      // to the same tag without renaming it.
      final second = await tags.attachTagByLabel(
        cardId: 'c1',
        rawLabel: 'CHÀO',
        newTagId: 'tag2',
        now: t1,
      );
      expect(second.id, first.id);
      expect(second.name, 'Chào');

      final attached = await tags.tagsOf('c1');
      expect(attached, hasLength(1));
    });

    test('attach is idempotent (TAG-004)', () async {
      final tag = await tags.attachTagByLabel(
        cardId: 'c1',
        rawLabel: 'topik',
        newTagId: 'tag1',
        now: t0,
      );
      await tags.attachTagByLabel(
        cardId: 'c1',
        rawLabel: 'TOPIK',
        newTagId: 'tag2',
        now: t1,
      );

      final attached = await tags.tagsOf('c1');
      expect(attached.single.id, tag.id);
    });

    test('an empty normalized label is invalid (TAG-002)', () async {
      await expectLater(
        tags.attachTagByLabel(
          cardId: 'c1',
          rawLabel: '   ',
          newTagId: 'tag1',
          now: t0,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('detach removes only the association (TAG-005)', () async {
      final tag = await tags.attachTagByLabel(
        cardId: 'c1',
        rawLabel: 'topik',
        newTagId: 'tag1',
        now: t0,
      );

      await tags.detachTag(cardId: 'c1', tagId: tag.id, now: t1);

      expect(await tags.tagsOf('c1'), isEmpty);
      final card = await cards.findById('c1');
      expect(card, isNotNull);
      expect(card?.term, 'hello');
    });

    test(
      'deleting a tag is refused while used, allowed after (TAG-006)',
      () async {
        final tag = await tags.attachTagByLabel(
          cardId: 'c1',
          rawLabel: 'topik',
          newTagId: 'tag1',
          now: t0,
        );

        expect(await tags.deleteUnusedTag(tag.id), isFalse);

        await tags.detachTag(cardId: 'c1', tagId: tag.id, now: t1);
        expect(await tags.deleteUnusedTag(tag.id), isTrue);

        final remaining = await database.flashcardDao
            .findTagByNormalizedName('topik')
            .getSingleOrNull();
        expect(remaining, isNull);
      },
    );

    test('concurrent same-label creation resolves to the winner', () async {
      // Simulate the loser: the tag row appears between validation and
      // insert — the unique constraint resolves to the winner's id.
      await database.flashcardDao.insertTag('winner', 'Topik', 'topik', 0, 0);

      final resolved = await cards.resolveTagByLabel(
        displayName: 'TOPIK',
        normalizedName: 'topik',
        newTagId: 'loser',
        now: t0,
      );
      expect(resolved.id, 'winner');
      expect(resolved.name, 'Topik');
    });
  });

  group('audio refs (manage-card-audio.md)', () {
    test('add and remove commit with the card version', () async {
      await audio.addAudioRef(
        refId: 'a1',
        cardId: 'c1',
        languageCode: 'ko',
        assetId: 'asset-1',
        provider: 'local',
        now: t0,
      );

      final stored = await audio.audioRefsOf('c1');
      expect(stored.single.assetId, 'asset-1');
      expect(await cardVersion('c1'), t0.millisecondsSinceEpoch);

      await audio.removeAudioRef(refId: 'a1', cardId: 'c1', now: t1);
      expect(await audio.audioRefsOf('c1'), isEmpty);
      expect(await cardVersion('c1'), t1.millisecondsSinceEpoch);
    });

    test('blank asset metadata is a typed failure', () async {
      await expectLater(
        audio.addAudioRef(
          refId: 'a1',
          cardId: 'c1',
          languageCode: 'ko',
          assetId: '  ',
          provider: 'local',
          now: t0,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await audio.audioRefsOf('c1'), isEmpty);
    });
  });
}

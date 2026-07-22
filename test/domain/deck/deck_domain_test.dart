import 'package:memox_v6/core/time/app_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/deck/deck_name.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('deck content-state derivation (README §0 decision table)', () {
    DeckContentCounts counts(int children, int cards) =>
        DeckContentCounts(childDeckCount: children, activeCardCount: cards);

    test('derives every canonical state deterministically', () {
      expect(deriveDeckContentState(counts(0, 0)), DeckContentState.empty);
      expect(deriveDeckContentState(counts(2, 0)), DeckContentState.parent);
      expect(deriveDeckContentState(counts(0, 3)), DeckContentState.leaf);
      // Back to Empty after the last content leaves.
      expect(deriveDeckContentState(counts(0, 0)), DeckContentState.empty);
    });

    test('mixed content is corruption, never a renderable state', () {
      expect(
        () => deriveDeckContentState(counts(1, 1)),
        throwsA(
          isA<DataCorruptionFailure>().having(
            (failure) => failure.value,
            'value',
            'mixed',
          ),
        ),
      );
    });
  });

  group('deck name normalization', () {
    test('sibling identity is trimmed lowercase; display keeps casing', () {
      expect(normalizeDeckName('  Travel Plans '), 'travel plans');
      expect(validateDeckName('  Travel Plans '), 'Travel Plans');
    });

    test('an empty draft is a typed validation failure', () {
      expect(
        () => validateDeckName('   '),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.code,
            'code',
            'required',
          ),
        ),
      );
    });
  });

  group('database-backed invariants', () {
    late db.AppDatabase database;
    late DriftDeckRepository decks;

    setUp(() async {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      decks = DriftDeckRepository(database, const SystemClock());
      for (final pair in ['lp1', 'lp2']) {
        await database.languagePairDao.insertLanguagePair(
          pair,
          'en',
          pair,
          'en|$pair',
          0,
          0,
        );
      }
      await database.deckDao.insertDeck(
        'root1',
        'lp1',
        null,
        'Travel',
        'travel',
        0,
        0,
      );
      await database.deckDao.insertDeck(
        'root2',
        'lp2',
        null,
        'Reisen',
        'reisen',
        0,
        0,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('contentCounts feeds the derivation over live data', () async {
      expect(
        deriveDeckContentState(await decks.contentCounts('root1')),
        DeckContentState.empty,
      );

      await database.deckDao.insertDeck(
        'child',
        'lp1',
        'root1',
        'Asia',
        'asia',
        0,
        0,
      );
      expect(
        deriveDeckContentState(await decks.contentCounts('root1')),
        DeckContentState.parent,
      );

      await database.flashcardDao.insertFlashcard(
        'c1',
        'child',
        't',
        't',
        'm',
        0,
        0,
      );
      expect(
        deriveDeckContentState(await decks.contentCounts('child')),
        DeckContentState.leaf,
      );

      // Soft-deleted cards return the deck to Empty.
      await database.flashcardDao.softDeleteFlashcard(1, 1, 'c1');
      expect(
        deriveDeckContentState(await decks.contentCounts('child')),
        DeckContentState.empty,
      );
    });

    test('a deck tree never crosses language pairs', () async {
      await expectLater(
        database.deckDao.insertDeck('bad', 'lp2', 'root1', 'Bad', 'bad', 0, 0),
        throwsA(isA<SqliteException>()),
      );

      await expectLater(
        decks.move(
          'root2',
          newParentId: 'root1',
          updatedAt: DateTime.utc(2026, 7, 19),
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'deck-pair-mismatch',
          ),
        ),
      );

      // Same-pair nesting still works.
      await database.deckDao.insertDeck('ok', 'lp1', 'root1', 'Ok', 'ok', 0, 0);
    });
  });
}

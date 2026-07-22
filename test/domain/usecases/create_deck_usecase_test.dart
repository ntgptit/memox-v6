import 'package:memox_v6/core/time/app_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_language_pair_repository.dart';
import 'package:memox_v6/domain/deck/deck_content_state.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftDeckRepository decks;
  late CreateDeckUseCase createDeck;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    decks = DriftDeckRepository(database, const SystemClock());
    createDeck = CreateDeckUseCase(
      decks: decks,
      pairs: DriftLanguagePairRepository(database),
      idGenerator: SequentialIdGenerator(prefix: 'deck'),
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
  });

  tearDown(() async {
    await database.close();
  });

  Matcher throwsConflict(String code) => throwsA(
    isA<ConflictFailure>().having((failure) => failure.code, 'code', code),
  );

  test('creates a root deck with no automatic content', () async {
    final deck = await createDeck(name: '  Travel ', languagePairId: 'lp1');

    expect(deck.id, 'deck-1');
    expect(deck.name, 'Travel');
    expect(deck.normalizedName, 'travel');
    expect(deck.isRoot, isTrue);

    expect(
      deriveDeckContentState(await decks.contentCounts(deck.id)),
      DeckContentState.empty,
      reason: 'a new deck is always Empty - nothing is created for it',
    );
  });

  test('creates nested decks under a parent of the same pair', () async {
    final root = await createDeck(name: 'Travel', languagePairId: 'lp1');
    final child = await createDeck(
      name: 'Asia',
      languagePairId: 'lp1',
      parentId: root.id,
    );

    expect(child.parentId, root.id);
    expect(
      deriveDeckContentState(await decks.contentCounts(root.id)),
      DeckContentState.parent,
    );
  });

  test('sibling names collide per parent; other parents are free', () async {
    final root = await createDeck(name: 'Travel', languagePairId: 'lp1');
    await createDeck(name: 'Asia', languagePairId: 'lp1', parentId: root.id);

    await expectLater(
      createDeck(name: ' ASIA ', languagePairId: 'lp1', parentId: root.id),
      throwsConflict('duplicate'),
    );

    // The same name is fine at the root level.
    await createDeck(name: 'Asia', languagePairId: 'lp1');
  });

  test('retrying with the kept id is idempotent', () async {
    final first = await createDeck(
      name: 'Travel',
      languagePairId: 'lp1',
      retryDeckId: 'retry-1',
    );
    final retried = await createDeck(
      name: 'Travel',
      languagePairId: 'lp1',
      retryDeckId: 'retry-1',
    );

    expect(first.id, 'retry-1');
    expect(retried.id, 'retry-1');
    final rows = await database
        .customSelect('SELECT COUNT(*) AS n FROM decks')
        .getSingle();
    expect(rows.read<int>('n'), 1);
  });

  test('unknown pair or parent is typed validation', () async {
    await expectLater(
      createDeck(name: 'Travel', languagePairId: 'missing'),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.field,
          'field',
          'languagePairId',
        ),
      ),
    );
    await expectLater(
      createDeck(name: 'Travel', languagePairId: 'lp1', parentId: 'missing'),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.field,
          'field',
          'parentId',
        ),
      ),
    );
  });

  test(
    'a card-holding parent rejects child decks with the stable code',
    () async {
      final leaf = await createDeck(name: 'Words', languagePairId: 'lp1');
      await database.flashcardDao.insertFlashcard(
        'c1',
        leaf.id,
        't',
        't',
        'm',
        0,
        0,
      );

      await expectLater(
        createDeck(name: 'Sub', languagePairId: 'lp1', parentId: leaf.id),
        throwsConflict('deck-mixed-content'),
      );
    },
  );
}

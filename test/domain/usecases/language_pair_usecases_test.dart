import 'package:memox_v6/core/time/app_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_language_pair_repository.dart';
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/domain/language_pair/create_language_pair_result.dart';
import 'package:memox_v6/domain/language_pair/language_pair_key.dart';
import 'package:memox_v6/domain/usecases/language_pair/create_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/remove_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';

import '../../support/fake_clock.dart';
import '../../support/sequential_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftLanguagePairRepository pairs;
  late DriftPreferenceRepository preferences;
  late DriftDeckRepository decks;
  late CreateLanguagePairUseCase create;
  late SelectLanguagePairUseCase select;
  late RemoveLanguagePairUseCase remove;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    pairs = DriftLanguagePairRepository(database);
    preferences = DriftPreferenceRepository(database);
    decks = DriftDeckRepository(database, const SystemClock());
    final clock = FakeClock(DateTime.utc(2026, 7, 19));
    create = CreateLanguagePairUseCase(
      repository: pairs,
      idGenerator: SequentialIdGenerator(prefix: 'pair'),
      clock: clock,
    );
    select = SelectLanguagePairUseCase(
      pairs: pairs,
      preferences: preferences,
      clock: clock,
    );
    remove = RemoveLanguagePairUseCase(
      pairs: pairs,
      decks: decks,
      preferences: preferences,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Matcher throwsValidation(String field, String code) => throwsA(
    isA<ValidationFailure>()
        .having((failure) => failure.field, 'field', field)
        .having((failure) => failure.code, 'code', code),
  );

  test('the normalized key lowercases and trims both codes', () {
    final key = buildNormalizedPairKey(
      learningLanguageCode: ' EN ',
      nativeLanguageCode: 'Vi',
    );
    expect(key, 'en|vi');
  });

  group('CreateLanguagePairUseCase', () {
    test(
      'creates with stable injected identity and normalized codes',
      () async {
        final result = await create(
          learningLanguageCode: ' EN ',
          nativeLanguageCode: 'VI',
        );

        expect(result, isA<LanguagePairCreated>());
        expect(result.pair.id, 'pair-1');
        expect(result.pair.learningLanguageCode, 'en');
        expect(result.pair.normalizedPairKey, 'en|vi');
        expect(result.pair.createdAt, DateTime.utc(2026, 7, 19));

        final stored = await pairs.findById('pair-1');
        expect(stored, isNotNull);
      },
    );

    test('a duplicate returns the existing pair instead of creating', () async {
      await create(learningLanguageCode: 'en', nativeLanguageCode: 'vi');

      final again = await create(
        learningLanguageCode: 'EN',
        nativeLanguageCode: ' vi',
      );

      expect(again, isA<LanguagePairAlreadyExists>());
      expect(again.pair.id, 'pair-1');
    });

    test('validation is typed: required, unsupported, distinct', () async {
      await expectLater(
        create(learningLanguageCode: '  ', nativeLanguageCode: 'vi'),
        throwsValidation('learningLanguageCode', 'required'),
      );
      await expectLater(
        create(learningLanguageCode: 'xx', nativeLanguageCode: 'vi'),
        throwsValidation('learningLanguageCode', 'unsupported'),
      );
      await expectLater(
        create(learningLanguageCode: 'en', nativeLanguageCode: 'EN'),
        throwsValidation('nativeLanguageCode', 'not-distinct'),
      );
    });
  });

  group('SelectLanguagePairUseCase', () {
    test('persists the selection by stable id and reads it back', () async {
      await create(learningLanguageCode: 'en', nativeLanguageCode: 'vi');

      await select('pair-1');

      final active = await select.activePair();
      expect(active?.id, 'pair-1');
    });

    test(
      'rejects unknown ids and falls back to null when unresolved',
      () async {
        await expectLater(
          select('missing'),
          throwsValidation('languagePairId', 'unknown'),
        );
        expect(await select.activePair(), isNull);
      },
    );
  });

  group('RemoveLanguagePairUseCase', () {
    test('the deck dependency guard blocks removal', () async {
      await create(learningLanguageCode: 'en', nativeLanguageCode: 'vi');
      await database.deckDao.insertDeck(
        'd1',
        'pair-1',
        null,
        'Travel',
        'travel',
        0,
        0,
      );

      await expectLater(
        remove('pair-1'),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'deck-dependency',
          ),
        ),
      );
      expect(await pairs.findById('pair-1'), isNotNull);
    });

    test('removing the active pair clears the stored selection', () async {
      await create(learningLanguageCode: 'en', nativeLanguageCode: 'vi');
      await select('pair-1');

      await remove('pair-1');

      expect(await pairs.findById('pair-1'), isNull);
      expect(await select.activePair(), isNull);
      expect(
        await preferences.read(SelectLanguagePairUseCase.preferenceKey),
        isNull,
      );
    });
  });
}

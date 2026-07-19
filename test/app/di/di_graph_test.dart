import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/data/database/app_database.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';

import '../../support/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppDatabase inMemory() => AppDatabase.forTesting(NativeDatabase.memory());

  test('the warmed graph resolves every port over one database', () async {
    final database = inMemory();
    final container = createTestContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(database.close);

    await warmUpDiGraph(container);

    expect(
      container.read(flashcardRepositoryProvider),
      isA<DriftFlashcardRepository>(),
    );
    expect(
      identical(
        container.read(appDatabaseProvider),
        container.read(appDatabaseProvider),
      ),
      isTrue,
      reason: 'the database provider is keep-alive: one shared instance',
    );
  });

  test('repositories share the overridden database end to end', () async {
    final database = inMemory();
    final container = createTestContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(database.close);

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );

    final found = await container
        .read(languagePairRepositoryProvider)
        .findById('lp1');
    expect(found?.normalizedPairKey, 'en|vi');
  });

  test('a broken database fails the warm-up fast', () async {
    final database = inMemory();
    await database.customSelect('SELECT 1').getSingle();
    await database.close();
    final container = createTestContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );

    await expectLater(warmUpDiGraph(container), throwsA(isA<StateError>()));
  });
}

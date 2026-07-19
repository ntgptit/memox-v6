import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/dev/dev_fixtures.dart';

import 'database_contract.dart';
import 'restart_harness.dart';
import 'sequential_ids.dart';
import 'test_container.dart';

final _answerProvider = Provider<int>((ref) => 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sequential ids are deterministic and prefixed', () {
    final ids = SequentialIdGenerator(prefix: 'card');

    expect(ids.newId(), 'card-1');
    expect(ids.newId(), 'card-2');
  });

  test('test containers apply overrides and dispose themselves', () {
    final container = createTestContainer(
      overrides: [_answerProvider.overrideWithValue(42)],
    );

    expect(container.read(_answerProvider), 42);
  });

  runDatabaseLifecycleContract(
    'in-memory executor honors the opener contract',
    NativeDatabase.memory,
  );

  test('the restart harness keeps data across simulated restarts', () async {
    final harness = RestartHarness.create();
    final fixtures = DevFixtures(harness.database);
    await fixtures.seed(DevFixtureState.minimum);

    final reopened = await harness.restart();

    final rows = await reopened
        .customSelect('SELECT COUNT(*) AS n FROM flashcards')
        .getSingle();
    expect(rows.read<int>('n'), 1);
  });
}

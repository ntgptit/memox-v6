import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatabase lifecycle', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('opens at schema version 1 and executes queries', () async {
      expect(database.schemaVersion, 1);

      final row = await database.customSelect('SELECT 1 AS probe').getSingle();
      expect(row.read<int>('probe'), 1);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 1);
    });

    test('close is idempotent and ends the connection', () async {
      await database.customSelect('SELECT 1').getSingle();

      await database.close();
      await database.close();

      expect(
        () => database.customSelect('SELECT 1').getSingle(),
        throwsA(isA<StateError>()),
      );
    });

    test('a fresh instance opens after a previous one closed', () async {
      await database.close();

      final reopened = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(reopened.close);

      final row = await reopened.customSelect('SELECT 2 AS probe').getSingle();
      expect(row.read<int>('probe'), 2);
    });
  });
}

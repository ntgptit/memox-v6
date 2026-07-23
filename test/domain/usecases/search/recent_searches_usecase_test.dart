import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/domain/usecases/search/recent_searches_usecase.dart';

/// WBS 10.2 — recent searches record committed non-blank queries, deduped by
/// normalized text, newest-first and capped (manage-recent-searches.md).
void main() {
  late db.AppDatabase database;
  late RecentSearchesUseCase usecase;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    usecase = RecentSearchesUseCase(
      preferences: DriftPreferenceRepository(database),
      clock: const SystemClock(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('records newest-first', () async {
    await usecase.record('hello');
    await usecase.record('world');
    expect(await usecase.current(), ['world', 'hello']);
  });

  test('a blank query is not recorded', () async {
    await usecase.record('   ');
    expect(await usecase.current(), isEmpty);
  });

  test(
    'a repeat query dedupes and moves to the front with fresh text',
    () async {
      await usecase.record('hello');
      await usecase.record('world');
      await usecase.record('HELLO'); // same normalized as 'hello'
      expect(await usecase.current(), ['HELLO', 'world']);
    },
  );

  test('the list is capped at the newest entries', () async {
    for (var i = 0; i < 12; i++) {
      await usecase.record('query $i');
    }
    final recent = await usecase.current();
    expect(recent.length, 8);
    expect(recent.first, 'query 11');
    expect(recent.contains('query 3'), isFalse);
  });

  test('clear empties the list', () async {
    await usecase.record('hello');
    await usecase.clear();
    expect(await usecase.current(), isEmpty);
  });
}

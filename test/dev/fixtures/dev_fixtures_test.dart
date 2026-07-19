import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';
import 'package:memox_v6/data/dev/dev_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DevFixtures fixtures;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    fixtures = DevFixtures(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> count(String table) async {
    final row = await database
        .customSelect('SELECT COUNT(*) AS n FROM $table')
        .getSingle();
    return row.read<int>('n');
  }

  test('release builds cannot construct fixtures', () {
    expect(() => DevFixtures(database, enabled: false), throwsStateError);
  });

  test('minimum seeds one pair, deck, card and Box 0 progress', () async {
    await fixtures.seed(DevFixtureState.minimum);

    expect(await count('language_pairs'), 1);
    expect(await count('decks'), 1);
    expect(await count('flashcards'), 1);
    expect(await count('learning_progress'), 1);
  });

  test('dense seeds a deck tree with paged-size card batches', () async {
    await fixtures.seed(DevFixtureState.dense);

    expect(await count('decks'), 4);
    expect(await count('flashcards'), 75);
    expect(await count('learning_progress'), 75);
  });

  test('error seeds a corrupt preference that reads as fallback', () async {
    await fixtures.seed(DevFixtureState.error);

    final row = await database.preferenceDao
        .findPreference('appearance')
        .getSingle();
    expect(row.valueJson, contains('broken'));
  });

  test('pausedSession seeds a resumable active session', () async {
    await fixtures.seed(DevFixtureState.pausedSession);

    final active = await database.studySessionDao
        .watchActiveSession()
        .getSingle();
    expect(active.id, 'fix-session');
    expect(await count('study_session_cards'), 1);
    expect(await count('study_checkpoints'), 1);
    expect(await count('study_round_orders'), 1);
  });

  test('dueCard seeds a card due in the past', () async {
    await fixtures.seed(DevFixtureState.dueCard);

    final due = await database.learningProgressDao
        .countDueProgress(1752885000000)
        .getSingle();
    expect(due, 1);
  });

  test('reset returns any state to empty', () async {
    await fixtures.seed(DevFixtureState.pausedSession);

    await fixtures.reset();

    for (final table in [
      'language_pairs',
      'decks',
      'flashcards',
      'learning_progress',
      'study_sessions',
      'study_checkpoints',
      'preferences',
    ]) {
      expect(await count(table), 0, reason: table);
    }
  });
}

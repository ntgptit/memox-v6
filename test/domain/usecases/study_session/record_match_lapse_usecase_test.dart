import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/usecases/study_session/record_match_lapse_usecase.dart';

/// WBS 5.6.12 — a Match lapse reaches the checkpoint as it happens
/// (`exit-study-session.md` §5, `match-terms-and-meanings.md` §4).
void main() {
  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late RecordMatchLapseUseCase record;

  final now = DateTime.utc(2026, 7, 27, 12);

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    sessions = DriftStudySessionRepository(database);
    record = RecordMatchLapseUseCase(sessions);

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'Deck', 'deck', 0, 0);
    await database.studySessionDao.insertSession(
      's1',
      'newLearning',
      'd1',
      'subtree',
      'active',
      1,
      0,
      0,
      0,
    );
  });

  Future<void> seedCheckpoint({List<String> failed = const <String>[]}) =>
      sessions.saveCheckpoint(
        SessionCheckpoint(
          id: 'cp-s1',
          sessionId: 's1',
          stageIndex: 1,
          roundIndex: 1,
          cardPosition: 0,
          failedCardIds: failed,
          timerStateJson: '{}',
          stateVersion: 1,
          updatedAt: now,
        ),
      );

  test('a lapse joins the committed failed set', () async {
    await seedCheckpoint();

    await record(sessionId: 's1', cardId: 'c1');

    final saved = await sessions.checkpoint('s1');
    expect(saved!.failedCardIds, <String>['c1']);
    expect(
      saved.cardPosition,
      0,
      reason: 'the position is not the board\'s to move',
    );
  });

  // §4: "không duplicate". A learner can miss the same pair twice in a round.
  test('the same card lapsing twice is recorded once', () async {
    await seedCheckpoint();

    await record(sessionId: 's1', cardId: 'c1');
    await record(sessionId: 's1', cardId: 'c1');

    final saved = await sessions.checkpoint('s1');
    expect(saved!.failedCardIds, <String>['c1']);
  });

  test(
    'a lapse is added to what is already there, not instead of it',
    () async {
      await seedCheckpoint(failed: <String>['c9']);

      await record(sessionId: 's1', cardId: 'c1');

      final saved = await sessions.checkpoint('s1');
      expect(saved!.failedCardIds, <String>['c9', 'c1']);
    },
  );

  // Nothing committed yet: there is no position to amend, and writing one
  // would put the session somewhere it has never been.
  test('no checkpoint means nothing to amend', () async {
    await record(sessionId: 's1', cardId: 'c1');

    expect(await sessions.checkpoint('s1'), isNull);
  });
}

import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/deck/reset_progress_availability.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/usecases/deck/load_reset_progress_availability_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/reset_deck_progress_usecase.dart';

/// WBS 6.1 — a reset does not land underneath a running session
/// (`reset-deck-progress.md` §5: "Active session không bị silently rewrite").
///
/// A session freezes its cards at start and schedules against them when it
/// finalizes. A reset in between changes the SRS state it is working from,
/// which nothing tells the learner. §5 allows blocking the reset; this is that
/// block, and these tests pin where the boundary falls — a session on an
/// unrelated deck must not hold the whole library hostage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftDeckRepository decks;
  late DriftStudySessionRepository sessions;
  late DriftLearningProgressRepository progress;
  late LoadResetProgressAvailabilityUseCase availability;

  final now = DateTime.utc(2026, 7, 27, 9);

  Future<void> deck(String id, {String? parentId}) =>
      database.deckDao.insertDeck(id, 'lp1', parentId, id, id, 0, 0);

  Future<void> card(String id, String deckId, {int box = 3}) async {
    await database.flashcardDao.insertFlashcard(id, deckId, id, id, id, 0, 0);
    await database.learningProgressDao.insertProgress(
      'p-$id',
      id,
      box,
      box >= 1 && box <= 7 ? now.millisecondsSinceEpoch : null,
      0,
      0,
    );
  }

  /// A running session, written at the store rather than through the start
  /// use case: what the guard reads is the row, and the snapshots a real start
  /// would also write are not part of this question.
  Future<void> startSession(String deckId, {required SessionScope scope}) {
    return database.studySessionDao.insertSession(
      'session-$deckId',
      SessionType.dueReview.dbValue,
      deckId,
      scope.dbValue,
      SessionState.active.dbValue,
      1,
      now.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch,
    );
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    decks = DriftDeckRepository(database, _FixedClock(now));
    sessions = DriftStudySessionRepository(database);
    progress = DriftLearningProgressRepository(database);
    availability = LoadResetProgressAvailabilityUseCase(
      decks: decks,
      sessions: sessions,
    );
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    // root ─┬─ child ── (cards)
    //       └─ sibling ── (cards)
    // other ── (cards)      — a separate root, nothing to do with root's tree.
    await deck('root');
    await deck('child', parentId: 'root');
    await deck('sibling', parentId: 'root');
    await deck('other');
    await card('c-child', 'child');
    await card('c-sibling', 'sibling');
    await card('c-other', 'other');
  });

  tearDown(() => database.close());

  test('no session at all leaves every deck resettable', () async {
    expect(await availability('root'), ResetProgressAvailability.available);
    expect(await availability('child'), ResetProgressAvailability.available);
  });

  test('a session on the deck itself blocks it', () async {
    await startSession('child', scope: SessionScope.leaf);

    expect(
      await availability('child'),
      ResetProgressAvailability.blockedByActiveSession,
    );
  });

  test('a session below the reset scope blocks the ancestor', () async {
    await startSession('child', scope: SessionScope.leaf);

    expect(
      await availability('root'),
      ResetProgressAvailability.blockedByActiveSession,
      reason: 'resetting root resets the cards that session is working through',
    );
  });

  // The direction that depends on the session's own scope: a subtree session
  // on the root reaches down into the child, a leaf session does not.
  test('a subtree session above the reset scope blocks it', () async {
    await startSession('root', scope: SessionScope.subtree);

    expect(
      await availability('child'),
      ResetProgressAvailability.blockedByActiveSession,
    );
  });

  test('a leaf session on the parent does not block a child', () async {
    await startSession('root', scope: SessionScope.leaf);

    expect(
      await availability('child'),
      ResetProgressAvailability.available,
      reason: 'a leaf session never leaves its own deck',
    );
  });

  test('a session on an unrelated deck blocks nothing', () async {
    await startSession('other', scope: SessionScope.subtree);

    expect(await availability('root'), ResetProgressAvailability.available);
    expect(await availability('child'), ResetProgressAvailability.available);
  });

  test('a session that has ended blocks nothing', () async {
    await startSession('child', scope: SessionScope.leaf);
    await database.customStatement(
      'UPDATE study_sessions SET state = ? WHERE id = ?',
      <Object?>[SessionState.completed.dbValue, 'session-child'],
    );

    expect(await availability('child'), ResetProgressAvailability.available);
  });

  // The dialog checks availability before offering the action, but a session
  // can start while it is open — so the command is the authority, and refuses
  // without writing anything.
  test('the reset command itself refuses, leaving the boxes alone', () async {
    await startSession('child', scope: SessionScope.leaf);
    final reset = ResetDeckProgressUseCase(
      progress: progress,
      availability: availability,
      impact: LoadDeckDeletionImpactUseCase(
        decks: decks,
        sessions: DriftStudySessionRepository(database),
      ),
      idGenerator: _SeqIds('lp'),
      clock: _FixedClock(now),
    );

    await expectLater(
      // The session check runs before the count check, so the expectation
      // here is irrelevant — which is the point: a blocked reset never gets
      // as far as comparing impacts.
      reset('root', expectedAffectedCount: 2),
      throwsA(
        isA<ConflictFailure>().having((f) => f.code, 'code', 'session-active'),
      ),
    );
    expect((await progress.findByCard('c-child'))?.box, 3);
    expect((await progress.findByCard('c-sibling'))?.box, 3);
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  _SeqIds(this._prefix);
  final String _prefix;
  int _n = 0;
  @override
  String newId() => '$_prefix-${_n++}';
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/usecases/flashcard/delete_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// WBS 6.5 — `delete-flashcard.md` §5 and ST-CHG-007: "Current prompt hoặc
/// pending answer | Block delete; user phải exit, commit answer hoặc explicit
/// skip trước delete."
///
/// The row above it in the same table allows deleting a card that is in the
/// session but further down the queue, so this is a narrow rule about the one
/// card on screen. Both halves are asserted here: the block is only worth
/// having if it does not also stop the delete the spec permits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late LoadStudyRuntimeUseCase loadRuntime;
  late DeleteFlashcardUseCase delete;
  late StartStudySessionUseCase start;
  late AnswerStudyStageUseCase answer;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    final cards = DriftFlashcardRepository(database);
    final progress = DriftLearningProgressRepository(database);
    loadRuntime = LoadStudyRuntimeUseCase(sessions: sessions);
    delete = DeleteFlashcardUseCase(
      cards: cards,
      runtime: loadRuntime,
      clock: _FixedClock(now),
    );
    start = StartStudySessionUseCase(
      progress: progress,
      cards: cards,
      sessions: sessions,
      clock: _FixedClock(now),
      idGenerator: _SeqIds('start'),
    );
    answer = AnswerStudyStageUseCase(
      sessions: sessions,
      factory: StudyModeFactory.standard(),
      clock: _FixedClock(now),
      idGenerator: _SeqIds('answer'),
    );

    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D', 'd', 0, 0);
    for (final id in const <String>['c1', 'c2']) {
      await database.flashcardDao.insertFlashcard(id, 'd1', id, id, id, 0, 0);
      await database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        3,
        dueAt.millisecondsSinceEpoch,
        0,
        0,
      );
    }
  });

  tearDown(() => database.close());

  Future<void> startSession() => start(
    deckId: 'd1',
    scope: SessionScope.subtree,
    type: SessionType.dueReview,
  ).then((_) {});

  Future<bool> isDeleted(String cardId) async {
    final row = await database
        .customSelect("SELECT deleted_at FROM flashcards WHERE id = '$cardId'")
        .getSingle();
    return row.data['deleted_at'] != null;
  }

  test('the card on screen right now cannot be deleted', () async {
    await startSession();
    final current = (await loadRuntime())!.position.currentCardId!;

    await expectLater(
      delete.deleteCard(current),
      throwsA(
        isA<ConflictFailure>().having((f) => f.code, 'code', 'card-in-session'),
      ),
    );
    expect(await isDeleted(current), isFalse);
  });

  // §5 row 2: a card in the session but not the current prompt goes, and the
  // session skips it when its turn comes. A guard that blocked this would be
  // reading "in a session" where the table says "is the prompt".
  test('another card in the same session still deletes', () async {
    await startSession();
    final runtime = (await loadRuntime())!;
    final current = runtime.position.currentCardId!;
    final other = runtime.position.roundCardIds.firstWhere(
      (id) => id != current,
    );

    await delete.deleteCard(other);

    expect(await isDeleted(other), isTrue);
  });

  test('the block lifts once the session moves on', () async {
    await startSession();
    final runtime = (await loadRuntime())!;
    final first = runtime.position.currentCardId!;

    await answer(
      runtime,
      SrsBinaryReviewInput(
        sessionId: runtime.session.id,
        cardId: first,
        roundIndex: runtime.position.roundIndex,
        eventId: 'srs-$first-remembered',
        action: SrsBinaryAction.remembered,
      ),
    );

    // The prompt has moved, so the card that was on screen is now just a card
    // in the session — the row the table allows.
    await delete.deleteCard(first);

    expect(await isDeleted(first), isTrue);
  });

  test('with no session running nothing is blocked', () async {
    await delete.deleteCard('c1');

    expect(await isDeleted('c1'), isTrue);
  });

  test('a finished session blocks nothing', () async {
    await startSession();
    final current = (await loadRuntime())!.position.currentCardId!;
    await database.customStatement(
      'UPDATE study_sessions SET state = ? WHERE state = ?',
      <Object?>[SessionState.completed.dbValue, SessionState.active.dbValue],
    );

    await delete.deleteCard(current);

    expect(await isDeleted(current), isTrue);
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

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_modes/strategies/srs_binary_review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/skipped_card_reason.dart';
import 'package:memox_v6/domain/usecases/flashcard/delete_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/hide_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/skip_unavailable_card_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// WBS 5.6 — ST-CONTENT-CHANGE-v1 ST-CHG-005/006/010: a card deleted or
/// hidden after the snapshot is skipped with its reason, never substituted,
/// never graded, and left out of the accuracy denominator.
///
/// The snapshot keeps a running session coherent, which is why the card's text
/// is still there to render. It is not licence to quiz a learner on a card
/// they deleted — and answering it would schedule review for a card that no
/// longer exists.
///
/// Driven over one store from the card mutation through to the next prompt,
/// because that is where the rule lives: the delete is right, the session is
/// right, and what was missing was the session noticing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  late DriftFlashcardRepository cards;
  late LoadStudyRuntimeUseCase loadRuntime;
  late SkipUnavailableCardUseCase skip;
  late DeleteFlashcardUseCase delete;
  late HideFlashcardUseCase hide;
  late AnswerStudyStageUseCase answer;

  final now = DateTime.utc(2026, 7, 27, 9);
  final dueAt = now.subtract(const Duration(days: 1));

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    cards = DriftFlashcardRepository(database);
    final progress = DriftLearningProgressRepository(database);
    loadRuntime = LoadStudyRuntimeUseCase(sessions: sessions);
    skip = SkipUnavailableCardUseCase(
      sessions: sessions,
      cards: cards,
      clock: _FixedClock(now),
    );
    delete = DeleteFlashcardUseCase(
      cards: cards,
      runtime: loadRuntime,
      clock: _FixedClock(now),
    );
    hide = HideFlashcardUseCase(cards: cards, clock: _FixedClock(now));
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
    for (final id in const <String>['c1', 'c2', 'c3']) {
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
    await StartStudySessionUseCase(
      progress: progress,
      cards: cards,
      sessions: sessions,
      clock: _FixedClock(now),
      idGenerator: _SeqIds('start'),
    ).call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.dueReview,
    );
  });

  tearDown(() => database.close());

  Future<void> answerCurrent() async {
    final runtime = (await loadRuntime())!;
    final cardId = runtime.position.currentCardId!;
    await answer(
      runtime,
      SrsBinaryReviewInput(
        sessionId: runtime.session.id,
        cardId: cardId,
        roundIndex: runtime.position.roundIndex,
        eventId: 'srs-$cardId-remembered',
        action: SrsBinaryAction.remembered,
      ),
    );
  }

  Future<int> attemptCount() async {
    final row = await database
        .customSelect('SELECT COUNT(*) AS c FROM study_attempts')
        .getSingle();
    return row.read<int>('c');
  }

  test('a card deleted after the snapshot is skipped, not asked', () async {
    final runtime = (await loadRuntime())!;
    final current = runtime.position.currentCardId!;
    final next = runtime.position.roundCardIds.firstWhere(
      (id) => id != current,
    );

    // Deleted from another surface. The delete guard blocks only the card
    // that is the current prompt, so the queue ahead can change under a
    // running session — which is the case ST-CHG-006 is about.
    await delete.deleteCard(next);
    expect(await skip((await loadRuntime())!), isNull, reason: 'not there yet');

    // Answering the current card walks the position onto the deleted one.
    await answerCurrent();
    final onDeleted = (await loadRuntime())!;
    expect(onDeleted.position.currentCardId, next);

    expect(await skip(onDeleted), SkippedCardReason.deletedAfterSnapshot);

    final after = (await loadRuntime())!;
    expect(after.position.currentCardId, isNot(next));
    expect(
      await attemptCount(),
      1,
      reason:
          'only the answered card wrote one — a skip is not an answer, '
          'so the skipped card is in no denominator and gets no schedule',
    );
  });

  test('a card hidden after the snapshot is skipped too', () async {
    final runtime = (await loadRuntime())!;
    final current = runtime.position.currentCardId!;

    await hide.setHidden(current, hidden: true);

    expect(
      await skip((await loadRuntime())!),
      SkippedCardReason.hiddenAfterSnapshot,
    );
    expect((await loadRuntime())!.position.currentCardId, isNot(current));
  });

  test('a card that is still there is not skipped', () async {
    final runtime = (await loadRuntime())!;

    expect(await skip(runtime), isNull);
    expect(
      (await loadRuntime())!.position.currentCardId,
      runtime.position.currentCardId,
      reason: 'nothing moved',
    );
  });

  // The whole round can disappear. Every card is stepped over, none of them
  // is graded, and the session reaches its end rather than stalling on a card
  // it will not ask.
  test('a round that has entirely vanished completes the session', () async {
    for (final id in const <String>['c1', 'c2', 'c3']) {
      await hide.setHidden(id, hidden: true);
    }

    var runtime = (await loadRuntime())!;
    for (var i = 0; i < 3; i++) {
      expect(await skip(runtime), SkippedCardReason.hiddenAfterSnapshot);
      runtime = (await loadRuntime())!;
    }

    expect(runtime.isComplete, isTrue);
    expect(runtime.position.currentCardId, isNull);
    expect(await attemptCount(), 0);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/study_modes/guess_question_builder.dart';
import 'package:memox_v6/domain/study_modes/strategies/fill_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/guess_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/strategies/review_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_attempt.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';

/// WBS 5.7.4 — the first-learning pipeline composes end to end: a newLearning
/// session drives the real advance policy + mode factory through all five stages
/// (Review → Match → Guess → Recall → Fill) to completion when every answer
/// passes (`answer-study-stage.md`; study-deck.md §6). This is the missing
/// integration layer above the per-policy unit tests — it proves the stages
/// wire together, not just in isolation.
void main() {
  final now = DateTime.utc(2026, 7, 24, 9);
  const cardCount = 5;
  const stages = <StudyModeType>[
    StudyModeType.review,
    StudyModeType.match,
    StudyModeType.guess,
    StudyModeType.recall,
    StudyModeType.fill,
  ];

  StudyRuntimeState start() => StudyRuntimeState.assemble(
    session: StudySession(
      id: 's1',
      type: SessionType.newLearning,
      deckId: 'd1',
      scope: SessionScope.subtree,
      state: SessionState.active,
      revision: 0,
      snapshotVersion: 1,
      scheduleSrs: true,
      startedAt: now,
      finalizedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
    stages: stages,
    cardSnapshots: <SessionCardSnapshot>[
      for (var i = 0; i < cardCount; i++)
        SessionCardSnapshot(
          id: 'sc$i',
          sessionId: 's1',
          cardId: 'c$i',
          displayOrder: i,
          term: 'term-$i',
          meaning: 'meaning-$i',
          contentVersion: 1,
          progressBox: 0,
          progressRevision: 0,
        ),
    ],
    currentOrder: SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: <String>[for (var i = 0; i < cardCount; i++) 'c$i'],
    ),
  );

  test('every stage passed drives the session to completion', () async {
    final repo = _CollectingRepo();
    final useCase = AnswerStudyStageUseCase(
      sessions: repo,
      factory: StudyModeFactory.standard(),
      clock: _FixedClock(now),
      idGenerator: _SeqIds(),
    );

    var state = start();
    final modesSeen = <StudyModeType>{};
    var guard = 0;
    while (!state.isComplete) {
      if (guard++ > 200) {
        fail('pipeline did not converge — likely a stuck mastery round');
      }
      modesSeen.add(state.currentMode);
      state = await useCase.call(state, _correctInputFor(state));
    }

    // All five stages ran, exactly once per card each (no mastery repeats, since
    // every answer passed): 5 stages × 5 cards.
    expect(modesSeen, stages.toSet());
    expect(repo.saved.length, stages.length * cardCount);
    expect(
      repo.saved.every(
        (a) => a.outcome == 'correct' || a.outcome == 'reviewed',
      ),
      isTrue,
      reason: 'a passing run records no wrong/almost',
    );
    expect(
      repo.saved.every((a) => a.isTerminal == false),
      isTrue,
      reason: 'stage attempts are non-terminal; grading is at finalize',
    );
  });
}

/// Builds a passing input for the stage under the cursor.
StudyModeInput _correctInputFor(StudyRuntimeState state) {
  final card = state.currentCard!;
  final round = state.position.roundIndex;
  final event = '${state.currentMode.id}-$round-${state.position.cardPosition}';
  switch (state.currentMode) {
    case StudyModeType.review:
      return ReviewInput(sessionId: 's1', cardId: card.cardId, eventId: event);
    case StudyModeType.match:
      return MatchInput(
        sessionId: 's1',
        cardId: card.cardId,
        roundIndex: round,
        eventId: event,
        termPairId: card.cardId,
        selectedMeaningPairId: card.cardId,
        termMeaning: card.meaning,
        selectedMeaning: card.meaning,
      );
    case StudyModeType.guess:
      final question = const GuessQuestionBuilder().build(
        sessionId: 's1',
        roundIndex: round,
        target: GuessCandidate(cardId: card.cardId, meaning: card.meaning),
        pool: <GuessCandidate>[
          for (final c in state.cardsById.values)
            GuessCandidate(cardId: c.cardId, meaning: c.meaning),
        ],
      );
      return GuessInput(
        sessionId: 's1',
        cardId: card.cardId,
        roundIndex: round,
        eventId: event,
        options: question.options,
        correctChoiceId: question.correctChoiceId,
        selectedChoiceId: question.correctChoiceId,
      );
    case StudyModeType.recall:
      return RecallInput(
        sessionId: 's1',
        cardId: card.cardId,
        roundIndex: round,
        eventId: event,
        revealed: true,
        resolution: RecallResolution.remembered,
        elapsedActiveMs: 1000,
      );
    case StudyModeType.fill:
      return FillInput(
        sessionId: 's1',
        cardId: card.cardId,
        roundIndex: round,
        eventId: event,
        rawInput: card.term,
        acceptedAnswers: <String>[card.term],
      );
    case StudyModeType.srsBinaryReview:
      throw StateError('srsBinaryReview is not a newLearning stage');
  }
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${_n++}';
}

/// Collects every atomic save so the drive can assert the full attempt set.
class _CollectingRepo implements StudySessionRepository {
  final List<StudyAttempt> saved = <StudyAttempt>[];

  @override
  Future<void> saveAttemptWithCheckpoint({
    required StudyAttempt attempt,
    required SessionCheckpoint checkpoint,
    SessionRoundOrder? newRoundOrder,
  }) async {
    saved.add(attempt);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not used in this test',
  );
}

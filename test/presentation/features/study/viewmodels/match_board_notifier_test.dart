import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/match_board_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/match_flush_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.6 — the Match board notifier classifies pairings via SM-MATCH-v1,
/// tracks sticky lapses (answer-study-stage.md §72), and flushes per-card
/// outcomes in cursor order.
void main() {
  final now = DateTime.utc(2026, 7, 23, 18);

  StudyRuntimeState runtime() => StudyRuntimeState.assemble(
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
    stages: const <StudyModeType>[StudyModeType.match],
    cardSnapshots: <SessionCardSnapshot>[
      for (var i = 0; i < 3; i++)
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
      cardIds: const <String>['c0', 'c1', 'c2'],
    ),
  );

  Future<ProviderContainer> harness({AnswerStudyStageUseCase? useCase}) async {
    final container = ProviderContainer(
      overrides: [
        studySessionRuntimeProvider.overrideWith(
          (ref) => Future.value(runtime()),
        ),
        if (useCase != null)
          answerStudyStageUseCaseProvider.overrideWithValue(useCase),
      ],
    );
    addTearDown(container.dispose);
    await container.read(studySessionRuntimeProvider.future);
    return container;
  }

  test('builds a board over the round with nothing locked', () async {
    final container = await harness();
    final board = container.read(matchBoardProvider);
    expect(board.isReady, isTrue);
    expect(board.pairCount, 3);
    expect(board.lockedCount, 0);
    expect(board.meanings.map((m) => m.cardId).toSet(), {'c0', 'c1', 'c2'});
  });

  test('a correct pairing locks the pair and advances progress', () async {
    final container = await harness();
    final board = container.read(matchBoardProvider.notifier);

    board.selectTerm('c0');
    board.selectMeaning('c0');

    final state = container.read(matchBoardProvider);
    expect(state.round.isLocked('c0'), isTrue);
    expect(state.lockedCount, 1);
    expect(state.selectedTermId, isNull);
  });

  test('a wrong pairing lapses the card and leaves it to retry', () async {
    final container = await harness();
    final board = container.read(matchBoardProvider.notifier);

    board.selectTerm('c0');
    board.selectMeaning('c1'); // a different meaning → wrong

    var state = container.read(matchBoardProvider);
    expect(state.round.hasLapsed('c0'), isTrue);
    expect(state.round.isLocked('c0'), isFalse);
    expect(state.flashOutcome, ModeOutcome.wrong);

    // Retry with the correct meaning completes the tile, lapse stays sticky.
    board.selectTerm('c0');
    board.selectMeaning('c0');
    state = container.read(matchBoardProvider);
    expect(state.round.isLocked('c0'), isTrue);
    expect(state.round.passedFor('c0'), isFalse);
  });

  test('flushInputs reproduces each card outcome in cursor order', () async {
    final container = await harness();
    final board = container.read(matchBoardProvider.notifier);

    // c0 clean, c1 lapses then completes, c2 clean.
    board.selectTerm('c0');
    board.selectMeaning('c0');
    board.selectTerm('c1');
    board.selectMeaning('c2'); // wrong for c1
    board.selectTerm('c1');
    board.selectMeaning('c1'); // complete c1
    board.selectTerm('c2');
    board.selectMeaning('c2');

    expect(container.read(matchBoardProvider).isComplete, isTrue);

    final inputs = board.flushInputs();
    expect(inputs.map((i) => i.cardId).toList(), ['c0', 'c1', 'c2']);
    // Re-classifying each input yields the recorded outcome.
    const strategy = MatchStudyModeStrategy();
    ModeOutcome outcome(MatchInput i) => strategy.evaluate(i).outcome;
    expect(outcome(inputs[0]), ModeOutcome.correct);
    expect(outcome(inputs[1]), ModeOutcome.wrong);
    expect(outcome(inputs[2]), ModeOutcome.correct);
  });

  test('flush threads the answer use case over every card in order', () async {
    final useCase = _RecordingAnswer(runtime());
    final container = await harness(useCase: useCase);
    final board = container.read(matchBoardProvider.notifier);

    for (final id in const ['c0', 'c1', 'c2']) {
      board.selectTerm(id);
      board.selectMeaning(id);
    }
    final inputs = board.flushInputs();

    await container.read(matchFlushProvider.notifier).flush(inputs);

    expect(container.read(matchFlushProvider), isA<AsyncData<void>>());
    expect(useCase.received.map((i) => (i as MatchInput).cardId).toList(), [
      'c0',
      'c1',
      'c2',
    ]);
  });
}

/// Records the inputs it is called with and returns the same runtime, so the
/// flush loop threads without touching a repository.
class _RecordingAnswer implements AnswerStudyStageUseCase {
  _RecordingAnswer(this._runtime);
  final StudyRuntimeState _runtime;
  final List<StudyModeInput> received = <StudyModeInput>[];

  @override
  Future<StudyRuntimeState> call(
    StudyRuntimeState current,
    StudyModeInput input,
  ) async {
    received.add(input);
    return _runtime;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

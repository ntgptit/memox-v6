import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_advance_policy.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/match_flush_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.6 — retrying a Match board that half committed.
///
/// The flush writes card by card, so a failure in the middle leaves a
/// committed prefix behind. The retry re-sends the whole board, which is the
/// only thing it has; what it must not do is answer a card that already has an
/// attempt. The idempotency key would not stop it either — by then the cursor
/// has moved, and the key is built from the position.
void main() {
  final now = DateTime.utc(2026, 7, 27, 12);

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
      for (final id in const <String>['c0', 'c1'])
        SessionCardSnapshot(
          id: 'sc-$id',
          sessionId: 's1',
          cardId: id,
          displayOrder: 0,
          term: id,
          meaning: id,
          contentVersion: 1,
          progressBox: 3,
          progressRevision: 0,
        ),
    ],
    currentOrder: SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: const <String>['c0', 'c1'],
    ),
  );

  MatchInput input(String cardId) => MatchInput(
    sessionId: 's1',
    cardId: cardId,
    roundIndex: 1,
    eventId: 'match-$cardId',
    termPairId: cardId,
    selectedMeaningPairId: cardId,
    termMeaning: cardId,
    selectedMeaning: cardId,
  );

  test('a retry after a half-committed board does not re-answer it', () async {
    final answer = _CursorAnswer(failOn: 'c1');
    final container = ProviderContainer(
      overrides: [
        studySessionRuntimeProvider.overrideWith(
          (ref) async => answer.current ?? runtime(),
        ),
        answerStudyStageUseCaseProvider.overrideWithValue(answer),
      ],
    );
    addTearDown(container.dispose);
    await container.read(studySessionRuntimeProvider.future);

    final notifier = container.read(matchFlushProvider.notifier);
    await notifier.flush(<MatchInput>[input('c0'), input('c1')]);

    expect(container.read(matchFlushProvider), isA<AsyncError<void>>());
    expect(answer.answered, <String>['c0', 'c1']);

    answer.failOn = null;
    await notifier.retry();

    expect(
      answer.answered,
      <String>['c0', 'c1', 'c1'],
      reason: 'c0 was already committed, so the retry stepped over it',
    );
    expect(container.read(matchFlushProvider), isA<AsyncData<void>>());
  });
}

/// An answer use case that advances the cursor like the real one, and fails
/// on a named card until told otherwise.
class _CursorAnswer implements AnswerStudyStageUseCase {
  _CursorAnswer({this.failOn});

  String? failOn;
  final List<String> answered = <String>[];
  StudyRuntimeState? current;

  @override
  Future<StudyRuntimeState> call(
    StudyRuntimeState runtime,
    StudyModeInput input,
  ) async {
    final cardId = runtime.position.currentCardId!;
    answered.add(cardId);
    if (cardId == failOn) {
      throw ValidationFailure(field: 'attempt', code: 'io');
    }
    final next = StudyRuntimeState(
      session: runtime.session,
      stages: runtime.stages,
      position: SessionPosition(
        stageIndex: runtime.position.stageIndex,
        roundIndex: runtime.position.roundIndex,
        roundCardIds: runtime.position.roundCardIds,
        cardPosition: runtime.position.cardPosition + 1,
        failedCardIds: runtime.position.failedCardIds,
      ),
      cardsById: runtime.cardsById,
    );
    current = next;
    return next;
  }
}

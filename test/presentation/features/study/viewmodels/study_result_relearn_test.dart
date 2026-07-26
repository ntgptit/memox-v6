import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_advance_policy.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_result_notifier.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.13 — starting a relearn session from the result screen
/// (`relearn-cards.md` §1: it is a new session the learner explicitly starts
/// from `Review missed`).
void main() {
  final now = DateTime.utc(2026, 7, 27, 10);

  StudyRuntimeState completedRuntime() => StudyRuntimeState(
    session: StudySession(
      id: 's1',
      type: SessionType.dueReview,
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
    stages: const <StudyModeType>[StudyModeType.srsBinaryReview],
    position: const SessionPosition(
      stageIndex: 0,
      roundIndex: 0,
      roundCardIds: <String>['c1'],
      cardPosition: 1,
      failedCardIds: <String>['c1'],
      phase: SessionPhase.sessionComplete,
    ),
    cardsById: const {},
  );

  ProviderContainer harness(_GatedStart start) {
    final container = ProviderContainer(
      overrides: [
        studySessionRuntimeProvider.overrideWith(
          (ref) async => completedRuntime(),
        ),
        finalizeStudySessionUseCaseProvider.overrideWithValue(_FakeFinalize()),
        startStudySessionUseCaseProvider.overrideWithValue(start),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a second tap while the first start is in flight is ignored', () async {
    final start = _GatedStart(now);
    final container = harness(start);
    // The runtime the result finalizes from has to be resolved first.
    await container.read(studySessionRuntimeProvider.future);
    final notifier = container.read(studyResultProvider.notifier);
    await notifier.finalize();

    final first = notifier.startRelearn();
    final second = await notifier.startRelearn();

    expect(
      second,
      isNull,
      reason: 'the second tap has nothing of its own to report',
    );

    start.finish();
    expect(await first, isA<AsyncData<void>>());
    expect(
      start.calls,
      1,
      reason:
          'a second start would find the session the first is creating and '
          'fail on the one-active-session rule, reporting a conflict for '
          'what the learner did once',
    );
  });

  test('a start that fails comes back as the failure it was', () async {
    final start = _GatedStart(now);
    final container = harness(start);
    await container.read(studySessionRuntimeProvider.future);
    final notifier = container.read(studyResultProvider.notifier);
    await notifier.finalize();

    final pending = notifier.startRelearn();
    start.fail();

    expect(await pending, isA<AsyncError<void>>());
  });
}

/// A start whose write completes only when the test says so.
class _GatedStart implements StartStudySessionUseCase {
  _GatedStart(this._now);

  final DateTime _now;
  final Completer<void> _gate = Completer<void>();
  int calls = 0;

  void finish() => _gate.complete();
  void fail() => _gate.completeError(StateError('queue not written'));

  @override
  Future<StudySession> call({
    required String deckId,
    required SessionScope scope,
    required SessionType type,
    StudyModeType? selectedMode,
    List<String> relearnCardIds = const <String>[],
  }) async {
    calls++;
    await _gate.future;
    return StudySession(
      id: 'relearn-1',
      type: type,
      deckId: deckId,
      scope: scope,
      state: SessionState.active,
      revision: 0,
      snapshotVersion: 1,
      scheduleSrs: true,
      startedAt: _now,
      finalizedAt: null,
      createdAt: _now,
      updatedAt: _now,
    );
  }
}

/// A finalize that returns a summary with one missed card, so the result has
/// something to relearn.
class _FakeFinalize implements FinalizeStudySessionUseCase {
  @override
  Future<StudySessionSummary> call(StudyRuntimeState runtime) async {
    return const StudySessionSummary(
      reviewedCount: 1,
      correctCount: 0,
      missedCardIds: <String>['c1'],
    );
  }
}

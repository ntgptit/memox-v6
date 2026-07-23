import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_start_notifier.dart';

/// WBS 5.6.1/2 — the Study command runs [StartStudySessionUseCase] behind the
/// action runner: a started session lands on data, a blocked start surfaces the
/// typed failure, and it never touches a repository (`start-study-session.md`).
void main() {
  final now = DateTime.utc(2026, 7, 24, 10);

  StudySession session() => StudySession(
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
  );

  ProviderContainer harness(_FakeStart useCase) {
    final container = ProviderContainer(
      overrides: [startStudySessionUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('start commits a deck-subtree session and lands on data', () async {
    final useCase = _FakeStart(result: session());
    final container = harness(useCase);

    await container
        .read(studyStartProvider.notifier)
        .start(deckId: 'd1', type: SessionType.newLearning);

    expect(container.read(studyStartProvider), isA<AsyncData<void>>());
    expect(useCase.calls, 1);
    expect(useCase.deckId, 'd1');
    expect(useCase.scope, SessionScope.subtree);
    expect(useCase.type, SessionType.newLearning);
  });

  test('a blocked start surfaces the typed failure', () async {
    final useCase = _FakeStart(
      error: ValidationFailure(field: 'session', code: 'no-eligible-cards'),
    );
    final container = harness(useCase);

    await container.read(studyStartProvider.notifier).start(deckId: 'd1');

    final state = container.read(studyStartProvider);
    expect(state, isA<AsyncError<void>>());
    expect((state as AsyncError<void>).error, isA<ValidationFailure>());
  });

  test('a second start while one is in flight is ignored', () async {
    final useCase = _FakeStart(result: session());
    final container = harness(useCase);
    final notifier = container.read(studyStartProvider.notifier);

    final first = notifier.start(deckId: 'd1');
    // The re-entrant guard drops this call before it reaches the use case.
    await notifier.start(deckId: 'd1');
    await first;

    expect(useCase.calls, 1);
  });
}

class _FakeStart extends StartStudySessionUseCase {
  _FakeStart({this.result, this.error})
    : super(
        progress: _Unused(),
        cards: _UnusedCards(),
        sessions: _UnusedSessions(),
        clock: _Unused(),
        idGenerator: _Unused(),
      );

  final StudySession? result;
  final Object? error;

  int calls = 0;
  String? deckId;
  SessionScope? scope;
  SessionType? type;

  @override
  Future<StudySession> call({
    required String deckId,
    required SessionScope scope,
    required SessionType type,
    StudyModeType? selectedMode,
  }) async {
    calls++;
    this.deckId = deckId;
    this.scope = scope;
    this.type = type;
    if (error != null) throw error!;
    return result!;
  }
}

/// Stand-ins for the constructor dependencies; the overridden [call] never uses
/// them. The two card/session repositories carry an incompatible `findById`, so
/// they cannot share one stub class.
class _Unused implements LearningProgressRepository, AppClock, IdGenerator {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedCards implements FlashcardRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedSessions implements StudySessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

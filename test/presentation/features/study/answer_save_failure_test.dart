import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
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
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/study_session_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.3 — `answer-study-stage.md` §6: "Failure dialog: `Couldn't save
/// your answer. Your answer is still here.` + `Try again`."
///
/// Nothing read the answer command's state, so a save that failed looked
/// exactly like one still in flight: the card stayed put and said nothing. The
/// dialog is mounted on the dispatcher, which is the one widget outliving the
/// stage screens that all submit through the same command.
void main() {
  final now = DateTime.utc(2026, 7, 27, 12);

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2200);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  StudyRuntimeState runtime() => StudyRuntimeState.assemble(
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
    cardSnapshots: <SessionCardSnapshot>[
      SessionCardSnapshot(
        id: 'sc0',
        sessionId: 's1',
        cardId: 'c0',
        displayOrder: 0,
        term: 'friend-term',
        meaning: 'friend',
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
      cardIds: const <String>['c0'],
    ),
  );

  StudyRuntimeState matchRuntime() => StudyRuntimeState.assemble(
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
      SessionCardSnapshot(
        id: 'sc0',
        sessionId: 's1',
        cardId: 'c0',
        displayOrder: 0,
        term: 'friend-term',
        meaning: 'friend',
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
      cardIds: const <String>['c0'],
    ),
  );

  Widget wrap(_FailingAnswer answer) => ProviderScope(
    overrides: [
      studySessionRuntimeProvider.overrideWith(
        (ref) => Future.value(runtime()),
      ),
      answerStudyStageUseCaseProvider.overrideWithValue(answer),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StudySessionScreen(),
    ),
  );

  testWidgets('a save that fails says so and keeps the answer', (tester) async {
    await tester.pumpWidget(wrap(_FailingAnswer()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t save your answer'), findsOneWidget);
    expect(find.text('Your answer is still here.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  // §6: "Retry cùng attempt không tạo record hoặc progress update lần hai."
  // The same input is re-submitted, so the attempt's request id is the same
  // one the store already knows how to absorb.
  testWidgets('Try again re-submits the answer that failed', (tester) async {
    final answer = _FailingAnswer();
    await tester.pumpWidget(wrap(answer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();
    answer.failNext = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(answer.submitted, hasLength(2));
    expect(
      answer.submitted.last.cardId,
      answer.submitted.first.cardId,
      reason: 'the retry carries the same answer, not a fresh one',
    );
    expect(find.text('Couldn’t save your answer'), findsNothing);
  });

  // Match commits a whole board through its own command, so the dispatcher's
  // answer listener never saw its failures: `Next round` on a save that could
  // not land did nothing, and the board sat there looking finished.
  testWidgets('a Match board that cannot be committed says so', (tester) async {
    final answer = _FailingAnswer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studySessionRuntimeProvider.overrideWith(
            (ref) => Future.value(matchRuntime()),
          ),
          answerStudyStageUseCaseProvider.overrideWithValue(answer),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StudySessionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // One pair: tapping both halves completes the board.
    await tester.tap(find.text('friend-term'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('friend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next round'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t save your answer'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    answer.failNext = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t save your answer'), findsNothing);
    expect(answer.submitted, hasLength(2), reason: 'the board was re-sent');
  });

  // §9 gives a stale write its own copy: the session moved elsewhere, so the
  // fix is to re-read it rather than to push the same answer again.
  testWidgets('a stale write asks for a reload instead', (tester) async {
    final answer = _FailingAnswer(
      failure: ConflictFailure(code: 'revision', entity: 'study_sessions'),
    );
    await tester.pumpWidget(wrap(answer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(find.text('This session changed elsewhere'), findsOneWidget);
    expect(find.text('Reload your saved progress.'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
}

/// An answer use case that fails until told otherwise, recording what it was
/// asked to save.
class _FailingAnswer implements AnswerStudyStageUseCase {
  _FailingAnswer({AppFailure? failure})
    : _failure = failure ?? ValidationFailure(field: 'attempt', code: 'io');

  final AppFailure _failure;
  final List<StudyModeInput> submitted = <StudyModeInput>[];
  bool failNext = true;

  @override
  Future<StudyRuntimeState> call(
    StudyRuntimeState runtime,
    StudyModeInput input,
  ) async {
    submitted.add(input);
    if (failNext) throw _failure;
    return runtime;
  }
}

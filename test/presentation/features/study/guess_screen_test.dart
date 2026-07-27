import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_modes/study_mode_input.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/presentation/features/study/screens/study_session_screen.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/guess_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';

/// WBS 5.6.7 — the Guess screen shows the term prompt and five meaning choices,
/// with a Continue action after selection (`guess-card-meaning.md`, kit
/// guess-mode).
void main() {
  final now = DateTime.utc(2026, 7, 23, 17);

  // A tall surface so the lazily-built option list renders every card
  // (five options + the prompt) without scrolling.
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2400);
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

  StudyRuntimeState runtime({required int cardCount}) {
    final meanings = <String>[
      'school',
      'hospital',
      'park',
      'restaurant',
      'library',
      'market',
    ];
    return StudyRuntimeState.assemble(
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
      stages: const <StudyModeType>[StudyModeType.guess],
      cardSnapshots: <SessionCardSnapshot>[
        for (var i = 0; i < cardCount; i++)
          SessionCardSnapshot(
            id: 'sc$i',
            sessionId: 's1',
            cardId: 'c$i',
            displayOrder: i,
            term: 'term-$i',
            meaning: meanings[i],
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
  }

  Widget wrap(StudyRuntimeState state) => ProviderScope(
    overrides: [
      studySessionRuntimeProvider.overrideWith((ref) => Future.value(state)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const GuessScreen(),
    ),
  );

  testWidgets('renders the term and five distinct meaning options', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime(cardCount: 6)));
    await tester.pumpAndSettle();

    expect(find.text('Guess'), findsOneWidget);
    expect(find.text('term-0'), findsOneWidget);
    // The correct meaning plus four distractors are all shown.
    expect(find.text('school'), findsOneWidget);
    // Exactly five option cards' worth of meanings render.
    final shown = <String>[
      'school',
      'hospital',
      'park',
      'restaurant',
      'library',
      'market',
    ].where((m) => tester.any(find.text(m))).length;
    expect(shown, 5);
  });

  testWidgets('selecting an option reveals the Continue action', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime(cardCount: 6)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(MxButton, 'Continue'), findsNothing);
    await tester.tap(find.text('school'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MxButton, 'Continue'), findsOneWidget);
  });

  // §6: "Failure dialog: `Couldn't save your answer. Your answer is still
  // here.`" The screen cleared the selection the moment Continue was tapped,
  // so a save that failed took the learner's choice off the screen while the
  // dialog told them it was still there.
  testWidgets('a save that fails leaves the chosen option chosen', (
    tester,
  ) async {
    final answer = _FailingAnswer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studySessionRuntimeProvider.overrideWith(
            (ref) => Future.value(runtime(cardCount: 6)),
          ),
          answerStudyStageUseCaseProvider.overrideWithValue(answer),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // The dispatcher, not the bare screen: it owns the failure dialog
          // and its listener is what keeps the answer command alive while the
          // save is in flight.
          home: const StudySessionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('school'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t save your answer'), findsOneWidget);
    // The Continue action is still behind the dialog, and it appears only
    // when an option is chosen — so the choice survived the failed save.
    expect(find.widgetWithText(MxButton, 'Continue'), findsOneWidget);
  });

  testWidgets(
    'a pool without five distinct meanings shows a recovery message',
    (tester) async {
      await tester.pumpWidget(wrap(runtime(cardCount: 3)));
      await tester.pumpAndSettle();
      expect(
        find.text('Not enough distinct options to guess this card.'),
        findsOneWidget,
      );
    },
  );
}

/// An answer use case that always fails, so the screen is left holding the
/// selection it just tried to commit.
class _FailingAnswer implements AnswerStudyStageUseCase {
  @override
  Future<StudyRuntimeState> call(
    StudyRuntimeState runtime,
    StudyModeInput input,
  ) async {
    throw ValidationFailure(field: 'attempt', code: 'io');
  }
}

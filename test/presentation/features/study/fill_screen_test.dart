import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_checkpoint.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/screens/fill_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_language_provider.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.9 — Fill compares the typed term against the accepted answer under
/// SM-FILL-v1 and reveals correct/wrong feedback (`fill-card-answer.md`).
void main() {
  final now = DateTime.utc(2026, 7, 23, 19);

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
    stages: const <StudyModeType>[StudyModeType.fill],
    cardSnapshots: <SessionCardSnapshot>[
      SessionCardSnapshot(
        id: 'sc0',
        sessionId: 's1',
        cardId: 'c0',
        displayOrder: 0,
        term: 'apple',
        meaning: 'fruit',
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
      cardIds: const <String>['c0'],
    ),
  );

  /// The same one-card round, re-opened at [roundIndex] — what a mastery retry
  /// round looks like when the only card in it failed.
  StudyRuntimeState atRound(int roundIndex) => StudyRuntimeState.assemble(
    session: runtime().session,
    stages: const <StudyModeType>[StudyModeType.fill],
    cardSnapshots: <SessionCardSnapshot>[
      SessionCardSnapshot(
        id: 'sc0',
        sessionId: 's1',
        cardId: 'c0',
        displayOrder: 0,
        term: 'apple',
        meaning: 'fruit',
        contentVersion: 1,
        progressBox: 0,
        progressRevision: 0,
      ),
    ],
    currentOrder: SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: roundIndex,
      seed: 1,
      cardIds: const <String>['c0'],
    ),
    checkpoint: SessionCheckpoint(
      id: 'cp1',
      sessionId: 's1',
      stageIndex: 0,
      roundIndex: roundIndex,
      cardPosition: 0,
      failedCardIds: const <String>['c0'],
      timerStateJson: '{}',
      stateVersion: 1,
      updatedAt: now,
    ),
  );

  Widget wrap({StudyLanguageContext? languages}) => ProviderScope(
    overrides: [
      studySessionRuntimeProvider.overrideWith(
        (ref) => Future.value(runtime()),
      ),
      if (languages != null)
        studyLanguageContextProvider(
          deckId: 'd1',
        ).overrideWith((ref) => Future.value(languages)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FillScreen(),
    ),
  );

  // §4: "Hint state thuộc từng attempt và reset khi Card bắt đầu attempt ở
  // round mới", and a new round "mở input trống cho attempt mới".
  //
  // The feedback and hint were keyed by card alone. On a one-card retry round
  // the stage re-opens on the same card, so the widget element survives the
  // round boundary, the providers are never released, and the retry begins
  // already graded — input locked, answer revealed, Continue showing. The
  // learner cannot answer, so the round can never be passed and the session
  // can never finish.
  testWidgets('a retry round on the same card starts a fresh attempt', (
    tester,
  ) async {
    var round = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studySessionRuntimeProvider.overrideWith(
            (ref) => Future.value(atRound(round)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FillScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    expect(find.textContaining('starts with'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pear');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    // Graded wrong: the answer is revealed and the CTA becomes Continue.
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('apple'), findsWidgets);

    // The failed round closes and the retry round opens on the same card.
    round = 2;
    ProviderScope.containerOf(
      tester.element(find.byType(FillScreen)),
    ).invalidate(studySessionRuntimeProvider);
    await tester.pumpAndSettle();

    expect(find.text('Check'), findsOneWidget, reason: 'a fresh attempt');
    expect(find.text('Continue'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isTrue);
    // §4 again: the hint belongs to the attempt that asked for it.
    expect(find.text('Help'), findsOneWidget);
    expect(find.textContaining('starts with'), findsNothing);
  });

  // The kit requires deck-driven language labels — "Type the term (Korean)",
  // not "Type the term" — so a learner with two active pairs can tell which
  // script the prompt wants.
  testWidgets('the prompt names the deck term language', (tester) async {
    await tester.pumpWidget(
      wrap(
        languages: const StudyLanguageContext(
          termLanguageName: '한국어',
          meaningLanguageName: 'English',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Type the term (한국어)'), findsOneWidget);
    expect(find.text('Type the term'), findsNothing);
  });

  testWidgets('an unresolved pair falls back to the plain prompt', (
    tester,
  ) async {
    // Empty rather than absent: the deck or its pair failed to resolve. The
    // unqualified copy is correct here — "Type the term ()" would not be.
    await tester.pumpWidget(
      wrap(
        languages: const StudyLanguageContext(
          termLanguageName: '',
          meaningLanguageName: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Type the term'), findsOneWidget);
  });

  testWidgets('waiting shows the meaning, input and Check/Help', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Fill'), findsOneWidget);
    expect(find.text('fruit'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    // Nothing is graded yet, so there is no Continue and no answer reveal.
    expect(find.text('Continue'), findsNothing);
    expect(find.textContaining('Answer:'), findsNothing);
  });

  testWidgets('a matching answer grades correct and offers Continue', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'apple');
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Check'), findsNothing);
    // A correct answer does not reveal the answer line.
    expect(find.textContaining('Answer:'), findsNothing);
  });

  testWidgets('a wrong answer reveals the answer and offers Continue', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'banana');
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Answer: apple'), findsOneWidget);
  });

  testWidgets('a blank answer keeps Check disabled (no grading)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Check is present but disabled; tapping it grades nothing.
    await tester.tap(find.text('Check'));
    await tester.pump();
    expect(find.text('Continue'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1200, 2400);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
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
    final shown = <String>['school', 'hospital', 'park', 'restaurant', 'library', 'market']
        .where((m) => tester.any(find.text(m)))
        .length;
    expect(shown, 5);
  });

  testWidgets('selecting an option reveals the Continue action', (tester) async {
    await tester.pumpWidget(wrap(runtime(cardCount: 6)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(MxButton, 'Continue'), findsNothing);
    await tester.tap(find.text('school'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MxButton, 'Continue'), findsOneWidget);
  });

  testWidgets('a pool without five distinct meanings shows a recovery message', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime(cardCount: 3)));
    await tester.pumpAndSettle();
    expect(
      find.text('Not enough distinct options to guess this card.'),
      findsOneWidget,
    );
  });
}

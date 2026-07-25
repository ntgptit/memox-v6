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
import 'package:memox_v6/presentation/features/study/screens/match_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.6 — the Match board (kit `match-mode`).
///
/// Match had no widget test, no parity fixture, no spec and no `MX-VIS-*` row
/// while the other four modes had all four. The column order below is the
/// reason that mattered: a matching board is functionally symmetric, so
/// nothing about its behaviour reveals which side holds terms. Only the kit
/// says, and it says meanings left, terms right.
void main() {
  final now = DateTime.utc(2026, 7, 26, 12);

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

  StudyRuntimeState runtime() {
    const pairs = <(String, String)>[
      ('사랑', 'love'),
      ('학교', 'school'),
      ('음식', 'food'),
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
      stages: const <StudyModeType>[StudyModeType.match],
      cardSnapshots: <SessionCardSnapshot>[
        for (var i = 0; i < pairs.length; i++)
          SessionCardSnapshot(
            id: 'sc$i',
            sessionId: 's1',
            cardId: 'c$i',
            displayOrder: i,
            term: pairs[i].$1,
            meaning: pairs[i].$2,
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
        cardIds: <String>[for (var i = 0; i < pairs.length; i++) 'c$i'],
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
      home: const MatchScreen(),
    ),
  );

  testWidgets('renders both sides of the board', (tester) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    expect(find.text('Match'), findsOneWidget);
    // Unlike Guess, every card contributes both a term and a meaning tile.
    for (final label in <String>['사랑', '학교', '음식', 'love', 'school', 'food']) {
      expect(find.text(label), findsOneWidget, reason: '$label tile missing');
    }
  });

  testWidgets('meanings are the left column and terms the right', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    // The kit fixes the sides: `LEFT = ['time','love',…]` are meanings and
    // `RIGHT = ['사랑','학교',…]` are terms. They shipped reversed, and no
    // behaviour changes when they are — which is exactly why this is pinned
    // by position rather than left to the pixel gate, whose ratio on a board
    // of white tiles absorbed the whole swap.
    final meaning = tester.getTopLeft(find.text('love'));
    final term = tester.getTopLeft(find.text('사랑'));
    expect(
      meaning.dx,
      lessThan(term.dx),
      reason: 'meanings must sit left of terms',
    );
  });
}

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
import 'package:memox_v6/presentation/features/study/screens/study_session_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6 — the study route dispatches to the current stage's mode screen, or
/// a placeholder when no session is active.
void main() {
  final now = DateTime.utc(2026, 7, 23, 16);

  StudyRuntimeState reviewRuntime() => StudyRuntimeState.assemble(
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
    stages: const <StudyModeType>[StudyModeType.review, StudyModeType.match],
    cardSnapshots: <SessionCardSnapshot>[
      SessionCardSnapshot(
        id: 'sc-a',
        sessionId: 's1',
        cardId: 'a',
        displayOrder: 0,
        term: '학교',
        meaning: 'school',
        contentVersion: 1,
        progressBox: 0,
        progressRevision: 0,
      ),
    ],
    currentOrder: const SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: <String>['a'],
    ),
  );

  Widget wrap(StudyRuntimeState? state) => ProviderScope(
    overrides: [
      studySessionRuntimeProvider.overrideWith((ref) => Future.value(state)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StudySessionScreen(),
    ),
  );

  testWidgets('dispatches a Review stage to the Review screen', (tester) async {
    await tester.pumpWidget(wrap(reviewRuntime()));
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('school'), findsOneWidget);
  });

  testWidgets('shows a placeholder when no session is active', (tester) async {
    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();
    expect(find.text('No study session is in progress.'), findsOneWidget);
  });
}

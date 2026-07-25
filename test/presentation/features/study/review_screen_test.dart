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
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/presentation/features/study/screens/review_screen.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';

/// WBS 5.6.5 — the Review screen shows term + meaning together with browse
/// navigation (`review-cards.md`, kit `review-mode`).
void main() {
  final now = DateTime.utc(2026, 7, 23, 15);

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
    stages: const <StudyModeType>[StudyModeType.review, StudyModeType.match],
    cardSnapshots: <SessionCardSnapshot>[
      _card('a', 0, 'school', '학교'),
      _card('b', 1, 'teacher', '선생님'),
    ],
    currentOrder: const SessionRoundOrder(
      id: 'ro1',
      sessionId: 's1',
      roundIndex: 1,
      seed: 1,
      cardIds: <String>['a', 'b'],
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
      home: const ReviewScreen(),
    ),
  );

  testWidgets('shows the current card term + meaning and browse controls', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    expect(find.text('school'), findsOneWidget);
    expect(find.text('학교'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    // Kit review-mode bottom hint between the chevrons.
    expect(find.text('Swipe to continue'), findsOneWidget);

    // The previous chevron is disabled on the first card; next is enabled.
    final previous = tester.widget<MxIconButton>(
      find.ancestor(
        of: find.byIcon(Symbols.chevron_left_rounded),
        matching: find.byType(MxIconButton),
      ),
    );
    expect(previous.onPressed, isNull);
    final next = tester.widget<MxIconButton>(
      find.ancestor(
        of: find.byIcon(Symbols.chevron_right_rounded),
        matching: find.byType(MxIconButton),
      ),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('shows an empty message when no session is active', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();
    expect(find.text('No study session is in progress.'), findsOneWidget);
  });
}

SessionCardSnapshot _card(String id, int order, String meaning, String term) =>
    SessionCardSnapshot(
      id: 'sc-$id',
      sessionId: 's1',
      cardId: id,
      displayOrder: order,
      term: term,
      meaning: meaning,
      contentVersion: 1,
      progressBox: 0,
      progressRevision: 0,
    );

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
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
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

  // The board is symmetric: a learner may open a pair from either side. This
  // shipped term-first only — `selectMeaning` returned early with no term
  // selected, so a first tap on the meaning column did nothing at all: no
  // selection, no feedback, no way to tell the tile was live. The kit's own
  // `match-mode--selected` shot highlights a *meaning* tile as the first pick.
  testWidgets('a meaning can be picked first and reads selected', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('love'));
    await tester.pumpAndSettle();

    final tile = tester.widget<MxCard>(
      find.ancestor(of: find.text('love'), matching: find.byType(MxCard)).first,
    );
    expect(tile.variant, MxCardVariant.primarySoft);
  });

  testWidgets('meaning-first closes a pair exactly as term-first does', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    // 사랑 / love is a true pair; opening from the meaning side must resolve
    // it, not sit inert waiting for a term to be chosen first.
    await tester.tap(find.text('love'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사랑'));
    await tester.pumpAndSettle();

    for (final label in <String>['love', '사랑']) {
      final tile = tester.widget<MxCard>(
        find
            .ancestor(of: find.text(label), matching: find.byType(MxCard))
            .first,
      );
      expect(
        tile.variant,
        MxCardVariant.successSoft,
        reason: '$label should read correct after the pair resolves',
      );
    }
  });

  testWidgets('a matched pair leaves the board on the next interaction', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('love'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사랑'));
    await tester.pumpAndSettle();

    // Any further interaction clears the flash; the solved pair then renders
    // hidden at full height (kit `Tile.jsx`: `visibility: hidden`), so the
    // board keeps its shape without the pair competing for attention.
    await tester.tap(find.text('school'));
    await tester.pumpAndSettle();

    final solved = tester.widget<Visibility>(
      find
          .ancestor(of: find.text('love'), matching: find.byType(Visibility))
          .first,
    );
    expect(solved.visible, isFalse);
    expect(solved.maintainSize, isTrue);
  });

  // A selection used to be a one-way door: the only way out was to pair the
  // tile with something, so a mis-tap forced the learner to record a lapse on
  // a card they had not actually got wrong. It also made the kit's resting
  // `match-mode--almost` frame unreachable — every route out of a selection
  // left either a selected tile or a flashing outcome.
  testWidgets('tapping the selected tile again cancels the selection', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('love'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MxCard>(
            find
                .ancestor(of: find.text('love'), matching: find.byType(MxCard))
                .first,
          )
          .variant,
      MxCardVariant.primarySoft,
    );

    await tester.tap(find.text('love'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<MxCard>(
            find
                .ancestor(of: find.text('love'), matching: find.byType(MxCard))
                .first,
          )
          .variant,
      MxCardVariant.flat,
      reason: 'the tile should return to resting, not stay selected',
    );

    // And the board is genuinely free: the next pairing resolves normally
    // rather than against the abandoned pick.
    await tester.tap(find.text('school'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('학교'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<MxCard>(
            find
                .ancestor(
                  of: find.text('school'),
                  matching: find.byType(MxCard),
                )
                .first,
          )
          .variant,
      MxCardVariant.successSoft,
    );
  });

  testWidgets('cancelling works from the term side too', (tester) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('사랑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사랑'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<MxCard>(
            find
                .ancestor(of: find.text('사랑'), matching: find.byType(MxCard))
                .first,
          )
          .variant,
      MxCardVariant.flat,
    );
  });

  // `exit-study-session.md` §5: "Warn unfinished input not saved". A Match
  // round commits nothing until the whole board is cleared, so leaving with
  // pairs locked throws all of them away — and the shared exit copy calls that
  // "the current unfinished answer", which is the wrong size by a board.
  testWidgets('leaving mid-board says the round will start over', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('love'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사랑'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Exit'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('this round starts over'),
      findsOneWidget,
      reason: 'the matched pair is not saved, and the confirm has to say so',
    );

    await tester.tap(find.text('Keep studying'));
    await tester.pumpAndSettle();
  });

  // With nothing matched there is nothing extra to warn about, and the shared
  // copy is exactly right.
  testWidgets('leaving an untouched board adds no extra warning', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(runtime()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Exit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('this round starts over'), findsNothing);
    expect(find.text('Leave this session?'), findsOneWidget);

    await tester.tap(find.text('Keep studying'));
    await tester.pumpAndSettle();
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

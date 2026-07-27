import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/core/time/app_time_zone.dart';
import '../../../support/fake_clock.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/presentation/features/search/routes/search_routes.dart';
import 'package:memox_v6/presentation/features/today/routes/today_routes.dart';
import 'package:memox_v6/app/router/route_paths.dart';
import 'package:go_router/go_router.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/today/screens/today_screen.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_loading_skeleton.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_greeting_header.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_goal_card.dart';
import 'package:memox_v6/domain/study_goal/daily_progress_status.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_note.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_fab.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/today/start_review_outcome.dart';
import 'package:memox_v6/domain/today/continue_session_outcome.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/continue_session_notifier.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/start_review_notifier.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:memox_v6/domain/learning_progress/library_mastery.dart';
import 'package:memox_v6/presentation/features/deck/widgets/deck_summary_row.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_badge.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';

/// WBS 5.7.2 — the Today entry renders one primary action per projection state,
/// plus loading (no fake zeros) and load-error (`load-today-dashboard.md`).
void main() {
  Widget wrap(Override override) => ProviderScope(
    overrides: [override],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TodayScreen(),
    ),
  );

  Override data(TodayProjection projection) =>
      todayProjectionProvider.overrideWith((ref) => Future.value(projection));

  /// Today under a real router beside search, for the return-refresh test.
  Widget routed(GoRouter router, Override override) => ProviderScope(
    overrides: [override],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );

  /// Hands out the snapshots in order, so a re-read is visible on screen
  /// rather than inferred from a call count.
  Override snapshots(List<TodayProjection> takes) {
    var read = 0;
    return todayProjectionProvider.overrideWith((ref) {
      final projection = takes[read.clamp(0, takes.length - 1)];
      read++;
      return Future.value(projection);
    });
  }

  testWidgets('a paused session offers Resume', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.continueSession,
            dueCount: 12,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Study session paused'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Resume session'), findsOneWidget);
  });

  testWidgets('due cards offer Start review with the count', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.startReview,
            dueCount: 7,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 cards due'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Start review'), findsOneWidget);
  });

  testWidgets('an empty library offers Create a deck', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.createLibrary,
            dueCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start your first deck'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Create a deck'), findsOneWidget);
  });

  // The kit replaces the Review CTA on a caught-up day; it does not leave the
  // screen without one. This state used to offer nothing at all.
  testWidgets('caught up shows the message and a way onward', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.caughtUp,
            dueCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Explore decks'), findsOneWidget);
  });

  testWidgets('loading shows no fake zeros', (tester) async {
    final never = Completer<TodayProjection>();
    await tester.pumpWidget(
      wrap(todayProjectionProvider.overrideWith((ref) => never.future)),
    );
    await tester.pump();
    // No "0 cards due" or a result while finalizing.
    expect(find.textContaining('0 cards due'), findsNothing);
    expect(find.text('Start review'), findsNothing);
  });

  testWidgets('a load error offers Retry', (tester) async {
    await tester.pumpWidget(
      wrap(
        todayProjectionProvider.overrideWith(
          (ref) => Future<TodayProjection>.error('boom'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today couldn’t load'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Retry'), findsOneWidget);
  });

  // Kit `dashboard/greeting`: the greeting sits in the scroll body, above
  // every state — including loading, which is why it is outside the async
  // builder rather than inside each branch.
  testWidgets('the greeting renders above the loading skeleton', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        todayProjectionProvider.overrideWith(
          (ref) => Completer<TodayProjection>().future,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TodayGreetingHeader), findsOneWidget);
    expect(find.byType(TodayLoadingSkeleton), findsOneWidget);
  });

  testWidgets('the greeting follows the time of day', (tester) async {
    Future<String> greetingAt(int hour) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayGreetingHeader(now: DateTime(2026, 7, 26, hour)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((t) => t.startsWith('Good'));
    }

    expect(await greetingAt(9), 'Good morning');
    expect(await greetingAt(14), 'Good afternoon');
    expect(await greetingAt(20), 'Good evening');
  });

  // Kit `dashboard/goal`. The data has existed since the projection gained
  // `dailyProgress`; this is the display it was composed for.
  group('daily goal card', () {
    TodayProjection withGoal(DailyProgressStatus progress) => TodayProjection(
      primaryAction: TodayPrimaryAction.caughtUp,
      dueCount: 0,
      dailyProgress: progress,
    );

    testWidgets('shows progress toward the target in cards', (tester) async {
      await tester.pumpWidget(
        wrap(
          data(
            withGoal(
              const DailyProgressStatus(
                streakDays: 3,
                goalDoneCards: 14,
                goalTargetCards: 20,
                studiedToday: true,
                hasStreakHistory: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily goal'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('14 of 20 cards · 6 left'), findsOneWidget);
    });

    testWidgets('a met goal reads complete, not a remainder', (tester) async {
      await tester.pumpWidget(
        wrap(
          data(
            withGoal(
              const DailyProgressStatus(
                streakDays: 4,
                goalDoneCards: 22,
                goalTargetCards: 20,
                studiedToday: true,
                hasStreakHistory: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Over-target is allowed and displayed as done — never as 110%, and
      // never as "-2 left".
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('All 20 cards · goal complete'), findsOneWidget);
    });

    testWidgets('no configured goal shows no card', (tester) async {
      await tester.pumpWidget(
        wrap(data(withGoal(const DailyProgressStatus.none()))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TodayGoalCard), findsNothing);
      expect(find.text('You’re all caught up'), findsOneWidget);
    });

    // Kit and spec §3: due/resume content precedes goal/streak content. The
    // card landed above the primary section, which put a supporting metric
    // ahead of the screen's one objective.
    testWidgets('the card sits below the primary section', (tester) async {
      await tester.pumpWidget(
        wrap(
          data(
            TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
              dailyProgress: const DailyProgressStatus(
                streakDays: 3,
                goalDoneCards: 14,
                goalTargetCards: 20,
                studiedToday: true,
                hasStreakHistory: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cta = tester.getTopLeft(
        find.widgetWithText(MxButton, 'Start review'),
      );
      final card = tester.getTopLeft(find.byType(TodayGoalCard));
      expect(card.dy, greaterThan(cta.dy));
    });
  });

  // Kit `dashboard--goal-met` / `--streak-reset` / `--not-studied`.
  group('state notes', () {
    TodayProjection standing(DailyProgressStatus progress) => TodayProjection(
      primaryAction: TodayPrimaryAction.startReview,
      dueCount: 7,
      dailyProgress: progress,
    );

    Future<void> pump(tester, DailyProgressStatus progress) async {
      await tester.pumpWidget(wrap(data(standing(progress))));
      await tester.pumpAndSettle();
    }

    testWidgets('a met goal celebrates without crediting itself', (
      tester,
    ) async {
      await pump(
        tester,
        const DailyProgressStatus(
          streakDays: 5,
          goalDoneCards: 20,
          goalTargetCards: 20,
          studiedToday: true,
          hasStreakHistory: true,
        ),
      );

      expect(
        find.text('Daily goal reached! Today counts toward your streak.'),
        findsOneWidget,
      );
      // The streak day came from studying, not from the target — the kit's
      // "Streak +1" would say otherwise.
      expect(find.textContaining('+1'), findsNothing);
    });

    testWidgets('a lapsed streak reads as reset', (tester) async {
      await pump(
        tester,
        const DailyProgressStatus(
          streakDays: 0,
          goalDoneCards: 0,
          goalTargetCards: 20,
          hasStreakHistory: true,
        ),
      );

      expect(
        find.text('Streak reset — study today to start again.'),
        findsOneWidget,
      );
    });

    // The same zero, a different fact. Naming a loss they never had would be
    // the first thing a new learner reads.
    testWidgets('a first-time learner is told nothing reset', (tester) async {
      await pump(
        tester,
        const DailyProgressStatus(
          streakDays: 0,
          goalDoneCards: 0,
          goalTargetCards: 20,
        ),
      );

      expect(find.byType(MxNote), findsNothing);
    });

    testWidgets('a live streak with nothing done today nudges', (tester) async {
      await pump(
        tester,
        const DailyProgressStatus(
          streakDays: 12,
          goalDoneCards: 0,
          goalTargetCards: 20,
          hasStreakHistory: true,
        ),
      );

      expect(
        find.text('You haven’t studied today — study to keep your streak.'),
        findsOneWidget,
      );
    });

    testWidgets('a day already under way needs no note', (tester) async {
      await pump(
        tester,
        const DailyProgressStatus(
          streakDays: 12,
          goalDoneCards: 4,
          goalTargetCards: 20,
          studiedToday: true,
          hasStreakHistory: true,
        ),
      );

      expect(find.byType(MxNote), findsNothing);
    });

    // The streak outlives the goal, so the nudge must reach someone who never
    // set a target.
    testWidgets('the nudge does not need a configured goal', (tester) async {
      await pump(
        tester,
        const DailyProgressStatus(
          streakDays: 9,
          goalDoneCards: 0,
          goalTargetCards: 0,
          hasStreakHistory: true,
        ),
      );

      expect(find.byType(TodayGoalCard), findsNothing);
      expect(
        find.text('You haven’t studied today — study to keep your streak.'),
        findsOneWidget,
      );
    });
  });

  // Kit `dashboard/decks`. The rows are the shared DeckCard the Library
  // renders, so the two screens cannot say different things about a deck.
  group('recent decks', () {
    DeckSummary summary(
      String name, {
      int cards = 10,
      int due = 0,
      int mastered = 0,
      int studiable = 10,
    }) => DeckSummary(
      deck: Deck(
        id: name,
        languagePairId: 'lp1',
        parentId: null,
        name: name,
        normalizedName: name.toLowerCase(),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      cardCount: cards,
      dueCount: due,
      masteredCount: mastered,
      studiableCount: studiable,
    );

    Future<void> pump(WidgetTester tester, List<DeckSummary> decks) async {
      await tester.pumpWidget(
        wrap(
          data(
            TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
              recentDecks: decks,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists the decks with their counts and mastery', (
      tester,
    ) async {
      await pump(tester, <DeckSummary>[
        summary('Grammar', cards: 12, due: 4, mastered: 9, studiable: 12),
      ]);

      expect(find.text('Recent decks'), findsOneWidget);
      expect(find.byType(DeckSummaryRow), findsOneWidget);
      final bar = tester.widget<MxProgress>(find.byType(MxProgress));
      expect(bar.value, 0.75);
    });

    // "0" in a due-count badge reads as a count that failed to load, so the
    // kit marks a settled deck with a check instead.
    testWidgets('a deck with nothing due is checked, not zeroed', (
      tester,
    ) async {
      await pump(tester, <DeckSummary>[summary('Phrases')]);

      // Scoped to the badge: the strip below renders a bare "0" for a streak
      // that has not started, which is a different zero.
      expect(find.widgetWithText(MxBadge, '0'), findsNothing);
      final badge = tester.widget<MxBadge>(find.byType(MxBadge));
      expect(badge.icon, isNotNull);
    });

    testWidgets('a due deck shows its count', (tester) async {
      await pump(tester, <DeckSummary>[summary('Grammar', due: 4)]);

      expect(find.widgetWithText(MxBadge, '4'), findsOneWidget);
    });

    testWidgets('the list closes with a link to the Library', (tester) async {
      await pump(tester, <DeckSummary>[summary('Grammar')]);

      expect(find.widgetWithText(MxLink, 'See all decks'), findsOneWidget);
    });

    // A supporting section: it disappears rather than showing an empty box.
    testWidgets('no decks shows no section', (tester) async {
      await pump(tester, const <DeckSummary>[]);

      expect(find.text('Recent decks'), findsNothing);
      expect(find.byType(DeckSummaryRow), findsNothing);
    });
  });

  // Kit `dashboard/today`. Two of the kit's four stats have no source; the
  // strip carries the two that do rather than inventing the rest.
  group('stat strip', () {
    Future<void> pump(
      WidgetTester tester, {
      int streak = 0,
      LibraryMastery mastery = const LibraryMastery.empty(),
    }) async {
      await tester.pumpWidget(
        wrap(
          data(
            TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
              dailyProgress: DailyProgressStatus(
                streakDays: streak,
                goalDoneCards: 0,
                goalTargetCards: 0,
                studiedToday: true,
                hasStreakHistory: streak > 0,
              ),
              libraryMastery: mastery,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the streak and the mastered share', (tester) async {
      await pump(
        tester,
        streak: 12,
        mastery: const LibraryMastery(masteredCount: 11, studiableCount: 20),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('day streak'), findsOneWidget);
      expect(find.text('55%'), findsOneWidget);
      expect(find.text('library mastered'), findsOneWidget);
    });

    // An empty library divides by zero if the fraction is naive.
    testWidgets('an empty library reads 0%, not a crash', (tester) async {
      await pump(tester);

      expect(find.text('0%'), findsOneWidget);
    });

    // Nothing captures foreground-active intervals (`int-9`) and today's
    // qualified-card count is recorded only when a goal exists, so neither
    // number may appear — an invented one would look exactly like a real one.
    testWidgets('shows no stat it has no source for', (tester) async {
      await pump(
        tester,
        streak: 3,
        mastery: const LibraryMastery(masteredCount: 1, studiableCount: 4),
      );

      expect(find.text('studied'), findsNothing);
      expect(find.text('words learned'), findsNothing);
    });
  });

  // WBS 5.7.3 — the CTA runs the revalidation rather than navigating on a
  // count that may be minutes old (`start-review-from-today.md`).
  group('start review handoff', () {
    Override due() => data(
      const TodayProjection(
        primaryAction: TodayPrimaryAction.startReview,
        dueCount: 7,
      ),
    );

    testWidgets('the CTA dispatches the revalidating start', (tester) async {
      var started = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            due(),
            startReviewProvider.overrideWith(
              () => _RecordingStartReview((_) => started++),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MxButton, 'Start review'));
      await tester.pumpAndSettle();

      expect(started, 1);
    });

    // §4: "Starting khóa CTA/double tap".
    testWidgets('a start in flight disables the CTA', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            due(),
            startReviewProvider.overrideWith(_LoadingStartReview.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<MxButton>(
        find.widgetWithText(MxButton, 'Start review'),
      );
      expect(button.onPressed, isNull);
    });

    // §4: "Start failure giữ Dashboard snapshot" — the dashboard stays, and
    // says so, instead of navigating or blanking.
    testWidgets('a failed start keeps the dashboard and reports', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            due(),
            startReviewProvider.overrideWith(_FailedStartReview.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue studying'), findsOneWidget);
      expect(
        find.text(
          'Couldn’t start the review. Your progress is unchanged — try again.',
        ),
        findsOneWidget,
      );
      // Still offered: the retry is the same control.
      final button = tester.widget<MxButton>(
        find.widgetWithText(MxButton, 'Start review'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  // WBS 5.7.3 — Resume resolves the session again before navigating
  // (`continue-session-from-today.md`).
  group('continue session handoff', () {
    Override paused() => data(
      const TodayProjection(
        primaryAction: TodayPrimaryAction.continueSession,
        dueCount: 12,
      ),
    );

    Widget app(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TodayScreen(),
      ),
    );

    testWidgets('the CTA dispatches the revalidating resume', (tester) async {
      var resumed = 0;
      await tester.pumpWidget(
        app(<Override>[
          paused(),
          continueSessionProvider.overrideWith(
            () => _RecordingContinue(() => resumed++),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MxButton, 'Resume session'));
      await tester.pumpAndSettle();

      expect(resumed, 1);
    });

    // §4: "Handoff token chặn duplicate navigation".
    testWidgets('a resume in flight disables the CTA', (tester) async {
      await tester.pumpWidget(
        app(<Override>[
          paused(),
          continueSessionProvider.overrideWith(_LoadingContinue.new),
        ]),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<MxButton>(
        find.widgetWithText(MxButton, 'Resume session'),
      );
      expect(button.onPressed, isNull);
    });

    // §2 node E: refresh *and* explain. Refreshing alone would make the CTA
    // vanish with no account of why.
    testWidgets('a session that already ended says so', (tester) async {
      await tester.pumpWidget(
        app(<Override>[
          paused(),
          continueSessionProvider.overrideWith(_EndedContinue.new),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'That session already finished, so there is nothing to resume.',
        ),
        findsOneWidget,
      );
    });

    // §1: "Resume failure không xóa session hoặc Dashboard state".
    testWidgets('a failed resume keeps the dashboard and the session', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(<Override>[
          paused(),
          continueSessionProvider.overrideWith(_FailedContinue.new),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Study session paused'), findsOneWidget);
      expect(
        find.text(
          'Couldn’t resume the session. It is still saved — try again.',
        ),
        findsOneWidget,
      );
      final button = tester.widget<MxButton>(
        find.widgetWithText(MxButton, 'Resume session'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  // WBS 5.7.2 — `refresh-today-projections.md`. A failed *refresh* is not a
  // failed load: there is a good snapshot on screen and it must survive.
  group('refresh', () {
    testWidgets('a failed refresh keeps the dashboard and marks it stale', (
      tester,
    ) async {
      var shouldFail = false;
      final container = ProviderContainer(
        overrides: [
          todayProjectionProvider.overrideWith((ref) async {
            if (shouldFail) throw StateError('boom');
            return const TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7 cards due'), findsOneWidget);

      // The refresh a pull would dispatch, with the next load failing.
      shouldFail = true;
      await container
          .refresh(todayProjectionProvider.future)
          .then<void>((_) {}, onError: (Object _) {});
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Showing what was loaded earlier — the refresh didn’t go through.',
        ),
        findsOneWidget,
      );
      // §1: last-good survives. The count is still the one that loaded.
      expect(find.text('7 cards due'), findsOneWidget);
      // Not the full-screen load error, which would have thrown it away.
      expect(find.text('Today couldn’t load'), findsNothing);
    });

    // A first load that fails has no last-good to keep, so the error surface
    // is right — the stale path must not swallow it.
    testWidgets('a first load that fails still shows the error', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          todayProjectionProvider.overrideWith(
            (ref) => Future<TodayProjection>.error('boom'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today couldn’t load'), findsOneWidget);
      expect(
        find.text(
          'Showing what was loaded earlier — the refresh didn’t go through.',
        ),
        findsNothing,
      );
    });
  });

  // WBS 5.7.2 — `manage-today-create-actions.md`; kit `dashboard/add` and
  // `dashboard/create-sheet`.
  group('create sheet', () {
    testWidgets('the FAB opens the create actions', (tester) async {
      await tester.pumpWidget(
        wrap(
          data(
            const TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MxFab));
      await tester.pumpAndSettle();

      // The shared select sheet uppercases its title, as the kit does.
      expect(find.text('CREATE'), findsOneWidget);
      expect(find.text('Add card'), findsOneWidget);
      expect(find.text('Create deck'), findsOneWidget);
    });

    // The kit lists a third entry. Nothing in this build imports anything —
    // no route, no flow, no use case — and a row that opens nothing is worse
    // than a menu that is honest about what it can do.
    testWidgets('no import row, because nothing imports', (tester) async {
      await tester.pumpWidget(
        wrap(
          data(
            const TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MxFab));
      await tester.pumpAndSettle();

      expect(find.textContaining('Import'), findsNothing);
    });

    // §6: "Dismiss không có side effect."
    testWidgets('dismissing the sheet changes nothing', (tester) async {
      await tester.pumpWidget(
        wrap(
          data(
            const TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MxFab));
      await tester.pumpAndSettle();
      // Tap the scrim above the sheet.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('CREATE'), findsNothing);
      expect(find.text('7 cards due'), findsOneWidget);
    });
  });

  // WBS 5.7.2 — `handle-caught-up-today.md` §2 node G and
  // `handle-empty-library-today.md` §1.
  group('caught-up and empty actions', () {
    // Caught up on reviews is not the same as having nothing to learn.
    testWidgets('unstudied cards offer a new-learning session', (tester) async {
      var startedWith = <SessionType>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            data(
              const TodayProjection(
                primaryAction: TodayPrimaryAction.caughtUp,
                dueCount: 0,
                newCount: 40,
              ),
            ),
            startReviewProvider.overrideWith(
              () => _RecordingStartReview(startedWith.add),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MxButton, 'Learn 40 new cards'));
      await tester.pumpAndSettle();

      // Sec 6: the optional action revalidates like the due CTA does, over
      // the new queue rather than the due one.
      expect(startedWith, <SessionType>[SessionType.newLearning]);
    });

    // Sec 1 forbids manufacturing a CTA, and an action over an empty queue
    // would be exactly that.
    testWidgets('nothing to learn offers no learning action', (tester) async {
      await tester.pumpWidget(
        wrap(
          data(
            const TodayProjection(
              primaryAction: TodayPrimaryAction.caughtUp,
              dueCount: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('new cards'), findsNothing);
      expect(find.widgetWithText(MxButton, 'Explore decks'), findsOneWidget);
    });

    // The action said "Create a deck" and opened the Library — a list of the
    // decks the learner does not have.
    testWidgets('an empty library opens the create flow, not the Library', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          data(
            const TodayProjection(
              primaryAction: TodayPrimaryAction.createLibrary,
              dueCount: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MxButton, 'Create a deck'));
      await tester.pumpAndSettle();

      // The create-deck dialog, identified by the field it asks for.
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  // WBS 5.7.3 — `start-review-from-today.md` §2 node E. Several due decks
  // used to send the learner to the Library to find one themselves.
  group('scope picker', () {
    testWidgets('several due decks offer a choice with their counts', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            data(
              const TodayProjection(
                primaryAction: TodayPrimaryAction.startReview,
                dueCount: 10,
              ),
            ),
            startReviewProvider.overrideWith(_ChoosingStartReview.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MxButton, 'Start review'));
      await tester.pumpAndSettle();

      expect(find.text('WHICH DECK?'), findsOneWidget);
      expect(find.text('Grammar · 4 cards'), findsOneWidget);
      expect(find.text('Vocabulary · 6 cards'), findsOneWidget);
    });
  });

  // `refresh-today-projections.md` §3 names app foreground first among the
  // refresh triggers. Nothing wired it: a dashboard left open overnight kept
  // yesterday's due count, and every number here is derived from "now".
  testWidgets('coming back to the foreground re-reads the dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        snapshots(const <TodayProjection>[
          TodayProjection(
            primaryAction: TodayPrimaryAction.startReview,
            dueCount: 7,
          ),
          TodayProjection(
            primaryAction: TodayPrimaryAction.caughtUp,
            dueCount: 0,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 cards due'), findsOneWidget);

    // Away and back: the sequence a real backgrounding walks through.
    for (final state in const <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(find.text('7 cards due'), findsNothing);
    expect(find.text('You’re all caught up'), findsOneWidget);
  });

  // §3's "Deck/Card mutation" trigger, on the path this screen owns: search is
  // pushed over Today, so Today stays mounted underneath and kept its snapshot
  // across a visit that can rename or delete the very cards it counted.
  testWidgets('returning from search re-reads the dashboard', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.home,
      routes: [...todayBranchRoutes(), ...searchRoutes()],
    );
    await tester.pumpWidget(
      routed(
        router,
        snapshots(const <TodayProjection>[
          TodayProjection(
            primaryAction: TodayPrimaryAction.startReview,
            dueCount: 7,
          ),
          TodayProjection(
            primaryAction: TodayPrimaryAction.caughtUp,
            dueCount: 0,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 cards due'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('7 cards due'), findsNothing);
    expect(find.text('You’re all caught up'), findsOneWidget);
  });

  // `manage-today-create-actions.md` §4: "Double selection chỉ handoff một
  // flow". The sheet takes a frame to cover the FAB, and a second tap inside
  // that frame opened a second sheet over the first — dismissing one left the
  // other still standing.
  testWidgets('a double tap on the create FAB opens one sheet', (tester) async {
    await tester.pumpWidget(
      wrap(
        data(
          const TodayProjection(
            primaryAction: TodayPrimaryAction.startReview,
            dueCount: 7,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Driven through the callback rather than two hit-tested taps: after the
    // first tap the sheet's barrier owns the FAB's position, so a second
    // pointer never reaches it and the race this guards would not be
    // reproduced. Two synchronous invocations are exactly that race.
    final fab = tester.widget<MxFab>(find.byType(MxFab));
    fab.onPressed!();
    fab.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('CREATE'), findsOneWidget);
  });

  // `handle-caught-up-today.md` §4: "Browse return giữ Today context và
  // refresh". Library is a sibling tab, not a route over Today, so the shell
  // keeps this branch mounted — a learner who browsed away, added something
  // and came back read the numbers from before they left.
  testWidgets('coming back to the Today tab re-reads the dashboard', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RoutePaths.home,
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => shell,
          branches: <StatefulShellBranch>[
            StatefulShellBranch(routes: todayBranchRoutes()),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: RoutePaths.library,
                  builder: (context, state) =>
                      const Scaffold(body: Text('Library stands in here')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      routed(
        router,
        snapshots(const <TodayProjection>[
          TodayProjection(
            primaryAction: TodayPrimaryAction.startReview,
            dueCount: 7,
          ),
          TodayProjection(
            primaryAction: TodayPrimaryAction.caughtUp,
            dueCount: 0,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 cards due'), findsOneWidget);

    router.go(RoutePaths.library);
    await tester.pumpAndSettle();
    expect(find.text('Library stands in here'), findsOneWidget);

    router.go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.text('7 cards due'), findsNothing);
    expect(find.text('You’re all caught up'), findsOneWidget);
  });

  // `refresh-today-projections.md` §3's day-boundary trigger, and §4: "Day
  // boundary có thể đổi primary state và summaries cùng snapshot."
  //
  // Foreground covers every way back into the app; this covers the one way it
  // does not — a dashboard left open across midnight. No other trigger
  // fires there, and every number on the screen is derived from the day that just
  // ended.
  testWidgets('midnight re-reads a dashboard left open across it', (
    tester,
  ) async {
    // Half a minute before midnight, in a zone where local is UTC so the
    // arithmetic under test is the screen's and not the host's.
    final clock = FakeClock(DateTime.utc(2026, 7, 27, 23, 59, 30));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(clock),
          appTimeZoneProvider.overrideWithValue(
            const FixedOffsetTimeZone(id: 'test', offset: Duration.zero),
          ),
          snapshots(const <TodayProjection>[
            TodayProjection(
              primaryAction: TodayPrimaryAction.startReview,
              dueCount: 7,
            ),
            TodayProjection(
              primaryAction: TodayPrimaryAction.caughtUp,
              dueCount: 0,
            ),
          ]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TodayScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 cards due'), findsOneWidget);

    // Nobody touches the app; the day simply ends.
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();

    expect(find.text('7 cards due'), findsNothing);
    expect(find.text('You’re all caught up'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _RecordingStartReview extends StartReview {
  _RecordingStartReview(this._onStart);

  final void Function(SessionType type) _onStart;

  @override
  Future<void> start({
    SessionType type = SessionType.dueReview,
    String? deckId,
  }) async => _onStart(type);
}

class _LoadingStartReview extends StartReview {
  @override
  AsyncValue<StartReviewOutcome?> build() =>
      const AsyncLoading<StartReviewOutcome?>();
}

class _FailedStartReview extends StartReview {
  @override
  AsyncValue<StartReviewOutcome?> build() => AsyncError<StartReviewOutcome?>(
    const UnexpectedFailure(cause: 'boom'),
    StackTrace.empty,
  );
}

class _RecordingContinue extends ContinueSession {
  _RecordingContinue(this._onResume);

  final void Function() _onResume;

  @override
  Future<void> resume() async => _onResume();
}

class _LoadingContinue extends ContinueSession {
  @override
  AsyncValue<ContinueSessionOutcome?> build() =>
      const AsyncLoading<ContinueSessionOutcome?>();
}

class _EndedContinue extends ContinueSession {
  @override
  AsyncValue<ContinueSessionOutcome?> build() =>
      const AsyncData<ContinueSessionOutcome?>(SessionNoLongerResumable());
}

class _FailedContinue extends ContinueSession {
  @override
  AsyncValue<ContinueSessionOutcome?> build() =>
      AsyncError<ContinueSessionOutcome?>(
        const UnexpectedFailure(cause: 'boom'),
        StackTrace.empty,
      );
}

/// Resolves straight to the multi-deck branch, so the picker is what the tap
/// produces.
class _ChoosingStartReview extends StartReview {
  @override
  Future<void> start({
    SessionType type = SessionType.dueReview,
    String? deckId,
  }) async {
    state = const AsyncLoading<StartReviewOutcome?>();
    state = const AsyncData<StartReviewOutcome?>(
      ChooseReviewScope(
        options: <ReviewScopeOption>[
          ReviewScopeOption(
            deckId: 'd1',
            deckName: 'Grammar',
            eligibleCount: 4,
          ),
          ReviewScopeOption(
            deckId: 'd2',
            deckName: 'Vocabulary',
            eligibleCount: 6,
          ),
        ],
      ),
    );
  }
}

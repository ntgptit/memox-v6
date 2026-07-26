import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
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
}

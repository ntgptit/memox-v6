import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_select_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_header.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_loading_skeleton.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_greeting_header.dart';
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_goal_card.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_state_note.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_recent_decks.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_stat_strip.dart';
import 'package:memox_v6/presentation/features/today/widgets/today_create_fab.dart';
import 'package:memox_v6/presentation/features/deck/widgets/create_deck_dialog.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/start_review_notifier.dart';
import 'package:memox_v6/domain/today/start_review_outcome.dart';
import 'package:memox_v6/domain/today/continue_session_outcome.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/continue_session_notifier.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';

/// The Today entry (WBS 5.7.2; `load-today-dashboard.md`, kit `dashboard`). A
/// branch of `AppTabShell` (the bottom nav lives there), it renders the composed
/// [TodayProjection] into exactly one primary action: resume a paused session,
/// start a review, create a first deck, or an all-caught-up message — plus the
/// loading and load-error states.
///
/// Every section of the kit composition is now in place: greeting, state
/// note, Continue-studying, Daily-goal card, stat strip and Recent decks. The
/// strip carries two of the kit's four stats — see `TodayStatStrip` for why
/// the other two have no source to read.
///
/// Start review still opens the Library, because no session-start UI command
/// exists app-wide and `StartStudySessionUseCase` is deck-scoped (recorded
/// gaps).
///
/// Template-only shell: the consumer child does the watch.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The state bodies own their scrolling (lists) or fill the frame (empty
    // states), so the scaffold provides no outer scroll view.
    return MxScaffold(
      scrollable: false,
      appBar: MxContextualAppBar(
        title: l10n.todayTitle,
        // Kit `dashboard/search-open`. The bar's root variant is "title +
        // trailing actions", and search is the one this build can wire: the
        // notification bell needs a notifications feature and the avatar an
        // account (WBS 14.x). Library already offers the same action, so this
        // is the second door to one screen rather than a new capability.
        actions: <Widget>[
          MxIconButton.toolbar(
            icon: Symbols.search_rounded,
            semanticLabel: l10n.searchLabel,
            onPressed: () => context.pushSearch(),
          ),
        ],
      ),
      // Kit `dashboard/add`: the create action is the FAB, never a nav tab —
      // the bottom bar holds destinations only.
      fab: const TodayCreateFab(),
      body: const _TodayBody(),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The greeting needs no data, so it sits outside the async builder and
    // renders in every state including loading and error — which is what the
    // kit does: it splits the greeting out of the app bar so it scrolls with
    // the content, and draws it above the skeleton too.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TodayGreetingHeader(
          // The app's zone, not the host's: `DateTime.toLocal()` reads the
          // device offset, which can differ from the zone every streak day
          // and goal bucket was written in — the greeting would then say
          // evening on a day the records call yesterday.
          now: ref
              .watch(appTimeZoneProvider)
              .localTimeOf(ref.watch(appClockProvider).nowUtc()),
        ),
        // Kit `.app__body` gap: `space-6`. It was `space-5` (20) here, four
        // logical short of every other section break in the app.
        const MxGap.s6(),
        // §3's manual trigger. The other triggers it lists — foreground, day
        // boundary, deck/card mutation — are not wired yet; this is the one
        // the learner can reach.
        //
        // No request token of its own (§1): the provider element keeps only
        // its latest future, so a response from a superseded refresh is
        // dropped before it can reach the screen. Adding a second token would
        // be a parallel mechanism for a guarantee Riverpod already gives.
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(todayProjectionProvider.future),
            child: _TodayStates(l10n: l10n),
          ),
        ),
      ],
    );
  }
}

class _TodayStates extends ConsumerWidget {
  const _TodayStates({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MxAsyncBuilder<TodayProjection>(
      value: ref.watch(todayProjectionProvider),
      loading: (context) => const TodayLoadingSkeleton(),
      errorTitle: l10n.todayErrorTitle,
      retryLabel: l10n.studyRetryLabel,
      onRetry: () => ref.invalidate(todayProjectionProvider),
      // §1: a refresh that fails keeps the last good dashboard and says it is
      // old, rather than replacing a screenful of real data with a banner.
      staleLabel: l10n.todayStaleBody,
      data: (context, projection) => _TodayContent(projection: projection),
    );
  }
}

/// The dashboard body: one scrolling column of sections in the kit's order —
/// note, the primary section, the Daily-goal card, the stat strip, the decks.
///
/// The goal card sat *above* the primary section when it landed, which put a
/// supporting metric ahead of the screen's one objective; the kit renders
/// `<GoalCard>` after the Continue-studying block, and the spec's §3 order is
/// explicit that due/resume content precedes goal/streak content.
class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.projection});

  final TodayProjection projection;

  @override
  Widget build(BuildContext context) {
    // First-run is a different tree in the kit, not a section of this one: the
    // onboarding hero replaces the body, with no note and no goal card above
    // a library that has nothing in it yet.
    if (projection.primaryAction == TodayPrimaryAction.createLibrary) {
      return const _EmptyState();
    }

    final progress = projection.dailyProgress;
    final note = todayNoteFor(progress);

    return ListView(
      children: <Widget>[
        if (note != null) ...<Widget>[
          TodayStateNote(kind: note),
          const MxGap.s6(),
        ],
        _TodayPrimary(projection: projection),
        // The card is the goal's own display, so it is absent when no goal is
        // configured rather than showing a target of zero — `hasGoal` is the
        // card's not-shown condition, not a missing value.
        if (progress.hasGoal) ...<Widget>[
          const MxGap.s6(),
          TodayGoalCard(status: progress),
        ],
        // Kit order: the strip sits between the goal card and the deck rows.
        const MxGap.s6(),
        TodayStatStrip(
          streakDays: progress.streakDays,
          mastery: projection.libraryMastery,
        ),
        // A supporting section (§3): empty when the pair has no decks, which
        // does not change what Today asks for.
        if (projection.recentDecks.isNotEmpty) ...<Widget>[
          const MxGap.s6(),
          TodayRecentDecks(
            decks: projection.recentDecks,
            onOpenDeck: (summary) => context.goDeckDetail(summary.deck.id),
            onSeeAll: () => context.goLibrary(),
          ),
        ],
      ],
    );
  }
}

class _TodayPrimary extends StatelessWidget {
  const _TodayPrimary({required this.projection});

  final TodayProjection projection;

  @override
  Widget build(BuildContext context) {
    return switch (projection.primaryAction) {
      TodayPrimaryAction.continueSession => _PausedState(),
      TodayPrimaryAction.startReview => _DueState(
        dueCount: projection.dueCount,
      ),
      // Handled by _TodayContent, which swaps the whole body for the hero.
      TodayPrimaryAction.createLibrary => _EmptyState(),
      TodayPrimaryAction.caughtUp => _CaughtUpState(
        newCount: projection.newCount,
      ),
    };
  }
}

/// The paused-session primary section, and the handoff back into it
/// (WBS 5.7.3; `continue-session-from-today.md`).
///
/// The button navigated straight to `/study` on a projection composed when
/// Today loaded. Between then and the tap the session can be finalized on the
/// study screen, abandoned, or completed after a restart — and the route
/// would have opened with nothing to resume.

/// Offers the decks a review could run over, then starts in the chosen one
/// (`start-review-from-today.md` §2, node E).
///
/// The counts come from the outcome rather than a fresh query: the learner
/// must choose between the numbers the revalidation just read, not a second
/// answer from a moment later. The start still revalidates that the chosen
/// deck is eligible — a queue can empty while a sheet is open.
Future<void> _chooseScope(
  BuildContext context,
  WidgetRef ref,
  List<ReviewScopeOption> options,
) async {
  final l10n = AppLocalizations.of(context);
  final deckId = await showMxSelectSheet<String>(
    context,
    title: l10n.todayChooseScopeTitle,
    options: <MxSelectOption<String>>[
      for (final option in options)
        MxSelectOption<String>(
          key: option.deckId,
          icon: Symbols.style_rounded,
          label: l10n.todayChooseScopeOption(
            option.deckName,
            option.eligibleCount,
          ),
        ),
    ],
  );
  if (deckId == null) return;
  await ref.read(startReviewProvider.notifier).start(deckId: deckId);
}

class _PausedState extends ConsumerWidget {
  const _PausedState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final resume = ref.watch(continueSessionProvider);

    ref.listen<AsyncValue<ContinueSessionOutcome?>>(continueSessionProvider, (
      previous,
      next,
    ) {
      if (previous is! AsyncLoading<ContinueSessionOutcome?>) return;
      switch (next) {
        case AsyncData<ContinueSessionOutcome?>(value: final outcome):
          switch (outcome) {
            case ResumeAtCheckpoint():
              context.goStudy();
            case SessionNoLongerResumable():
              // §2 node E and §4: recomposing is what makes the CTA
              // disappear; the notice below is the "explain" half, and it
              // survives the refresh because it lives in the command's state.
              ref.invalidate(todayProjectionProvider);
            case null:
              break;
          }
        case AsyncError<ContinueSessionOutcome?>():
        // §1: the session and the dashboard are both left alone.
        case AsyncLoading<ContinueSessionOutcome?>():
          break;
      }
    });

    final gone =
        resume is AsyncData<ContinueSessionOutcome?> &&
        resume.value is SessionNoLongerResumable;

    // A section of the body's column, not its own scroll view: the sections
    // scroll together, which is what puts the goal card below this one instead
    // of pinned to the bottom of the frame.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (gone) ...<Widget>[
          MxBanner(tone: MxBannerTone.info, body: l10n.todaySessionEndedBody),
          const MxGap.s4(),
        ],
        MxCard(
          variant: MxCardVariant.primarySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MxText(l10n.todayPausedTitle, role: MxTextRole.title),
              const MxGap.s2(),
              MxText(l10n.todayPausedBody, role: MxTextRole.body),
            ],
          ),
        ),
        const MxGap.s4(),
        MxButton(
          icon: Symbols.play_arrow_rounded,
          label: l10n.todayResumeLabel,
          block: true,
          onPressed: resume is AsyncLoading<ContinueSessionOutcome?>
              ? null
              : () => ref.read(continueSessionProvider.notifier).resume(),
        ),
        if (resume is AsyncError<ContinueSessionOutcome?>) ...<Widget>[
          const MxGap.s3(),
          MxBanner(tone: MxBannerTone.error, body: l10n.todayResumeFailedBody),
        ],
      ],
    );
  }
}

/// The due-cards primary section, and the handoff into the session
/// (WBS 5.7.3; `start-review-from-today.md`).
///
/// The button used to open the Library, which was the only thing it could do
/// while nothing revalidated the count. It now runs the revalidation the flow
/// specifies and acts on what comes back.
class _DueState extends ConsumerWidget {
  const _DueState({required this.dueCount});

  final int dueCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final start = ref.watch(startReviewProvider);

    // §2's four branches. Nothing here decides anything — the outcome was
    // resolved against freshly read state, and this only routes it.
    ref.listen<AsyncValue<StartReviewOutcome?>>(startReviewProvider, (
      previous,
      next,
    ) {
      if (previous is! AsyncLoading<StartReviewOutcome?>) return;
      switch (next) {
        case AsyncData<StartReviewOutcome?>(value: final outcome):
          switch (outcome) {
            case ResumeActiveSession():
            case ReviewStarted():
              context.goStudy();
            case NothingDueNow():
              // §4: "No longer due chuyển caught-up, không báo lỗi" —
              // recomposing the projection *is* the move to caught-up.
              ref.invalidate(todayProjectionProvider);
            case ChooseReviewScope(:final options):
              // §2 node E: resolve the scope, then hand off. This opened the
              // Library, which is neither — it left the learner to find a
              // deck themselves and lost the counts the revalidation had
              // just read.
              _chooseScope(context, ref, options);
            case null:
              break;
          }
        case AsyncError<StartReviewOutcome?>():
        // §4: the dashboard is kept as it was; the error is reported in
        // place and the button stays available to retry.
        case AsyncLoading<StartReviewOutcome?>():
          break;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxSectionHeader(
          title: l10n.todayDueTitle,
          caption: l10n.todayDueCaption(dueCount),
        ),
        const MxGap.s3(),
        MxButton(
          icon: Symbols.bolt_rounded,
          label: l10n.todayStartReviewLabel,
          block: true,
          // §4: "Starting khóa CTA/double tap". The command guards
          // re-entrancy too; a disabled control says so instead of
          // swallowing the tap.
          onPressed: start is AsyncLoading<StartReviewOutcome?>
              ? null
              : () => ref.read(startReviewProvider.notifier).start(),
        ),
        if (start is AsyncError<StartReviewOutcome?>) ...<Widget>[
          const MxGap.s3(),
          MxBanner(
            tone: MxBannerTone.error,
            body: l10n.todayStartReviewFailedBody,
          ),
        ],
      ],
    );
  }
}

/// The empty-library state (`handle-empty-library-today.md`).
///
/// The action said `Create a deck` and opened the Library, which is neither
/// the create flow nor anything the label promised — the learner arrived at a
/// list of the decks they do not have. §1 is explicit that Create and Import
/// only hand off to their owning flows.
///
/// The kit pairs the primary with `Import from a file`. That alternate is not
/// offered: nothing in this build imports anything, and §3 asks for exactly
/// one primary CTA — an alternate that opens nothing is not one.
class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MxEmptyState(
      icon: Icons.school_outlined,
      title: l10n.todayEmptyTitle,
      body: l10n.todayEmptyBody,
      action: MxButton(
        icon: Symbols.add_rounded,
        label: l10n.todayCreateLabel,
        onPressed: () async {
          await showCreateDeckDialog(context);
          // §2: Empty is left only after the source commits and Today
          // recomposes; a cancel lands back here unchanged (§4).
          ref.invalidate(todayProjectionProvider);
        },
      ),
    );
  }
}

/// Nothing due (kit `dashboard/continue`, caught-up branch).
///
/// A section at the top of the body, not a centred empty state: the kit keeps
/// the rest of the dashboard — goal, streak, decks — visible on a caught-up
/// day, and only the Review CTA is replaced.
///
/// It replaces the CTA rather than removing it. This screen offered no control
/// at all when nothing was due, so a learner who had finished their reviews
/// was shown a congratulation and no way onward.
class _CaughtUpState extends ConsumerWidget {
  const _CaughtUpState({required this.newCount});

  /// Cards never studied in the active pair. `handle-caught-up-today.md` §2
  /// node G: caught up on reviews is not the same as having nothing to learn,
  /// and until this was composed Today could not tell the difference.
  final int newCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final start = ref.watch(startReviewProvider);
    final starting = start is AsyncLoading<StartReviewOutcome?>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxText(l10n.todayCaughtUpTitle, role: MxTextRole.bodyStrong),
        const MxGap.s1(),
        MxText(
          l10n.todayCaughtUpBody,
          role: MxTextRole.caption,
          color: context.colors.textSecondary,
        ),
        const MxGap.s3(),
        // §2 node G, the optional action. Offered only when there is
        // something to learn — §1 forbids manufacturing a CTA ("Khong tao due
        // Card gia de cung cap CTA"), and an action over an empty queue would
        // be exactly that with extra steps.
        if (newCount > 0) ...<Widget>[
          MxButton(
            icon: Symbols.school_rounded,
            label: l10n.todayStudyNewLabel(newCount),
            block: true,
            // Sec 6: the optional action must not bypass study eligibility —
            // the same revalidation the due CTA runs, over the new queue.
            onPressed: starting
                ? null
                : () => ref
                      .read(startReviewProvider.notifier)
                      .start(type: SessionType.newLearning),
          ),
          const MxGap.s3(),
        ],
        MxButton(
          variant: MxButtonVariant.secondary,
          icon: Symbols.explore_rounded,
          label: l10n.todayExploreDecksLabel,
          block: true,
          onPressed: () => context.goLibrary(),
        ),
      ],
    );
  }
}

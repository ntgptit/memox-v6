import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_result_notifier.dart';
import 'package:memox_v6/presentation/features/today/viewmodels/today_projection_provider.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_badge.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_skeleton.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Study Result (WBS 5.6.13; `finalize-study-session.md`, kit `study-result`).
/// A terminal summary page — no back; exit only via the explicit actions. The
/// consumer child renders the committed [StudySessionSummary] from
/// [studyResultProvider], whose AsyncValue drives the kit states: finalizing
/// (loading), finalize-error with Retry (error), and the standard result (data).
/// The result renders the kit's time stat, `Review mistakes` link (missed cards)
/// and streak/goal card from [StudySessionSummary]; the summary's active-time
/// aggregation and goal/streak contribution are supplied by finalize (0/null
/// until those evidence paths compute, seeded canonically for parity).
///
/// Template-only shell: the consumer child does the watch.
class StudyResultScreen extends StatelessWidget {
  const StudyResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The finalizing/error states fill the frame, so the scaffold owns no scroll
    // view; the result body scrolls itself when the content is tall.
    return MxScaffold(
      scrollable: false,
      appBar: MxContextualAppBar(title: l10n.studyResultTitle),
      body: const _StudyResultBody(),
    );
  }
}

class _StudyResultBody extends ConsumerWidget {
  const _StudyResultBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MxAsyncBuilder<StudySessionSummary?>(
      value: ref.watch(studyResultProvider),
      loadingLabel: l10n.studyFinalizingLabel,
      loading: (context) => _Finalizing(
        retrying: ref.read(studyResultProvider.notifier).isRetrying,
      ),
      // §6's own composition. The shared compact banner carried the title and
      // a small Retry, and this screen is terminal by design — "no back; exit
      // only via the explicit actions" — so a finalize that kept failing left
      // the learner with one button and no way off the screen at all. The
      // body explaining what happened was written and never rendered.
      error: (context, failure) => _FinalizeFailed(
        onRetry: () => ref.read(studyResultProvider.notifier).retry(),
      ),
      errorTitle: l10n.studyFinalizeErrorTitle,
      data: (context, summary) => summary == null
          ? _Finalizing(
              retrying: ref.read(studyResultProvider.notifier).isRetrying,
            )
          : SingleChildScrollView(child: _ResultBody(summary: summary)),
    );
  }
}

/// The finalizing view (kit `study-result--finalizing`, and its
/// `retry-finalize` reframing).
///
/// §6 asks this state for a "stable progress/status", and the kit spends the
/// whole screen on it: the hero, then the shapes of the stats and the streak
/// card that are about to arrive. This was one centred sentence, so the screen
/// went from a line of text to a full page the moment the commit landed — and
/// a learner who had just watched a save fail was shown the same first-attempt
/// copy when they pressed Retry, with nothing saying the app had heard them.
///
/// No CTA, by §4: "không có CTA khi đang xử lý".
class _Finalizing extends StatelessWidget {
  const _Finalizing({required this.retrying});

  /// Renders §9's `retry` state rather than the first attempt.
  final bool retrying;

  /// Kit `<S w={44} h={22} />` over `<S w="64%" h={10} />` in each stat card,
  /// and `<S h={120} r={20} />` for the streak card.
  static const double _statValueWidth = 44;
  static const double _statValueHeight = 22;
  static const double _statLabelHeight = 10;
  static const double _statLabelFactor = 0.64;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const MxGap.s4(),
            Center(
              child: MxIconTile(
                icon: retrying
                    ? Symbols.refresh_rounded
                    : Symbols.cloud_sync_rounded,
                tone: MxIconTileTone.accent,
                large: true,
              ),
            ),
            const MxGap.s3(),
            MxText(
              retrying
                  ? l10n.studyFinalizeRetryingLabel
                  : l10n.studyFinalizingLabel,
              role: MxTextRole.subtitle,
              textAlign: TextAlign.center,
            ),
            const MxGap.s1(),
            MxText(
              retrying
                  ? l10n.studyFinalizeRetryingBody
                  : l10n.studyFinalizingBody,
              role: MxTextRole.body,
              color: context.colors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const MxGap.s4(),
            Row(
              children: <Widget>[
                for (var stat = 0; stat < 3; stat++) ...<Widget>[
                  if (stat > 0) const MxGap.s3(),
                  const Expanded(child: _StatSkeleton()),
                ],
              ],
            ),
            const MxGap.s4(),
            const MxSkeleton(
              height: AppSizes.size2xl,
              borderRadius: AppBorderRadii.card,
            ),
          ],
        ),
      ),
    );
  }
}

/// One stat card's placeholder: the number's box over its label's line.
class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return MxCard(
      variant: MxCardVariant.muted,
      padding: MxCardPadding.sm,
      child: Column(
        children: <Widget>[
          const MxSkeleton(
            width: _Finalizing._statValueWidth,
            height: _Finalizing._statValueHeight,
          ),
          const MxGap.s2(),
          FractionallySizedBox(
            widthFactor: _Finalizing._statLabelFactor,
            child: const MxSkeleton(height: _Finalizing._statLabelHeight),
          ),
        ],
      ),
    );
  }
}

/// Formats active study time as `m:ss` for the kit time stat.
String _formatActiveTime(int milliseconds) {
  final totalSeconds = milliseconds ~/ Duration.millisecondsPerSecond;
  final minutes = totalSeconds ~/ Duration.secondsPerMinute;
  final seconds = totalSeconds % Duration.secondsPerMinute;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({required this.summary});

  final StudySessionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accuracy = summary.reviewedCount == 0
        ? 0
        : (summary.correctCount * 100 / summary.reviewedCount).round();
    final goalStatus = summary.goalStatus;
    // `complete-daily-goal.md` §1: completion is reaching *or passing* the
    // effective target, and "Goal vượt target vẫn giữ completed state". A null
    // status is a session with no goal configured, which §1 says never
    // completes anything ("Disabled Goal không phát completion").
    final goalMet =
        goalStatus != null &&
        goalStatus.goalTargetCards > 0 &&
        goalStatus.goalDoneCards >= goalStatus.goalTargetCards;

    // Kit `StudyResult.jsx`: an outer column with a uniform space-4 gap between
    // the hero, stats, review link, streak card and CTA. Gaps are interleaved
    // explicitly here so the vertical rhythm matches the reference pixel-for-pixel.
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ResultHero: centered icon tile + title + subtitle, paddingTop s4,
          // internal gap s3, subtitle nudged s1 below the title.
          const MxGap.s4(),
          Center(
            child: MxIconTile(
              // §3 node F, the goal-met result state — the kit's
              // `study-result--goal-met` hero: the celebration glyph on the
              // success tone in place of the standard accent tile. The screen
              // had one hero for every outcome, so the surface where the goal
              // is actually completed was the one surface that never said so.
              icon: goalMet
                  ? Symbols.celebration_rounded
                  // The kit names the task-alt glyph here, but it does not render
                  // in the bundled Material Symbols Outlined or Rounded fonts.
                  // Both paint an ellipse with an identical 112x85 ink box at 4x,
                  // which is what a missing glyph falling back to a shared
                  // substitute looks like; the sharp family paints it square.
                  // Against the kit shot the hero came out 28x21 logical where
                  // the kit draws 27x27. The check-in-a-circle glyph used here
                  // carries the same meaning, stays in the Rounded family the
                  // icon contract requires, and renders undistorted. Pinned by
                  // mx_icon_aspect_test.dart, which fails once the named glyph
                  // renders square again.
                  : Symbols.check_circle_rounded,
              tone: goalMet ? MxIconTileTone.success : MxIconTileTone.accent,
              large: true,
            ),
          ),
          const MxGap.s3(),
          MxText(
            goalMet
                ? l10n.studyResultGoalMetTitle
                : l10n.studyResultCompleteTitle,
            role: MxTextRole.subtitle,
            textAlign: TextAlign.center,
          ),
          const MxGap.s1(),
          MxText(
            // The kit's subtitle here asserts "Streak +1", which this build
            // cannot verify — nothing says whether this session is what
            // extended the streak. §4's composition names the line that is
            // both true and the one the spec asks for: current of target.
            goalMet
                ? l10n.studyResultGoalMetBody(
                    goalStatus.goalDoneCards,
                    goalStatus.goalTargetCards,
                  )
                : l10n.studyResultReviewedText(summary.reviewedCount),
            role: MxTextRole.body,
            color: context.colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const MxGap.s4(),
          Row(
            children: <Widget>[
              Expanded(
                child: _Stat(
                  value: '${summary.reviewedCount}',
                  label: l10n.studyResultCardsLabel,
                ),
              ),
              const MxGap.s3(),
              Expanded(
                child: _Stat(
                  value: '$accuracy%',
                  label: l10n.studyResultCorrectLabel,
                ),
              ),
              const MxGap.s3(),
              Expanded(
                child: _Stat(
                  value: _formatActiveTime(summary.durationActiveMs),
                  label: l10n.studyResultTimeLabel,
                ),
              ),
            ],
          ),
          if (summary.missedCount > 0) ...<Widget>[
            // Kit pulls the link up by space-2 from the space-4 outer gap (net s2).
            const MxGap.s2(),
            Center(
              child: MxLink(
                icon: Symbols.replay_rounded,
                label: l10n.studyResultReviewMistakesLabel,
                // Starts a relearn session over the missed cards, then opens
                // it. This called `goStudy()` alone, which re-entered the
                // route the result was already on — the control rendered,
                // took a tap, and did nothing.
                onTap: () async {
                  final outcome = await ref
                      .read(studyResultProvider.notifier)
                      .startRelearn();
                  if (outcome == null || !context.mounted) return;
                  // `relearn-cards.md` §6. A start that cannot save the queue
                  // used to leave the learner tapping a link that did
                  // nothing; the answers it would relearn are already
                  // committed, which is the part worth saying.
                  if (outcome is AsyncError) {
                    showMxSnackbar(
                      context,
                      message: l10n.relearnQueueFailedMessage,
                      tone: MxSnackbarTone.error,
                    );
                    return;
                  }
                  context.goStudy();
                },
              ),
            ),
          ],
          if (goalStatus != null) ...<Widget>[
            const MxGap.s4(),
            _StreakCard(status: goalStatus, met: goalMet),
          ],
          const MxGap.s4(),
          MxButton(
            icon: Symbols.bolt_rounded,
            label: l10n.studyResultContinueLabel,
            block: true,
            // `refresh-today-projections.md` §3 lists "Study exit/finalize"
            // among the refresh triggers, and only the manual pull was wired.
            // The session just changed the due count, the goal bucket and the
            // streak; without this the dashboard behind still advertises the
            // review that was only now finished.
            onPressed: () {
              ref.invalidate(todayProjectionProvider);
              context.goHome();
            },
          ),
          const MxGap.s2(),
          MxButton(
            variant: MxButtonVariant.ghost,
            label: l10n.studyResultDoneLabel,
            block: true,
            onPressed: () {
              // Today is one tab away from the Library, and its projection is
              // just as stale either way out.
              ref.invalidate(todayProjectionProvider);
              context.goLibrary();
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return MxCard(
      variant: MxCardVariant.muted,
      padding: MxCardPadding.sm,
      child: Column(
        children: <Widget>[
          MxText(value, role: MxTextRole.title),
          const MxGap.s1(),
          MxText(label, role: MxTextRole.caption),
        ],
      ),
    );
  }
}

/// The streak + today's-goal card (kit `study-result` `StreakGoalCard.jsx`,
/// "goal status when applicable" — `finalize-study-session.md` §4). A
/// primary-soft card with an internal space-3 rhythm: the flame + streak row,
/// then the goal label row (space-2 above the bar) and the progress bar.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.status, required this.met});

  final StudyResultGoalStatus status;

  /// Adds the kit's achievement badge (`study-result/goal-badge`).
  final bool met;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final target = status.goalTargetCards;
    final progress = target == 0
        ? 0.0
        : (status.goalDoneCards / target).clamp(0.0, 1.0);
    final progressLabel = l10n.studyResultGoalProgressLabel(
      status.goalDoneCards,
      target,
    );

    return MxCard(
      variant: MxCardVariant.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (met) ...<Widget>[
            // Kit: the card stays the neutral primary-soft streak card and the
            // badge is the only success accent on it. The glyph is not
            // decoration — §4 forbids resting the success meaning on colour.
            // A Row rather than an Align: `MxBadge` centres inside its own
            // box, so under the loose constraints an `Align` hands down it
            // stretches to the full card width. A min-size Row gives its child
            // an unbounded main axis, which is what makes the pill wrap its
            // label — the kit draws it shrink-wrapped at the start.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MxBadge(
                  label: l10n.studyResultGoalMetBadge,
                  tone: MxBadgeTone.success,
                  soft: true,
                  leadingIcon: Symbols.celebration_rounded,
                ),
              ],
            ),
            const MxGap.s3(),
          ],
          Row(
            children: <Widget>[
              MxIcon(
                icon: Symbols.local_fire_department_rounded,
                color: context.colors.accent,
              ),
              const MxGap.s4(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MxText(
                      l10n.studyResultStreakDaysLabel(status.streakDays),
                      role: MxTextRole.bodyLarge,
                    ),
                    MxText(
                      l10n.studyResultStreakCaptionLabel,
                      role: MxTextRole.caption,
                      color: context.colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const MxGap.s3(),
          Row(
            children: <Widget>[
              Expanded(
                child: MxText(
                  l10n.studyResultGoalTitleLabel,
                  role: MxTextRole.caption,
                  color: context.colors.textSecondary,
                ),
              ),
              MxText(
                progressLabel,
                role: MxTextRole.caption,
                color: context.colors.textSecondary,
              ),
            ],
          ),
          const MxGap.s2(),
          // The kit draws this goal bar as the taller `ProgressBar height={8}` on
          // a `border` track, not the 4px `.progress` default: measured against
          // the shot it is ~7 logical px tall with a (74, 72, 93) track where
          // the default renders 4px on (28, 26, 43).
          MxProgress(
            value: progress.toDouble(),
            semanticLabel: progressLabel,
            prominent: true,
          ),
        ],
      ),
    );
  }
}

/// The finalize-error state (`finalize-study-session.md` §6).
///
/// Leaving is safe here, which is why it is offered: the session stays
/// active, Today offers it back as one to continue, and opening it finalizes
/// again — §6's "Retry: same finalize request identity" is what makes the
/// deferred attempt count once rather than twice. Nothing is lost by walking
/// away; only the schedule update waits.
class _FinalizeFailed extends StatelessWidget {
  const _FinalizeFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Composition from `StudyResult.jsx`'s `finalize-error` branch: an error
    // -toned `cloud_off` EmptyState over two stacked block buttons, `Retry`
    // primary with the refresh glyph and `Not now` ghost. The labels are the
    // kit's rather than §6's `Try again`, because the title and body already
    // came from the kit and a state should not speak in two voices.
    return MxEmptyState(
      icon: Symbols.cloud_off_rounded,
      tone: MxIconTileTone.error,
      title: l10n.studyFinalizeErrorTitle,
      body: l10n.studyFinalizeErrorMessage,
      // The kit's action column is `var(--memox-size-3xl)`, which is what
      // `standard` is; `wide` overshot it and painted past the kit's buttons
      // on both sides. Measured, not guessed.
      actionWidth: MxEmptyStateActionWidth.standard,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MxButton(
            icon: Symbols.refresh_rounded,
            label: l10n.studyRetryLabel,
            block: true,
            onPressed: onRetry,
          ),
          const MxGap.s3(),
          MxButton(
            label: l10n.studyFinalizeLaterLabel,
            variant: MxButtonVariant.ghost,
            block: true,
            onPressed: () => context.goHome(),
          ),
        ],
      ),
    );
  }
}

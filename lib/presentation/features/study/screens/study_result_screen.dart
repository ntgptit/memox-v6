import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_session/session_summary_policy.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_result_notifier.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
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
      loading: (context) => _Finalizing(label: l10n.studyFinalizingLabel),
      errorTitle: l10n.studyFinalizeErrorTitle,
      retryLabel: l10n.studyRetryLabel,
      onRetry: () => ref.read(studyResultProvider.notifier).retry(),
      data: (context, summary) => summary == null
          ? _Finalizing(label: l10n.studyFinalizingLabel)
          : SingleChildScrollView(child: _ResultBody(summary: summary)),
    );
  }
}

class _Finalizing extends StatelessWidget {
  const _Finalizing({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: MxText(label, role: MxTextRole.body));
  }
}

/// Formats active study time as `m:ss` for the kit time stat.
String _formatActiveTime(int milliseconds) {
  final totalSeconds = milliseconds ~/ Duration.millisecondsPerSecond;
  final minutes = totalSeconds ~/ Duration.secondsPerMinute;
  final seconds = totalSeconds % Duration.secondsPerMinute;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.summary});

  final StudySessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accuracy = summary.reviewedCount == 0
        ? 0
        : (summary.correctCount * 100 / summary.reviewedCount).round();
    final goalStatus = summary.goalStatus;

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
          const Center(
            child: MxIconTile(
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
              icon: Symbols.check_circle_rounded,
              tone: MxIconTileTone.accent,
              large: true,
            ),
          ),
          const MxGap.s3(),
          MxText(
            l10n.studyResultCompleteTitle,
            role: MxTextRole.subtitle,
            textAlign: TextAlign.center,
          ),
          const MxGap.s1(),
          MxText(
            l10n.studyResultReviewedText(summary.reviewedCount),
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
                onTap: () => context.goStudy(),
              ),
            ),
          ],
          if (goalStatus != null) ...<Widget>[
            const MxGap.s4(),
            _StreakCard(status: goalStatus),
          ],
          const MxGap.s4(),
          MxButton(
            icon: Symbols.bolt_rounded,
            label: l10n.studyResultContinueLabel,
            block: true,
            onPressed: () => context.goHome(),
          ),
          const MxGap.s2(),
          MxButton(
            variant: MxButtonVariant.ghost,
            label: l10n.studyResultDoneLabel,
            block: true,
            onPressed: () => context.goLibrary(),
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

/// The `Review mistakes` link (kit `study-result`, many-wrong branch). Starts a
/// The streak + today's-goal card (kit `study-result` `StreakGoalCard.jsx`,
/// "goal status when applicable" — `finalize-study-session.md` §4). A
/// primary-soft card with an internal space-3 rhythm: the flame + streak row,
/// then the goal label row (space-2 above the bar) and the progress bar.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.status});

  final StudyResultGoalStatus status;

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

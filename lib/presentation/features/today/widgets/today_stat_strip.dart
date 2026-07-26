import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/learning_progress/library_mastery.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_stat.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Today's inline stat strip (kit `dashboard/today`).
///
/// Flat, not a card: the kit keeps this screen to about two surface levels,
/// and merges the metrics into one low-surface summary rather than four
/// separate cards.
///
/// **Two of the kit's four stats are absent, and deliberately.** The kit shows
/// minutes studied, words learned today, day streak and library mastered.
///
/// - *Minutes studied* has no producer at all. `metric-formulas-v1` defines
///   `activeStudyDurationMs` as a union of validated foreground-active
///   intervals, but nothing captures those intervals: `study_attempts` has no
///   timing column and no flow owns recording them (`int-9`). A number here
///   would have to be invented.
/// - *Words learned today* is recorded only for learners who configured a
///   daily goal — `TrackDailyGoalUseCase` writes no day bucket without one.
///   For everyone else there is no count of today's qualified cards, and for
///   those who have a goal the Daily-goal card directly above already says it.
///   Repeating it two rows apart, from a source that vanishes when the goal
///   does, would be worse than leaving it out.
///
/// The two shown are both read from records that already exist, so what the
/// strip says is exactly what the store holds.
class TodayStatStrip extends StatelessWidget {
  const TodayStatStrip({
    super.key,
    required this.streakDays,
    required this.mastery,
  });

  final int streakDays;
  final LibraryMastery mastery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxText(l10n.todayStripTitle, role: MxTextRole.bodyStrong),
        const MxGap.s3(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: MxStat(
                icon: Symbols.local_fire_department_rounded,
                tone: MxStatTone.warning,
                value: l10n.todayStripStreakValue(streakDays),
                label: l10n.todayStripStreakLabel,
              ),
            ),
            const MxGap.s6(),
            Expanded(
              child: MxStat(
                icon: Symbols.verified_rounded,
                tone: MxStatTone.success,
                value: l10n.todayStripMasteryValue(
                  (mastery.fraction * 100).round(),
                ),
                label: l10n.todayStripMasteryLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

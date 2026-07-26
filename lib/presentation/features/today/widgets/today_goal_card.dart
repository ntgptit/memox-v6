import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_goal/daily_progress_status.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Today's daily-goal card (kit `dashboard/goal`).
///
/// Title and percentage on one baseline, the bar under them, and a caption
/// saying how far there is left to go. The percentage uses primary *text*
/// rather than the primary tint, which the kit calls out: tinted numerals read
/// as dim on the dark card, and the accent belongs to the bar.
///
/// Counted in qualified Cards, not minutes. The kit's card hardcodes
/// `minutes = 14, goal = 20`, but those are fixture values of the same kind
/// `StreakGoalCard.d.ts` describes as "hardcoded sample states" that Flutter
/// parameterizes — `metrics-v1` fixes the v1 unit as Cards and the schema
/// stores `target_card_count`. The Study Result made the same call.
class TodayGoalCard extends StatelessWidget {
  const TodayGoalCard({super.key, required this.status});

  final DailyProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    // Clamped so an over-target day reads 100% rather than something above it:
    // exceeding a goal is allowed and displayed as done, never as 130%.
    final fraction = status.goalTargetCards == 0
        ? 0.0
        : (status.goalDoneCards / status.goalTargetCards).clamp(0.0, 1.0);
    final percent = (fraction * 100).round();

    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child: MxText(
                  l10n.todayGoalCardTitle,
                  role: MxTextRole.bodyStrong,
                ),
              ),
              const MxGap.s3(),
              MxText(
                l10n.todayGoalCardPercent(percent),
                role: MxTextRole.subtitle,
                color: colors.text,
              ),
            ],
          ),
          const MxGap.s3(),
          MxProgress(
            value: fraction,
            semanticLabel: l10n.todayGoalCardSemantics(
              status.goalDoneCards,
              status.goalTargetCards,
            ),
          ),
          const MxGap.s3(),
          MxText(
            status.isMet
                ? l10n.todayGoalCardMetCaption(status.goalTargetCards)
                : l10n.todayGoalCardCaption(
                    status.goalDoneCards,
                    status.goalTargetCards,
                    status.goalTargetCards - status.goalDoneCards,
                  ),
            role: MxTextRole.caption,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

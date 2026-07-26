import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/domain/study_goal/daily_goal.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/daily_goal_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_action_callout.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart'
    show MxBannerTone;
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_switch.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_chip.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_setting_row.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The daily-goal form (`set-daily-study-goal.md`): enable/disable plus the
/// target, saved together.
///
/// One command for both fields, because §1 has a single effective
/// configuration — saving them separately would publish a half-applied goal
/// between the two writes.
Future<void> showDailyGoalSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showMxSheet<void>(
    context,
    title: l10n.dailyGoalLabel,
    child: const _DailyGoalBody(),
  );
}

class _DailyGoalBody extends ConsumerWidget {
  const _DailyGoalBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MxAsyncBuilder<DailyGoal?>(
      value: ref.watch(dailyGoalProvider),
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, goal) => _DailyGoalForm(goal: goal),
    );
  }
}

class _DailyGoalForm extends HookConsumerWidget {
  const _DailyGoalForm({required this.goal});

  final DailyGoal? goal;

  /// Targets offered, in qualified Cards — `metrics-v1` fixes the v1 unit.
  /// A short list rather than a free-text field: the schema requires a
  /// positive integer and no doc settles a range, so offering a picker avoids
  /// inventing bounds while still making every value it offers valid.
  static const List<int> _targets = <int>[5, 10, 20, 30, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goal = this.goal;

    final enabled = useState(goal?.isEnabled ?? true);
    // A disabled goal keeps its last target so re-enabling need not ask again
    // (§5); with no goal at all the middle option is the starting point.
    final target = useState(goal?.targetCardCount ?? 20);
    final saveState = ref.watch(dailyGoalCommandViewmodelProvider);
    final failure = MxActionErrors.failureOf(saveState);

    // §6: success confirms and closes; a failure keeps the sheet — and the
    // draft in it — exactly where it was. The sheet used to pop on whatever
    // came back, so a goal that never reached storage closed the form and
    // read as saved.
    listenMxAction(
      ref,
      dailyGoalCommandViewmodelProvider,
      onSuccess: () {
        showMxSnackbar(context, message: l10n.dailyGoalUpdatedMessage);
        Navigator.of(context).pop();
      },
    );

    Future<void> save() {
      return ref
          .read(dailyGoalCommandViewmodelProvider.notifier)
          .updateGoal(isEnabled: enabled.value, targetCardCount: target.value);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxSettingRow(
          title: l10n.dailyGoalEnabledLabel,
          body: l10n.dailyGoalEnabledBody,
          trailing: MxSwitch(
            value: enabled.value,
            onChanged: (value) => enabled.value = value,
            semanticLabel: l10n.dailyGoalEnabledLabel,
          ),
        ),
        const MxGap.s4(),
        MxText(l10n.dailyGoalTargetLabel, role: MxTextRole.captionStrong),
        const MxGap.s2(),
        // Disabled rather than hidden: §5 keeps the target visible so the
        // learner can see what re-enabling would restore.
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final option in _targets)
              MxChip(
                label: l10n.dailyGoalTargetOption(option),
                selected: target.value == option,
                onTap: enabled.value ? () => target.value = option : null,
              ),
          ],
        ),
        if (failure != null) ...[
          const MxGap.s4(),
          MxActionCallout(
            tone: MxBannerTone.error,
            text: l10n.dailyGoalSaveFailedMessage,
          ),
        ],
        const MxGap.s5(),
        MxButton(
          label: l10n.saveLabel,
          block: true,
          onPressed: saveState is AsyncLoading<void> ? null : save,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The shared chrome every Study stage renders inside (WBS 5.6.4; kit
/// `review-mode`/`*-mode` shots): a contextual app bar (back + mode title +
/// stage actions), a progress bar with an `answered/total` counter, the stage
/// [body], and an optional [bottomBar] action.
///
/// Template-only — it takes all data and callbacks through its constructor, so
/// it holds no state and reads no provider; the stage screen is the consumer
/// that feeds it. This keeps one constrained composition across every mode and
/// width.
class StudyShell extends StatelessWidget {
  const StudyShell({
    super.key,
    required this.title,
    required this.progress,
    required this.progressCounter,
    required this.progressSemanticLabel,
    required this.onBack,
    required this.backLabel,
    required this.body,
    this.actions = const <Widget>[],
    this.bottomBar,
  });

  /// The mode title, e.g. "Review".
  final String title;

  /// Round completion fraction in `[0, 1]`.
  final double progress;

  /// The `answered/total` counter, e.g. "7/20".
  final String progressCounter;

  /// Localized progress announcement for assistive tech.
  final String progressSemanticLabel;

  final VoidCallback onBack;
  final String backLabel;

  /// The stage content (the mode's prompt/interaction area).
  final Widget body;

  /// Trailing app-bar actions (font-size, overflow menu).
  final List<Widget> actions;

  /// Optional bottom action row (e.g. Review's swipe/continue controls).
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final bottomBar = this.bottomBar;
    return MxScaffold(
      scrollable: false,
      appBar: MxContextualAppBar(
        title: title,
        onBack: onBack,
        backLabel: backLabel,
        actions: actions,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Kit `.app__body`: space-4 top padding above the first child and a
          // space-6 gap between children (MxContentShell only supplies the
          // horizontal gutter). Sourced from tokens, not measured pixels.
          const MxGap.s4(),
          Row(
            children: <Widget>[
              Expanded(
                child: MxProgress(
                  value: progress,
                  semanticLabel: progressSemanticLabel,
                ),
              ),
              const MxGap.s3(),
              MxText(
                progressCounter,
                role: MxTextRole.caption,
                color: context.colors.textSecondary,
              ),
            ],
          ),
          const MxGap.s6(),
          Expanded(child: body),
          if (bottomBar != null) ...<Widget>[const MxGap.s6(), bottomBar],
        ],
      ),
    );
  }
}

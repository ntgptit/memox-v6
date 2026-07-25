import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_confirm_dialog.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

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

  /// Confirms before leaving, then hands off to [onBack].
  ///
  /// Here rather than in each screen because all five modes route their back
  /// action through this shell, and `exit-study-session.md` §1 makes the
  /// confirm unconditional: "X/Back trong active session luôn mở confirm".
  /// Every mode used to pop straight out, so a tap on Exit abandoned the
  /// screen mid-session with no warning at all.
  ///
  /// The session itself stays `active`, which is this build's resumable
  /// state — Today reads it back as the paused session and offers Continue —
  /// so `Save and exit` is a promise the model already keeps rather than a
  /// new transition.
  Future<void> _confirmExit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final leave = await showMxConfirmDialog(
      context,
      icon: Symbols.logout_rounded,
      tone: MxConfirmTone.warning,
      title: l10n.studyExitTitle,
      text: l10n.studyExitBody,
      confirmLabel: l10n.studyExitConfirmLabel,
      cancelLabel: l10n.studyExitKeepLabel,
    );
    if (leave) onBack();
  }

  @override
  Widget build(BuildContext context) {
    final bottomBar = this.bottomBar;
    return MxScaffold(
      scrollable: false,
      appBar: MxContextualAppBar(
        title: title,
        onBack: () => _confirmExit(context),
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
                  prominent: true,
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
          // Kit `.app__body` reserves the bottom-nav band below its content
          // (`padding-bottom: nav + space-6`) and then hands it straight back
          // to the thumb-zone control (`marginBottom: -bottom-nav-height`),
          // so the band costs the stage nothing and the control ends up
          // space-6 above the safe-area bottom.
          //
          // This used to reserve the band with a `space-11` gap and never
          // reclaim it, which is not the same thing: the study routes are
          // top-level and carry no bottom nav, so those 80px were pure empty
          // space between the stage and the control. Measured against
          // `review-mode--browsing`, it left both cards ~38px shorter than the
          // kit's while the control itself sat in the right place.
          if (bottomBar != null) ...<Widget>[
            const MxGap.s6(),
            bottomBar,
            const MxGap.s6(),
          ],
        ],
      ),
    );
  }
}

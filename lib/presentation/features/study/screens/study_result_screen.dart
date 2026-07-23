import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
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
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Study Result (WBS 5.6.13; `finalize-study-session.md`, kit `study-result`).
/// A terminal summary page — no back; exit only via the explicit actions. The
/// consumer child renders the committed [StudySessionSummary] from
/// [studyResultProvider], whose AsyncValue drives the kit states: finalizing
/// (loading), finalize-error with Retry (error), and the standard result (data).
/// Goal/streak and the time stat are deferred (not computed at finalize yet);
/// Review missed needs the relearn start (GAP-A) and is omitted here.
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

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.summary});

  final StudySessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accuracy = summary.reviewedCount == 0
        ? 0
        : (summary.correctCount * 100 / summary.reviewedCount).round();

    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const MxGap.s5(),
          const Center(child: MxIcon(icon: Symbols.task_alt_rounded)),
          const MxGap.s4(),
          MxText(
            l10n.studyResultCompleteTitle,
            role: MxTextRole.title,
            textAlign: TextAlign.center,
          ),
          const MxGap.s2(),
          MxText(
            l10n.studyResultReviewedText(summary.reviewedCount),
            role: MxTextRole.body,
            textAlign: TextAlign.center,
          ),
          const MxGap.s6(),
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
            ],
          ),
          const MxGap.s6(),
          MxButton(
            icon: Symbols.arrow_forward_rounded,
            label: l10n.studyResultContinueLabel,
            block: true,
            onPressed: () => context.goHome(),
          ),
          const MxGap.s3(),
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

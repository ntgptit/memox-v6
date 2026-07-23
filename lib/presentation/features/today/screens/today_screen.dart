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
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_header.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The Today entry (WBS 5.7.2; `load-today-dashboard.md`, kit `dashboard`). A
/// branch of `AppTabShell` (the bottom nav lives there), it renders the composed
/// [TodayProjection] into exactly one primary action: resume a paused session,
/// start a review, create a first deck, or an all-caught-up message — plus the
/// loading and load-error states.
///
/// Scoped to the projection's primary CTA: the kit's Daily-goal card, the
/// four-stat Today strip and the Recent-decks list are deferred (they need the
/// goal/streak, time-studied and mastery sources that are not composed yet), and
/// Start review currently opens the Library because no session-start UI command
/// exists app-wide and `StartStudySessionUseCase` is deck-scoped (recorded gaps).
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
      appBar: MxContextualAppBar(title: l10n.todayTitle),
      body: const _TodayBody(),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MxAsyncBuilder<TodayProjection>(
      value: ref.watch(todayProjectionProvider),
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.todayErrorTitle,
      retryLabel: l10n.studyRetryLabel,
      onRetry: () => ref.invalidate(todayProjectionProvider),
      data: (context, projection) => switch (projection.primaryAction) {
        TodayPrimaryAction.continueSession => _PausedState(),
        TodayPrimaryAction.startReview => _DueState(
          dueCount: projection.dueCount,
        ),
        TodayPrimaryAction.createLibrary => _EmptyState(),
        TodayPrimaryAction.caughtUp => _CaughtUpState(),
      },
    );
  }
}

class _PausedState extends StatelessWidget {
  const _PausedState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: <Widget>[
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
          onPressed: () => context.goStudy(),
        ),
      ],
    );
  }
}

class _DueState extends StatelessWidget {
  const _DueState({required this.dueCount});

  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
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
          onPressed: () => context.goLibrary(),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MxEmptyState(
      icon: Icons.school_outlined,
      title: l10n.todayEmptyTitle,
      body: l10n.todayEmptyBody,
      action: MxButton(
        icon: Symbols.add_rounded,
        label: l10n.todayCreateLabel,
        onPressed: () => context.goLibrary(),
      ),
    );
  }
}

class _CaughtUpState extends StatelessWidget {
  const _CaughtUpState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MxEmptyState(
      icon: Icons.check_circle_outline,
      title: l10n.todayCaughtUpTitle,
      body: l10n.todayCaughtUpBody,
    );
  }
}

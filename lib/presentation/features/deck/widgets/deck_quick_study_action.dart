import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_start_notifier.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';

/// The deck card's trailing study action (kit deck-row bolt).
///
/// Starts a session for one deck straight from a list, without opening it
/// first. It only dispatches: the navigation that follows a successful
/// start is listened for **once per screen**, by
/// [listenForQuickStudyStart].
///
/// That split is not stylistic. `studyStartProvider` is a single app-wide
/// command, so a listener mounted per row would fire once per visible row
/// on the same success — a list of ten decks would push the study route
/// ten times.
class DeckQuickStudyAction extends ConsumerWidget {
  const DeckQuickStudyAction({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isStarting = ref.watch(studyStartProvider) is AsyncLoading<void>;

    return MxIconButton(
      icon: Symbols.bolt_rounded,
      semanticLabel: l10n.deckStudyLabel,
      // One start at a time: the command guards re-entrancy itself, and a
      // dimmed control says so rather than swallowing the tap silently.
      onPressed: isStarting
          ? null
          : () => ref.read(studyStartProvider.notifier).start(deckId: deckId),
    );
  }
}

/// Navigates to the study route once a quick start commits, and answers the
/// one failure that is a decision rather than an error.
///
/// Mount this exactly once on a screen that shows [DeckQuickStudyAction]
/// rows — see that widget for why it must not live on the row itself.
void listenForQuickStudyStart(WidgetRef ref, BuildContext context) {
  listenMxAction(
    ref,
    studyStartProvider,
    onSuccess: () => context.goStudy(),
    onFailure: (failure) {
      // `start-study-session.md` §3 node D. A session is already running, and
      // the schema allows exactly one — so this is not a thing that went
      // wrong, it is a fork the learner has to take. Every other failure
      // stays a failure and is left to the shared error surface.
      if (failure is! ConflictFailure) return;
      if (failure.code != 'active-session') return;
      unawaited(_confirmResumeActiveSession(context));
    },
  );
}

/// The kit's `Continue your session?` prompt (`start-study-session.md` §4).
///
/// It offers `Resume` and dismissal, not the spec's `Start over`. Starting
/// over ends the running session, and **no document owns what that means**:
/// `exit-study-session.md` is explicit that leaving a session pauses it and
/// that the default confirm carries no destructive discard, while
/// `track-daily-goal.md` mentions an abandoned finalize only to say it must
/// not double-count. Nothing says whether an abandoned session's committed
/// answers keep their goal and streak contributions. Offering a button whose
/// consequences are undefined would be worse than offering one fewer.
Future<void> _confirmResumeActiveSession(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final resume = await showMxDialog<bool>(
    context,
    title: l10n.studyActiveSessionTitle,
    body: MxText(l10n.studyActiveSessionBody, role: MxTextRole.body),
    actions: <Widget>[
      MxButton(
        variant: MxButtonVariant.ghost,
        label: l10n.cancelLabel,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      MxButton(
        label: l10n.todayResumeLabel,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ],
  );
  if (resume == true && context.mounted) context.goStudy();
}

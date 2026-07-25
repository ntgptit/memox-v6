import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
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

/// Navigates to the study route once a quick start commits.
///
/// Mount this exactly once on a screen that shows [DeckQuickStudyAction]
/// rows — see that widget for why it must not live on the row itself.
void listenForQuickStudyStart(WidgetRef ref, BuildContext context) {
  listenMxAction(ref, studyStartProvider, onSuccess: () => context.goStudy());
}

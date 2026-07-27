import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_runtime_state.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_note.dart';

/// Says which kind of session the learner is in, above the prompt.
///
/// `relearn-cards.md` §1 requires that the learner "được biết còn bao nhiêu
/// Cards cần relearn", and §4 heads the surface `Relearn` over that count.
/// `srs-binary-review.md` §2 gives relearn and due review different scheduling
/// semantics — a relearn schedules from the card's *current* box and can
/// promote it, a due review moves it along its schedule. The two ran on the
/// same screen with the same title and no notice, so they were the same
/// picture with different consequences.
///
/// The kit marks both states this way (`study-session--relearn`,
/// `--due-review`), and its Guess variant adds "not counted toward progress".
/// That copy is not used: a relearn session in this build *is* counted — it
/// schedules once per card and qualifies for the goal and streak — so the kit
/// sentence would be a false statement about the product.
///
/// Returns null for the session types that need no notice: new learning and
/// practice are what the plain stage chrome already describes.
class StudySessionNote extends StatelessWidget {
  const StudySessionNote({super.key, required this.runtime});

  final StudyRuntimeState runtime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final position = runtime.position;
    final remaining = position.roundCardIds.length - position.cardPosition;

    return switch (runtime.session.type) {
      SessionType.relearn => MxNote(
        tone: MxNoteTone.warning,
        icon: Symbols.replay_rounded,
        text: l10n.relearnNoteBody(remaining),
      ),
      SessionType.dueReview => MxNote(
        tone: MxNoteTone.warning,
        icon: Symbols.schedule_rounded,
        text: l10n.dueReviewNoteBody,
      ),
      SessionType.newLearning ||
      SessionType.practice => const SizedBox.shrink(),
    };
  }
}

/// The stage title for [runtime], which is the session's kind when it has one.
///
/// A relearn session ran under the title of whichever strategy its plan
/// resolved — `Guess` or `Review` — so nothing on screen said these were the
/// cards the learner had just missed (`relearn-cards.md` §4).
String studyStageTitle(
  AppLocalizations l10n,
  StudyRuntimeState runtime,
  String modeTitle,
) {
  return runtime.session.type == SessionType.relearn
      ? l10n.relearnModeTitle
      : modeTitle;
}

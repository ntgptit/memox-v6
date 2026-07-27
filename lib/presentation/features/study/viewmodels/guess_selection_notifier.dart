import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guess_selection_notifier.g.dart';

/// The learner's chosen Guess option for the current card (WBS 5.6.7): the
/// selected choice id, or `null` while waiting. Presentation-only — it holds
/// the pre-commit selection so the feedback state can render before Continue
/// writes the attempt.
///
/// Keyed by `cardId`, like `FillFeedback` next door, so the next card starts
/// unselected without anyone clearing it. The screen used to clear it the
/// moment Continue was tapped, which meant a save that failed took the
/// learner's choice off the screen while the dialog told them their answer
/// was still there (`answer-study-stage.md` §6).
@riverpod
class GuessSelection extends _$GuessSelection {
  @override
  String? build(String cardId) => null;

  void select(String choiceId) => state = choiceId;
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guess_selection_notifier.g.dart';

/// The learner's chosen Guess option for the current card (WBS 5.6.7): the
/// selected choice id, or `null` while waiting. Presentation-only — it holds the
/// pre-commit selection so the feedback state can render before Continue writes
/// the attempt. Resets with the screen.
@riverpod
class GuessSelection extends _$GuessSelection {
  @override
  String? build() => null;

  void select(String choiceId) => state = choiceId;

  void clear() => state = null;
}

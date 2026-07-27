/// Outcome of a reset-progress submit (`reset-deck-progress.md` §5, §11).
///
/// §5: "Counts refresh trước submit; impact đổi yêu cầu confirm lại", and §11's
/// action matrix gives "Impact changed" its own row whose destructive action is
/// *Confirm lại* rather than Reset. A destructive confirm is a promise about a
/// number, so the number has to still be true when the button is pressed.
sealed class ResetProgressResult {
  const ResetProgressResult();
}

/// The reset ran over the scope the learner confirmed.
final class ProgressReset extends ResetProgressResult {
  const ProgressReset(this.cardCount);

  /// How many cards were returned to the unlearned state.
  final int cardCount;
}

/// Nothing was reset: the affected count moved between the confirm and the
/// submit, so the learner is shown the new impact and asked again.
final class ResetImpactChanged extends ResetProgressResult {
  const ResetImpactChanged(this.affectedCardCount);

  /// The count as it is now.
  final int affectedCardCount;
}

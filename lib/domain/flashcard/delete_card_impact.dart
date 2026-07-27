/// What deleting a card would disturb (`delete-flashcard.md` §3, §5).
///
/// §3's first node is "Load content/session/progress impact" and §9 asks the
/// confirm to state "exact impact". The confirm said the same sentence for a
/// card nobody was studying and a card sitting in the session the learner has
/// open, which are not the same decision.
enum DeleteCardImpact {
  /// Nothing is studying this card. §5's "No active session | Normal confirm".
  none,

  /// It is in the active session but is not the prompt on screen. §5 allows
  /// the delete and the session skips the card when its turn comes.
  inSession,

  /// It *is* the current prompt. §5 blocks the delete outright: the learner
  /// has to exit, commit the answer or skip before this is allowed.
  currentPrompt,
}

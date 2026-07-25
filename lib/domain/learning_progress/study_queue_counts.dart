/// Per-queue eligible card counts for one scope (WBS 5.4.2;
/// `surface-due-cards.md` §4).
///
/// The queues are mutually exclusive by construction — a card's box puts
/// it in exactly one of them, or in none:
///
/// - [newCount]: Box 0, not yet introduced.
/// - [dueCount]: Box 1..7 whose due instant has been reached.
/// - Box 8 is mastered and belongs to no queue.
///
/// Relearn is deliberately absent. It is not an SRS state: it is a set
/// of cards a learner picked from a *finalized* session's terminal
/// wrongs (§4), so it needs the session history that `5.6.13` will
/// deliver and cannot be derived from progress alone.
class StudyQueueCounts {
  const StudyQueueCounts({required this.dueCount, required this.newCount});

  static const StudyQueueCounts empty = StudyQueueCounts(
    dueCount: 0,
    newCount: 0,
  );

  final int dueCount;
  final int newCount;

  int get totalCount => dueCount + newCount;

  /// No eligible card in this scope. Distinct from "due is zero but new
  /// cards remain", which §9 requires consumers to tell apart.
  bool get hasNoEligibleCards => totalCount == 0;

  /// Nothing to review right now, though the scope may still hold new
  /// cards. §4 forbids inventing due items to fill this state.
  bool get hasNothingDue => dueCount == 0;
}

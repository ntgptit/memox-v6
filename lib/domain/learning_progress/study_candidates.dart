/// Eligible study queues for a deck scope (WBS 5.4.2, `surface-due-cards.md`).
///
/// A read-only selection: [dueCardIds] are learned cards whose review is
/// reached (ordered soonest-due first), [newCardIds] are cards with initial
/// progress not yet introduced. Each card appears at most once across the
/// queues. Relearn candidates are a separate, session-derived set and are not
/// modelled here.
class StudyCandidates {
  const StudyCandidates({required this.dueCardIds, required this.newCardIds});

  const StudyCandidates.empty() : dueCardIds = const [], newCardIds = const [];

  final List<String> dueCardIds;
  final List<String> newCardIds;

  int get dueCount => dueCardIds.length;
  int get newCount => newCardIds.length;
  bool get isEmpty => dueCardIds.isEmpty && newCardIds.isEmpty;
}

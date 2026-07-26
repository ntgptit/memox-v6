/// Where a card created from Today would go
/// (`manage-today-create-actions.md` §2, node C).
sealed class AddCardTarget {
  const AddCardTarget();
}

/// Exactly one deck can hold a card, so there is nothing to choose.
class SingleAddCardTarget extends AddCardTarget {
  const SingleAddCardTarget(this.deckId);

  final String deckId;
}

/// More than one deck could hold it. §1: "Add Card cần eligible target; nếu
/// thiếu phải chọn/tạo Deck trước" — picking one here would put the card
/// somewhere the learner never named.
class ChooseAddCardTarget extends AddCardTarget {
  const ChooseAddCardTarget();
}

/// Nothing can hold a card yet: an empty library, or one whose only decks are
/// Parents (flow node F). The guidance is to create a deck first.
class NoAddCardTarget extends AddCardTarget {
  const NoAddCardTarget();
}

/// Flashcard domain model (WBS 4.5): term + primary meaning in the
/// owning Leaf Deck, with content version and hidden/soft-delete
/// lifecycle.
class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.term,
    required this.primaryMeaning,
    required this.contentVersion,
    required this.isHidden,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deckId;
  final String term;
  final String primaryMeaning;
  final int contentVersion;
  final bool isHidden;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDeleted => deletedAt != null;
}

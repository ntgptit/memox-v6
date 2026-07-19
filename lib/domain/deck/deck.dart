/// Deck domain model (WBS 4.5). Deck state (empty/cards/subdecks) is
/// derived from children and direct cards, never stored.
class Deck {
  const Deck({
    required this.id,
    required this.languagePairId,
    required this.parentId,
    required this.name,
    required this.normalizedName,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String languagePairId;
  final String? parentId;
  final String name;
  final String normalizedName;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRoot => parentId == null;
}

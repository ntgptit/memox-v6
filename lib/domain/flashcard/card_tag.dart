/// Tag attachable to Flashcards (WBS 4.5).
class CardTag {
  const CardTag({
    required this.id,
    required this.name,
    required this.normalizedName,
  });

  final String id;
  final String name;
  final String normalizedName;
}

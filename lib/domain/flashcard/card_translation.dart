/// Additional translation owned by a Flashcard (WBS 4.5).
class CardTranslation {
  const CardTranslation({
    required this.id,
    required this.cardId,
    required this.languageCode,
    required this.text,
    required this.displayOrder,
  });

  final String id;
  final String cardId;
  final String languageCode;
  final String text;
  final int displayOrder;
}

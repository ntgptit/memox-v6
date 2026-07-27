/// One additional translation as it stands in the Card Editor's draft
/// (`manage-card-translations.md` §6).
///
/// §6 is explicit that child edits live in the parent draft until Save —
/// "Child edits live in parent Card draft until Save", and "Removing existing
/// translation can be undone by discard parent draft". The create path already
/// works this way: it collects translations and commits them inside the card's
/// own atomic operation. Edit mode did not, so every add and remove hit the
/// store the moment it was tapped, and Discard restored none of it (`int-99`).
class CardTranslationDraft {
  const CardTranslationDraft({
    required this.text,
    required this.languageCode,
    this.id,
  });

  /// The stored row's id, or `null` for a row the draft has not saved yet.
  /// §1 asks for stable identity, so a row that already exists keeps its own
  /// through the edit rather than being deleted and re-inserted.
  final String? id;

  final String text;
  final String languageCode;

  CardTranslationDraft withText(String value) =>
      CardTranslationDraft(id: id, text: value, languageCode: languageCode);
}

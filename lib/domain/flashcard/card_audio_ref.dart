/// Audio asset reference owned by a Flashcard (WBS 4.5): asset and
/// provider metadata only — player state belongs to Audio Playback.
class CardAudioRef {
  const CardAudioRef({
    required this.id,
    required this.cardId,
    required this.languageCode,
    required this.assetId,
    required this.provider,
  });

  final String id;
  final String cardId;
  final String languageCode;
  final String assetId;
  final String provider;
}

import 'package:memox_v6/domain/flashcard/card_audio_ref.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';

/// Complete content of a card being created (WBS 4.6A): the card plus
/// its optional child content, committed atomically as schema-v1
/// operation 1.
class NewCardContent {
  const NewCardContent({
    required this.card,
    this.translations = const [],
    this.tagIds = const [],
    this.audioRefs = const [],
  });

  final Flashcard card;
  final List<CardTranslation> translations;
  final List<String> tagIds;
  final List<CardAudioRef> audioRefs;
}

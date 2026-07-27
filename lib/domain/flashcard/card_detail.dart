import 'package:memox_v6/domain/flashcard/card_tag.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress.dart';

/// One Card as the detail surface presents it (`view-card-detail.md`).
///
/// A read projection, not an aggregate: it holds what the owning flows store
/// and owns none of it. The spec says as much — Card Detail "does not
/// duplicate edit, move, hide, delete, audio, translation, tag or Progress
/// rules".
class CardDetail {
  const CardDetail({
    required this.card,
    required this.deckName,
    required this.translations,
    required this.tags,
    required this.progress,
  });

  final Flashcard card;

  /// The owning deck's name — the "Deck path" the projection lists. Null when
  /// the deck read failed or the row is gone; the detail still renders its
  /// core text, which is what the Partial state asks for.
  final String? deckName;

  final List<CardTranslation> translations;
  final List<CardTag> tags;

  /// Read-only scheduling summary: Box and due status. Null before the card
  /// has any progress row at all.
  final LearningProgress? progress;
}

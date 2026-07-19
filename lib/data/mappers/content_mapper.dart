import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/mappers/primitive_mapper.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/card_audio_ref.dart';
import 'package:memox_v6/domain/flashcard/card_tag.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';

/// Content row → domain mappers (WBS 4.5). Explicit field-by-field
/// translation; domain code never sees Drift rows.

extension LanguagePairRowMapper on db.LanguagePair {
  LanguagePair toDomain() => LanguagePair(
    id: id,
    learningLanguageCode: learningLanguageCode,
    nativeLanguageCode: nativeLanguageCode,
    normalizedPairKey: normalizedPairKey,
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

extension DeckRowMapper on db.Deck {
  Deck toDomain() => Deck(
    id: id,
    languagePairId: languagePairId,
    parentId: parentId,
    name: name,
    normalizedName: normalizedName,
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

extension FlashcardRowMapper on db.Flashcard {
  Flashcard toDomain() => Flashcard(
    id: id,
    deckId: deckId,
    term: term,
    primaryMeaning: primaryMeaning,
    contentVersion: contentVersion,
    isHidden: storedBool(isHidden, entity: 'flashcards', field: 'is_hidden'),
    deletedAt: utcDateTimeOrNull(deletedAt),
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

extension CardTranslationRowMapper on db.FlashcardTranslation {
  CardTranslation toDomain() => CardTranslation(
    id: id,
    cardId: cardId,
    languageCode: languageCode,
    text: translationText,
    displayOrder: displayOrder,
  );
}

extension CardTagRowMapper on db.Tag {
  CardTag toDomain() =>
      CardTag(id: id, name: name, normalizedName: normalizedName);
}

extension CardAudioRefRowMapper on db.CardAudioRef {
  CardAudioRef toDomain() => CardAudioRef(
    id: id,
    cardId: cardId,
    languageCode: languageCode,
    assetId: assetId,
    provider: provider,
  );
}

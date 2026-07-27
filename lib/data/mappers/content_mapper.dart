import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/database/daos/deck_dao.dart' as db;
import 'package:memox_v6/data/mappers/primitive_mapper.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
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
    description: description,
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

/// The move-picker candidate row: the deck columns plus the computed reason
/// it cannot receive the move. Drift generates a distinct result class per
/// query, so the deck mapping is repeated rather than shared.
extension MoveDestinationCandidateRowMapper
    on db.MoveDestinationCandidatesResult {
  Deck toDomain() => Deck(
    id: id,
    languagePairId: languagePairId,
    parentId: parentId,
    name: name,
    normalizedName: normalizedName,
    description: description,
    createdAt: utcDateTime(createdAt),
    updatedAt: utcDateTime(updatedAt),
  );
}

/// The child-scoped summary row carries the same columns as the root one,
/// but drift generates a distinct result class per query, so the mapping is
/// repeated rather than shared.
extension ChildDeckSummaryRowMapper on db.WatchChildDeckSummariesResult {
  DeckSummary toDomain() => DeckSummary(
    deck: Deck(
      id: id,
      languagePairId: languagePairId,
      parentId: parentId,
      name: name,
      normalizedName: normalizedName,
      description: description,
      createdAt: utcDateTime(createdAt),
      updatedAt: utcDateTime(updatedAt),
    ),
    cardCount: cardCount,
    dueCount: dueCount,
    newCount: newCount,
    masteredCount: masteredCount,
    studiableCount: studiableCount,
  );
}

extension DeckSummaryRowMapper on db.WatchRootDeckSummariesResult {
  DeckSummary toDomain() => DeckSummary(
    deck: Deck(
      id: id,
      languagePairId: languagePairId,
      parentId: parentId,
      name: name,
      normalizedName: normalizedName,
      description: description,
      createdAt: utcDateTime(createdAt),
      updatedAt: utcDateTime(updatedAt),
    ),
    cardCount: cardCount,
    dueCount: dueCount,
    newCount: newCount,
    masteredCount: masteredCount,
    studiableCount: studiableCount,
  );
}

/// The Dashboard's Recent-decks row: the Library columns plus the ordering
/// key, which the domain summary does not carry — the order is the query's
/// answer, not a field the caller re-sorts by.
extension RecentDeckSummaryRowMapper on db.RecentRootDeckSummariesResult {
  DeckSummary toDomain() => DeckSummary(
    deck: Deck(
      id: id,
      languagePairId: languagePairId,
      parentId: parentId,
      name: name,
      normalizedName: normalizedName,
      description: description,
      createdAt: utcDateTime(createdAt),
      updatedAt: utcDateTime(updatedAt),
    ),
    cardCount: cardCount,
    dueCount: dueCount,
    newCount: newCount,
    masteredCount: masteredCount,
    studiableCount: studiableCount,
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

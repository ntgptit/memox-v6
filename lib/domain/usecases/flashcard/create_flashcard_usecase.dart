import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/card_audio_ref.dart';
import 'package:memox_v6/domain/flashcard/card_text.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/new_card_content.dart';

/// Creates a flashcard (WBS 5.3.1A; `create-flashcard.md`).
///
/// Validation is typed (required term/meaning, VAL-001 trimming);
/// duplicate detection runs **before** commit against normalized terms
/// across the owning pair and never overwrites — candidates return as
/// [DuplicateCandidatesFound] and only an explicit keep-both retry
/// ([allowDuplicate]) proceeds past them. The commit itself is
/// schema-v1 atomic operation 1 (card + child content + Box 0
/// progress), with the card id as the kept-id idempotency key.
class CreateFlashcardUseCase {
  const CreateFlashcardUseCase({
    required FlashcardRepository cards,
    required DeckRepository decks,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _cards = cards,
       _decks = decks,
       _idGenerator = idGenerator,
       _clock = clock;

  final FlashcardRepository _cards;
  final DeckRepository _decks;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  Future<CreateFlashcardResult> call({
    required String deckId,
    required String term,
    required String primaryMeaning,
    String? retryCardId,
    bool allowDuplicate = false,
    List<({String languageCode, String text})> translations = const [],
    bool isHidden = false,
    List<String> tagIds = const [],
    List<CardAudioRef> audioRefs = const [],
  }) async {
    final displayTerm = validateCardText(term, field: 'term');
    final displayMeaning = validateCardText(
      primaryMeaning,
      field: 'primaryMeaning',
    );

    if (retryCardId != null) {
      final existing = await _cards.findById(retryCardId);
      if (existing != null) return FlashcardCreated(existing);
    }

    final deck = await _decks.findById(deckId);
    if (deck == null) {
      throw ValidationFailure(field: 'deckId', code: 'unknown');
    }

    if (!allowDuplicate) {
      final candidates = await _cards.duplicateCandidates(
        languagePairId: deck.languagePairId,
        normalizedTerm: normalizeCardTerm(displayTerm),
      );
      if (candidates.isNotEmpty) {
        return DuplicateCandidatesFound(candidates);
      }
    }

    final now = _clock.nowUtc();
    final card = Flashcard(
      id: retryCardId ?? _idGenerator.newId(),
      deckId: deckId,
      term: displayTerm,
      primaryMeaning: displayMeaning,
      contentVersion: 1,
      // A card can be created already hidden (kit
      // `flashcard-editor/visibility`, inside More options): captured now,
      // studied later. It was hard-coded visible, so the editor had no way
      // to express that.
      isHidden: isHidden,
      deletedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    // Translations arrive as raw text, not as built rows: their `cardId` is
    // the id minted just above, so a caller could not fill it in. Building
    // them here also keeps them inside the same atomic commit as the card —
    // writing them afterwards would leave a card stored with its translation
    // missing if the second write failed, and a retry would then create a
    // duplicate card.
    final rows = <CardTranslation>[
      for (final (index, translation) in translations.indexed)
        CardTranslation(
          id: _idGenerator.newId(),
          cardId: card.id,
          languageCode: translation.languageCode,
          text: validateCardText(translation.text, field: 'translation'),
          displayOrder: index,
        ),
    ];

    await _cards.createCard(
      NewCardContent(
        card: card,
        translations: rows,
        tagIds: tagIds,
        audioRefs: audioRefs,
      ),
    );
    return FlashcardCreated(card);
  }
}

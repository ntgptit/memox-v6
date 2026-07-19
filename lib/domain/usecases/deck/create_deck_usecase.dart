import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/deck/deck_name.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';

/// Creates a root or nested deck (WBS 5.2.2; `create-deck.md`).
///
/// The create is one atomic insert with **no automatic content** — a
/// new deck is always Empty and its content type stays unlocked.
/// Conflict contract (store-enforced, typed): sibling-name collisions →
/// `ConflictFailure('duplicate')`; a card-holding parent →
/// `'deck-mixed-content'`; a cross-pair parent → `'deck-pair-mismatch'`.
///
/// Retry idempotency: a caller that must retry an unknown outcome
/// passes the same [retryDeckId] it generated for the first attempt —
/// finding it stored means the earlier insert committed, and the
/// stored deck is returned unchanged.
class CreateDeckUseCase {
  const CreateDeckUseCase({
    required DeckRepository decks,
    required LanguagePairRepository pairs,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _decks = decks,
       _pairs = pairs,
       _idGenerator = idGenerator,
       _clock = clock;

  final DeckRepository _decks;
  final LanguagePairRepository _pairs;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  Future<Deck> call({
    required String name,
    required String languagePairId,
    String? parentId,
    String? retryDeckId,
  }) async {
    final displayName = validateDeckName(name);
    final normalizedName = normalizeDeckName(name);

    if (retryDeckId != null) {
      final existing = await _decks.findById(retryDeckId);
      if (existing != null) return existing;
    }

    final pair = await _pairs.findById(languagePairId);
    if (pair == null) {
      throw ValidationFailure(field: 'languagePairId', code: 'unknown');
    }
    if (parentId != null) {
      final parent = await _decks.findById(parentId);
      if (parent == null) {
        throw ValidationFailure(field: 'parentId', code: 'unknown');
      }
    }

    final now = _clock.nowUtc();
    final deck = Deck(
      id: retryDeckId ?? _idGenerator.newId(),
      languagePairId: languagePairId,
      parentId: parentId,
      name: displayName,
      normalizedName: normalizedName,
      createdAt: now,
      updatedAt: now,
    );
    await _decks.createDeck(deck);
    return deck;
  }
}

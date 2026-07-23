import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Moves a deck to a new parent, or to the Library root (WBS 6.1; `move-deck.md`,
/// kit `deck-settings--move`).
///
/// The move keeps the deck's id, content, learning progress and metadata; only
/// its parent changes. The structural invariants are the store's atomic
/// authority (per the [DeckRepository] conflict contract), so this use case does
/// not recompute them (a use-case-side descendant walk would race the write): a
/// self/descendant target surfaces as `ConflictFailure('deck-cycle')`, a
/// card-holding (leaf) target as `'deck-mixed-content'`, and a destination
/// sibling-name collision as `'duplicate'`. The use case only resolves the deck
/// and — when moving under a parent — the target, raising a typed
/// [ValidationFailure] when either is missing so the caller can reload rather
/// than move into a stale destination.
class MoveDeckUseCase {
  const MoveDeckUseCase({
    required DeckRepository decks,
    required AppClock clock,
  }) : _decks = decks,
       _clock = clock;

  final DeckRepository _decks;
  final AppClock _clock;

  /// [newParentId] `null` moves the deck to the Library root.
  Future<void> call({required String deckId, String? newParentId}) async {
    final deck = await _decks.findById(deckId);
    if (deck == null) {
      throw ValidationFailure(field: 'deckId', code: 'unknown');
    }
    if (newParentId != null) {
      final target = await _decks.findById(newParentId);
      if (target == null) {
        throw ValidationFailure(field: 'newParentId', code: 'unknown');
      }
    }

    await _decks.move(
      deckId,
      newParentId: newParentId,
      updatedAt: _clock.nowUtc(),
    );
  }
}

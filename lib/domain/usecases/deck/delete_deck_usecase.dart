import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Permanently deletes a deck and its whole subtree (WBS 6.1; `delete-deck.md`,
/// kit `deck-settings--delete-confirm`).
///
/// A command only — the confirm dialog loads and shows the impact summary
/// (nested decks / cards / learning progress) *before* calling this. The store
/// removes the subtree atomically (a failure removes nothing) and there is no
/// undo (`delete-deck.md` §1), so the caller must confirm first. A missing deck
/// is a typed [ValidationFailure] so a stale action reports recovery instead of
/// silently succeeding.
class DeleteDeckUseCase {
  const DeleteDeckUseCase({required DeckRepository decks}) : _decks = decks;

  final DeckRepository _decks;

  Future<void> call(String deckId) async {
    final deck = await _decks.findById(deckId);
    if (deck == null) {
      throw ValidationFailure(field: 'deckId', code: 'unknown');
    }
    await _decks.delete(deckId);
  }
}

import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/deck/deck_name.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Renames an existing deck (WBS 6.1; `edit-deck.md`, kit `deck-settings--rename`).
///
/// Metadata-only: it changes the display name without touching the deck's
/// structure or content. The name is trimmed + validated ([validateDeckName]),
/// and a sibling-name collision surfaces as the store's typed
/// `ConflictFailure('duplicate')` — the use case never dedupes itself. A missing
/// deck is a typed [ValidationFailure], so the caller shows recovery rather than
/// silently doing nothing.
class RenameDeckUseCase {
  const RenameDeckUseCase({
    required DeckRepository decks,
    required AppClock clock,
  }) : _decks = decks,
       _clock = clock;

  final DeckRepository _decks;
  final AppClock _clock;

  Future<void> call({required String deckId, required String name}) async {
    final displayName = validateDeckName(name);
    final normalized = normalizeDeckName(name);

    final deck = await _decks.findById(deckId);
    if (deck == null) {
      throw ValidationFailure(field: 'deckId', code: 'unknown');
    }

    await _decks.rename(
      deckId,
      name: displayName,
      normalizedName: normalized,
      updatedAt: _clock.nowUtc(),
    );
  }
}

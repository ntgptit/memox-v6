import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/deck/deck_name.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';

/// Edits an existing deck's metadata (WBS 6.1; `edit-deck.md`, kit
/// `deck-settings--rename`).
///
/// Metadata-only: it changes the display name and the optional description
/// without touching the deck's structure or content. §1 makes them one save —
/// "Save failure giữ toàn bộ draft; không autosave một phần form" — so both
/// travel in a single write. The name is trimmed + validated
/// ([validateDeckName]), and a sibling-name collision surfaces as the store's
/// typed `ConflictFailure('duplicate')`; the use case never dedupes itself. A
/// missing deck is a typed [ValidationFailure], so the caller shows recovery
/// rather than silently doing nothing.
///
/// The description had no editing path at all until 2026-07-27: the column,
/// the domain field and the first-run form all carried it, and nothing could
/// change it afterwards (`int-57`).
class RenameDeckUseCase {
  const RenameDeckUseCase({
    required DeckRepository decks,
    required AppClock clock,
  }) : _decks = decks,
       _clock = clock;

  final DeckRepository _decks;
  final AppClock _clock;

  Future<void> call({
    required String deckId,
    required String name,
    String? description,
  }) async {
    final displayName = validateDeckName(name);
    final normalized = normalizeDeckName(name);

    final deck = await _decks.findById(deckId);
    if (deck == null) {
      throw ValidationFailure(field: 'deckId', code: 'unknown');
    }

    // Blank is absence, not an empty description: §1 makes it optional, and a
    // cleared field should read the same as one never filled in.
    final trimmed = description == null
        ? null
        : StringUtils.trimmed(description);
    await _decks.editMetadata(
      deckId,
      name: displayName,
      normalizedName: normalized,
      description: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      updatedAt: _clock.nowUtc(),
    );
  }
}

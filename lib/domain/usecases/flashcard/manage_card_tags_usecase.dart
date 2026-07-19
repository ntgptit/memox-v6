import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/flashcard/card_tag.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/flashcard/tag_label.dart';

/// Card tag management (WBS 5.3.1B; `manage-card-tags.md`
/// TAG-001..006).
///
/// Labels validate as NFC outer-trimmed display text with app-local
/// case-folded uniqueness; duplicate creation resolves to the existing
/// tag, attach is idempotent, and removing/deleting tags never mutates
/// card content beyond the version bump.
class ManageCardTagsUseCase {
  const ManageCardTagsUseCase({
    required FlashcardRepository cards,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _cards = cards,
       _idGenerator = idGenerator,
       _clock = clock;

  final FlashcardRepository _cards;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  Future<List<CardTag>> tagsOf(String cardId) => _cards.tagsOf(cardId);

  /// Attaches the tag owning [rawLabel], creating it when new; the
  /// returned tag keeps the first creator's display spelling.
  Future<CardTag> attachTagByLabel({
    required String cardId,
    required String rawLabel,
    required String newTagId,
    required DateTime now,
  }) async {
    final display = validateTagLabel(rawLabel);
    final tag = await _cards.resolveTagByLabel(
      displayName: display,
      normalizedName: normalizeTagLabel(display),
      newTagId: newTagId,
      now: now,
    );
    await _cards.attachCardTag(cardId, tagId: tag.id, now: now);
    return tag;
  }

  /// Validates and resolves labels to their owning tags (creating new
  /// ones) without attaching — create flows collect tag ids first so
  /// the card commit stays one atomic operation. Duplicate labels in
  /// the input resolve once.
  Future<List<String>> resolveTagIds(List<String> rawLabels) async {
    final ids = <String>[];
    for (final raw in rawLabels) {
      final display = validateTagLabel(raw);
      final tag = await _cards.resolveTagByLabel(
        displayName: display,
        normalizedName: normalizeTagLabel(display),
        newTagId: _idGenerator.newId(),
        now: _clock.nowUtc(),
      );
      if (!ids.contains(tag.id)) ids.add(tag.id);
    }
    return ids;
  }

  /// Removes one association (TAG-005: the card and its progress are
  /// untouched).
  Future<void> detachTag({
    required String cardId,
    required String tagId,
    required DateTime now,
  }) {
    return _cards.detachCardTag(cardId, tagId: tagId, now: now);
  }

  /// Deletes the tag only when no card uses it (TAG-006); returns
  /// whether it was deleted.
  Future<bool> deleteUnusedTag(String tagId) {
    return _cards.deleteTagIfUnused(tagId);
  }
}

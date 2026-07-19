import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// Deck-name normalization (WBS 5.2.1): sibling duplicate detection
/// compares trimmed lowercase names (`create-deck.md`), while the
/// display name keeps the user's casing.
String normalizeDeckName(String name) {
  return StringUtils.lowerCased(StringUtils.trimmed(name));
}

/// Validates a deck name draft; the trimmed display form is returned.
String validateDeckName(String raw) {
  final trimmed = StringUtils.trimmed(raw);
  if (trimmed.isEmpty) {
    throw ValidationFailure(field: 'deckName', code: 'required');
  }
  return trimmed;
}

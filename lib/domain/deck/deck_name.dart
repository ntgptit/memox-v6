import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// Deck-name normalization (WBS 5.2.1): sibling duplicate detection
/// compares trimmed lowercase names (`create-deck.md`), while the
/// display name keeps the user's casing.
String normalizeDeckName(String name) {
  return StringUtils.lowerCased(StringUtils.trimmed(name));
}

/// Validates a deck name draft; the trimmed display form is returned.
/// Longest accepted deck name, in code points.
///
/// A deck name is a short label, not prose — the kit's realistic example
/// is `Korean TOPIK I` (14). 60 keeps descriptive names comfortable while
/// staying well under the 89-character string the kit uses to illustrate
/// `create-deck-firstrun--name-too-long`, so the state stays reachable.
/// No spec or schema fixed a number; this one is chosen here and needs an
/// owner's confirmation (WBS 5.2.1, reopened 2026-07-20).
const int deckNameMaxLength = 60;

String validateDeckName(String raw) {
  final trimmed = StringUtils.trimmed(raw);
  if (trimmed.isEmpty) {
    throw ValidationFailure(field: 'deckName', code: 'required');
  }
  if (trimmed.runes.length > deckNameMaxLength) {
    throw ValidationFailure(field: 'deckName', code: 'too-long');
  }
  return trimmed;
}

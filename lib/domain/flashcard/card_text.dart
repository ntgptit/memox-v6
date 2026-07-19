import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// Card text validation and identity (WBS 5.3.1A; VAL-001).
///
/// Display text trims outer whitespace but keeps intentional internal
/// line breaks; the duplicate-candidate identity is the lowercase
/// trimmed term (`resolve-duplicate-flashcard.md`: normalized content,
/// never raw strings).

/// Trims and requires non-empty text; [field] names the offending
/// input in the typed failure. VAL-001: Unicode NFC + outer trim.
String validateCardText(String raw, {required String field}) {
  final trimmed = StringUtils.trimmed(StringUtils.nfc(raw));
  if (trimmed.isEmpty) {
    throw ValidationFailure(field: field, code: 'required');
  }
  return trimmed;
}

/// The duplicate-candidate identity of a term (and of any card text
/// compared for normalized duplicates, e.g. additional translations).
String normalizeCardTerm(String term) {
  return StringUtils.caseFolded(StringUtils.trimmed(StringUtils.nfc(term)));
}

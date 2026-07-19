import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// Card text validation and identity (WBS 5.3.1A; VAL-001).
///
/// Display text trims outer whitespace but keeps intentional internal
/// line breaks; the duplicate-candidate identity is the lowercase
/// trimmed term (`resolve-duplicate-flashcard.md`: normalized content,
/// never raw strings).

/// Trims and requires non-empty text; [field] names the offending
/// input in the typed failure.
String validateCardText(String raw, {required String field}) {
  final trimmed = StringUtils.trimmed(raw);
  if (trimmed.isEmpty) {
    throw ValidationFailure(field: field, code: 'required');
  }
  return trimmed;
}

/// The duplicate-candidate identity of a term.
String normalizeCardTerm(String term) {
  return StringUtils.lowerCased(StringUtils.trimmed(term));
}

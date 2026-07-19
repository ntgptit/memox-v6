import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// Tag label validation and identity (WBS 5.3.1B; TAG-001..003).
///
/// The display spelling keeps the user's casing and composition after
/// NFC + outer trim; uniqueness compares the case-folded normalized
/// label, so composed/decomposed Vietnamese and case variants resolve
/// to one tag.

/// Validates a tag label draft; the NFC outer-trimmed display form is
/// returned (TAG-001) and an empty normalized label is invalid
/// (TAG-002).
String validateTagLabel(String raw) {
  final display = StringUtils.trimmed(StringUtils.nfc(raw));
  if (display.isEmpty) {
    throw ValidationFailure(field: 'tagLabel', code: 'required');
  }
  return display;
}

/// The app-local uniqueness key of a label (TAG-003).
String normalizeTagLabel(String label) {
  return StringUtils.caseFolded(StringUtils.trimmed(StringUtils.nfc(label)));
}

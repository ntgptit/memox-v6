import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Central string normalization (guard
/// `memox.coding.string_normalization_via_string_utils`).
///
/// Domain and presentation code route trimming/case operations through
/// here so search, comparison and answer-matching semantics stay
/// consistent when they later become locale-aware.
abstract final class StringUtils {
  static String trimmed(String value) => value.trim();

  static String upperCased(String value) => value.toUpperCase();

  static String lowerCased(String value) => value.toLowerCase();

  /// Unicode NFC composition (VAL-001/TAG-001): composed and decomposed
  /// spellings of the same text share one canonical form.
  static String nfc(String value) => unorm.nfc(value);

  /// Case-folded comparison key. Tier 1 locales (en/vi) fold exactly
  /// through lowercase; full Unicode case folding can replace this
  /// without changing call sites.
  static String caseFolded(String value) => value.toLowerCase();
}

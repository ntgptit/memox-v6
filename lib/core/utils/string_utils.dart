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

  /// Collapse every run of (Unicode) whitespace to a single ASCII space and
  /// trim the outer edges. `\s` follows ECMAScript semantics here, so Unicode
  /// space separators collapse too.
  static String collapsedWhitespace(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// The shared v1 answer/meaning comparison key used by Match, Guess and Fill:
  /// NFC → case fold → trim + collapse internal whitespace. It keeps
  /// diacritics, punctuation and word order (no transliteration, stemming or
  /// fuzzy matching), so a normalized exact-compare is the only match.
  static String comparisonKey(String value) =>
      collapsedWhitespace(caseFolded(nfc(value)));
}

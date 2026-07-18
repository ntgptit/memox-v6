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
}

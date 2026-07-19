import 'package:memox_v6/core/utils/string_utils.dart';

/// Normalized language-pair identity (WBS 5.1.1).
///
/// The stored `normalized_pair_key` is the duplicate-detection identity
/// (`schema-v1.md`): lowercase trimmed codes joined as
/// `learning|native`, so `EN / vi` and `en/VI ` normalize to the same
/// pair and are never silently duplicated.
String buildNormalizedPairKey({
  required String learningLanguageCode,
  required String nativeLanguageCode,
}) {
  final learning = StringUtils.lowerCased(
    StringUtils.trimmed(learningLanguageCode),
  );
  final native = StringUtils.lowerCased(
    StringUtils.trimmed(nativeLanguageCode),
  );
  return '$learning|$native';
}

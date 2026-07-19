/// Language Pair domain model (WBS 4.5). No Drift dependency: mappers in
/// `lib/data/mappers` translate rows into this shape.
class LanguagePair {
  const LanguagePair({
    required this.id,
    required this.learningLanguageCode,
    required this.nativeLanguageCode,
    required this.normalizedPairKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String learningLanguageCode;
  final String nativeLanguageCode;
  final String normalizedPairKey;
  final DateTime createdAt;
  final DateTime updatedAt;
}

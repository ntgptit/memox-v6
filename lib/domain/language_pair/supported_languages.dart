/// One selectable language (WBS 5.1.1). Names are proper nouns shown in
/// their own script plus an English reference — not l10n copy.
class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  /// Lowercase ISO 639-1 code; the stored identity component.
  final String code;

  final String englishName;
  final String nativeName;
}

/// The v1 selectable-language catalog. Selection validity checks run
/// against this list; extending it is additive and needs no migration
/// (codes are stored as plain text).
const List<SupportedLanguage> supportedLanguages = [
  SupportedLanguage(code: 'en', englishName: 'English', nativeName: 'English'),
  SupportedLanguage(
    code: 'vi',
    englishName: 'Vietnamese',
    nativeName: 'Tiếng Việt',
  ),
  SupportedLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語'),
  SupportedLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어'),
  SupportedLanguage(code: 'zh', englishName: 'Chinese', nativeName: '中文'),
  SupportedLanguage(code: 'fr', englishName: 'French', nativeName: 'Français'),
  SupportedLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
  SupportedLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
  SupportedLanguage(
    code: 'pt',
    englishName: 'Portuguese',
    nativeName: 'Português',
  ),
  SupportedLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano'),
  SupportedLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский'),
  SupportedLanguage(code: 'th', englishName: 'Thai', nativeName: 'ไทย'),
];

/// Whether [code] (already normalized) is selectable in v1.
bool isSupportedLanguageCode(String code) {
  return supportedLanguages.any((language) => language.code == code);
}

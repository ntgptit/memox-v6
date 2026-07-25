import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/supported_languages.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_language_provider.g.dart';

/// The language names behind a study session's deck.
///
/// The kit states the rule for every mode screen: "Language labels are
/// DECK-DRIVEN (never hard-coded) so every language pair reads correctly."
/// Fill asks the learner to type the term, and the kit's prompt names the
/// language doing the asking — "Type the term (Korean)", "Type the Korean
/// word…" — because "Type your answer" leaves a learner with two active pairs
/// guessing which script is wanted.
///
/// `StudyRuntimeState` carries the session, its stages and its card
/// snapshots, but no language identity: a snapshot is term and meaning text,
/// deliberately frozen at start. So the names are resolved here from the
/// session's deck, the same way `cardEditorContext` resolves them for the
/// editor.
class StudyLanguageContext {
  const StudyLanguageContext({
    required this.termLanguageName,
    required this.meaningLanguageName,
  });

  /// Empty when the deck or pair cannot be resolved — callers fall back to
  /// the unqualified copy rather than rendering an empty parenthesis.
  final String termLanguageName;
  final String meaningLanguageName;

  bool get hasTermLanguage => termLanguageName.isNotEmpty;
}

@riverpod
Future<StudyLanguageContext> studyLanguageContext(
  Ref ref, {
  required String deckId,
}) async {
  final deck = await ref.watch(openDeckUseCaseProvider).deckById(deckId);
  if (deck == null) {
    return const StudyLanguageContext(
      termLanguageName: '',
      meaningLanguageName: '',
    );
  }
  final pair = await ref
      .watch(selectLanguagePairUseCaseProvider)
      .pairById(deck.languagePairId);
  return StudyLanguageContext(
    termLanguageName: _languageNameOf(pair, learning: true),
    meaningLanguageName: _languageNameOf(pair, learning: false),
  );
}

String _languageNameOf(LanguagePair? pair, {required bool learning}) {
  if (pair == null) return '';
  final code = learning ? pair.learningLanguageCode : pair.nativeLanguageCode;
  for (final language in supportedLanguages) {
    if (language.code == code) return language.nativeName;
  }
  return code;
}

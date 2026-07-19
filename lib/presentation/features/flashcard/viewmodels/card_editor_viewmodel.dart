import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/supported_languages.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_editor_viewmodel.g.dart';

/// Card Editor context (WBS 5.3.2A): the target deck plus its pair's
/// deck-driven language labels (`create-flashcard.md`: labels come
/// from the pair, never hard-coded).
class CardEditorContext {
  const CardEditorContext({
    required this.deck,
    required this.termLanguageName,
    required this.meaningLanguageName,
  });

  final Deck deck;
  final String termLanguageName;
  final String meaningLanguageName;
}

@riverpod
Future<CardEditorContext?> cardEditorContext(
  Ref ref, {
  required String deckId,
}) async {
  final deck = await ref.watch(openDeckUseCaseProvider).deckById(deckId);
  if (deck == null) return null;
  final pair = await ref
      .watch(selectLanguagePairUseCaseProvider)
      .pairById(deck.languagePairId);
  return CardEditorContext(
    deck: deck,
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

/// Save action (create mode): resolves tag labels to ids first so the
/// card + children + Box 0 progress commit as atomic operation 1.
@riverpod
class CardEditorSaveViewmodel extends _$CardEditorSaveViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createFlashcard({
    required String deckId,
    required String term,
    required String primaryMeaning,
    required List<String> rawTagLabels,
    bool allowDuplicate = false,
  }) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final tagIds = await ref
          .read(manageCardTagsUseCaseProvider)
          .resolveTagIds(rawTagLabels);

      final result = await ref
          .read(createFlashcardUseCaseProvider)
          .call(
            deckId: deckId,
            term: term,
            primaryMeaning: primaryMeaning,
            allowDuplicate: allowDuplicate,
            tagIds: tagIds,
          );
      // Duplicate review UI is child B scope; until it lands the
      // candidates surface as a typed conflict for the error banner.
      if (result is DuplicateCandidatesFound) {
        throw ConflictFailure(
          entity: 'flashcards',
          code: 'duplicate-review-pending',
        );
      }
    });
  }

  void reset() => state = const AsyncData(null);
}

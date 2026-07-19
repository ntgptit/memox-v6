import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/flashcard/create_flashcard_result.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
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
      // Candidates are a review decision, not an error: the banner
      // surface owns them (resolve-duplicate-flashcard.md).
      if (result is DuplicateCandidatesFound) {
        ref
            .read(cardEditorDuplicatesViewmodelProvider.notifier)
            .show(result.candidates);
        return;
      }
      ref.read(cardEditorDuplicatesViewmodelProvider.notifier).clear();
      ref.read(cardEditorSavedTickViewmodelProvider.notifier).bump();
    });
  }

  void reset() => state = const AsyncData(null);
}

/// Duplicate candidates awaiting the user's review decision; null when
/// no review is pending (kit DupBanner entry point).
@riverpod
class CardEditorDuplicatesViewmodel extends _$CardEditorDuplicatesViewmodel {
  @override
  List<Flashcard>? build() => null;

  void show(List<Flashcard> candidates) => state = candidates;

  void clear() => state = null;
}

/// Increments once per committed save so the screen can distinguish a
/// real success from a duplicate-review pause (both settle AsyncData).
@riverpod
class CardEditorSavedTickViewmodel extends _$CardEditorSavedTickViewmodel {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

/// Whether the editor draft diverged from blank (dirty-cancel guard:
/// kit KIT-25-06 — Cancel/back confirm before discarding a dirty draft).
@riverpod
class CardEditorDirtyViewmodel extends _$CardEditorDirtyViewmodel {
  @override
  bool build() => false;

  void set({required bool dirty}) => state = dirty;
}

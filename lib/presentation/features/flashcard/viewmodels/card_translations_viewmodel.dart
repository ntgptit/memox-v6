import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_translations_viewmodel.g.dart';

/// The card's additional translations, in their stored order (WBS 6.4;
/// `manage-card-translations.md`). One-shot read — a mutation invalidates it.
@riverpod
Future<List<CardTranslation>> cardTranslations(
  Ref ref, {
  required String cardId,
}) {
  return ref
      .watch(manageCardTranslationsUseCaseProvider)
      .translationsOf(cardId);
}

/// Add/remove commands for a card's additional translations (WBS 6.4). Each
/// mutation persists immediately with the card's content-version bump (the
/// card already exists in edit mode), then refreshes [cardTranslationsProvider].
/// Blank/duplicate text is rejected by the use case and surfaces as the typed
/// failure the caller shows.
@riverpod
class CardTranslationsCommandViewmodel
    extends _$CardTranslationsCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> addTranslation({
    required String cardId,
    required String languageCode,
    required String text,
  }) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref
          .read(manageCardTranslationsUseCaseProvider)
          .addTranslation(
            translationId: ref.read(idGeneratorProvider).newId(),
            cardId: cardId,
            languageCode: languageCode,
            rawText: text,
            now: ref.read(appClockProvider).nowUtc(),
          );
    });
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(cardTranslationsProvider(cardId: cardId));
    }
  }

  Future<void> removeTranslation({
    required String cardId,
    required String translationId,
  }) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref
          .read(manageCardTranslationsUseCaseProvider)
          .removeTranslation(
            translationId: translationId,
            cardId: cardId,
            now: ref.read(appClockProvider).nowUtc(),
          );
    });
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(cardTranslationsProvider(cardId: cardId));
    }
  }
}

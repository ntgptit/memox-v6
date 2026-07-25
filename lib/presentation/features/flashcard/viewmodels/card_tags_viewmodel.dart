import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/flashcard/card_tag.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_tags_viewmodel.g.dart';

/// The card's attached tags (WBS 6.4; `manage-card-tags.md`). One-shot read —
/// a mutation invalidates it.
@riverpod
Future<List<CardTag>> cardTags(Ref ref, {required String cardId}) {
  return ref.watch(manageCardTagsUseCaseProvider).tagsOf(cardId);
}

/// Attach/detach commands for a card's tags (WBS 6.4). Add resolves the label
/// to a tag (creating it if new) and attaches it; remove detaches and deletes
/// the tag when no card still uses it (TAG-006). Each mutation persists
/// immediately with the card's content-version bump, then refreshes the list.
@riverpod
class CardTagsCommandViewmodel extends _$CardTagsCommandViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> addTag({required String cardId, required String label}) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      await ref
          .read(manageCardTagsUseCaseProvider)
          .attachTagByLabel(
            cardId: cardId,
            rawLabel: label,
            newTagId: ref.read(idGeneratorProvider).newId(),
            now: ref.read(appClockProvider).nowUtc(),
          );
    });
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(cardTagsProvider(cardId: cardId));
    }
  }

  Future<void> removeTag({
    required String cardId,
    required String tagId,
  }) async {
    state = const AsyncLoading<void>();
    final result = await runMxAction(() async {
      final useCase = ref.read(manageCardTagsUseCaseProvider);
      await useCase.detachTag(
        cardId: cardId,
        tagId: tagId,
        now: ref.read(appClockProvider).nowUtc(),
      );
      await useCase.deleteUnusedTag(tagId);
    });
    state = result;
    if (result is! AsyncError) {
      ref.invalidate(cardTagsProvider(cardId: cardId));
    }
  }
}

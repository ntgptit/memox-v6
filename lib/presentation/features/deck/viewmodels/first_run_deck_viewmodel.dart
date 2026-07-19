import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/library_viewmodel.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'first_run_deck_viewmodel.g.dart';

/// Step-2 state and command of the first-run setup (WBS 5.2.3B).

/// The pair chosen in step 1, resolved for the summary row.
@riverpod
Future<LanguagePair?> firstRunActivePair(Ref ref) {
  return ref.watch(selectLanguagePairUseCaseProvider).activePair();
}

/// Deck draft kept across steps: navigating back to step 1 ("Change")
/// and returning must not lose the entered name/description
/// (`create-deck.md` draft rule) — hence keep-alive by design, cleared
/// explicitly after a successful create.
typedef FirstRunDeckDraft = ({
  String name,
  String description,
  String? retryDeckId,
});

@Riverpod(keepAlive: true)
class FirstRunDeckDraftViewmodel extends _$FirstRunDeckDraftViewmodel {
  @override
  FirstRunDeckDraft build() {
    return (name: '', description: '', retryDeckId: null);
  }

  void setDeckName(String value) {
    state = (
      name: value,
      description: state.description,
      retryDeckId: state.retryDeckId,
    );
  }

  void setDeckDescription(String value) {
    state = (
      name: state.name,
      description: value,
      retryDeckId: state.retryDeckId,
    );
  }

  /// The stable id reused across submit retries (kept-id idempotency).
  String ensureRetryDeckId() {
    final existing = state.retryDeckId;
    if (existing != null) return existing;
    final generated = ref.read(idGeneratorProvider).newId();
    state = (
      name: state.name,
      description: state.description,
      retryDeckId: generated,
    );
    return generated;
  }

  void clearDraft() {
    state = (name: '', description: '', retryDeckId: null);
  }
}

/// Submit command: creates the first deck from the draft through
/// `CreateDeckUseCase` and clears the draft on success.
@riverpod
class CreateFirstDeckViewmodel extends _$CreateFirstDeckViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createDeck() async {
    if (state is AsyncLoading<void>) return;
    final draftNotifier = ref.read(firstRunDeckDraftViewmodelProvider.notifier);
    final draft = ref.read(firstRunDeckDraftViewmodelProvider);
    final retryDeckId = draftNotifier.ensureRetryDeckId();

    state = const AsyncLoading();
    state = await runMxAction(() async {
      final pair = await ref
          .read(selectLanguagePairUseCaseProvider)
          .activePair();
      if (pair == null) {
        // Step 1 was skipped or its pair vanished; the flow returns
        // there instead of guessing a pair.
        throw StateError('first-run deck setup without an active pair');
      }
      final deck = await ref.read(createDeckUseCaseProvider)(
        name: draft.name,
        languagePairId: pair.id,
        retryDeckId: retryDeckId,
        description: draft.description,
      );
      draftNotifier.clearDraft();
      // Success lands in the Library with this deck highlighted and the
      // contextual callout (create-deck.md §7).
      ref.read(firstDeckCalloutViewmodelProvider.notifier).showForDeck(deck.id);
    });
  }
}

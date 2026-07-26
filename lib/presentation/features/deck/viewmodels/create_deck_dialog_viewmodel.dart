import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_deck_dialog_viewmodel.g.dart';

/// Submit command of the standard create-deck dialog (WBS 5.2.4C).
///
/// Root creates use the active pair; nested creates inherit the
/// parent's pair (resolved from the parent row, so the store's
/// pair-mismatch trigger can never fire from this path).
@riverpod
class CreateDeckDialogViewmodel extends _$CreateDeckDialogViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// The deck the last successful submit created, for the confirmation's
  /// `Open` action (`create-deck.md`). Kept beside the command state rather
  /// than inside it: the shared runner's contract is `AsyncValue<void>`, and
  /// widening it for one caller would change every command in the app.
  String? lastCreatedDeckId;

  Future<void> createDeck({
    required String name,
    required String? parentDeckId,
  }) async {
    if (state is AsyncLoading<void>) return;
    state = const AsyncLoading();
    state = await runMxAction(() async {
      final pairId = await _resolvePairId(parentDeckId);
      final deck = await ref.read(createDeckUseCaseProvider)(
        name: name,
        languagePairId: pairId,
        parentId: parentDeckId,
      );
      lastCreatedDeckId = deck.id;
    });
  }

  Future<String> _resolvePairId(String? parentDeckId) async {
    if (parentDeckId != null) {
      final parent = await ref
          .read(openDeckUseCaseProvider)
          .deckById(parentDeckId);
      if (parent == null) {
        throw ValidationFailure(field: 'parentId', code: 'unknown');
      }
      return parent.languagePairId;
    }
    final pair = await ref.read(selectLanguagePairUseCaseProvider).activePair();
    if (pair == null) {
      throw ValidationFailure(field: 'languagePairId', code: 'unknown');
    }
    return pair.id;
  }
}

import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'first_run_language_viewmodel.g.dart';

/// First-run language selection state and command (WBS 5.1.2).

/// The two-selection draft. Held in provider state so a failed save
/// keeps both selections, and keep-alive so "Change" from step 2 comes
/// back to the previous selections (`create-deck.md` draft rule).
typedef FirstRunLanguageDraft = ({String? learningCode, String? nativeCode});

@Riverpod(keepAlive: true)
class FirstRunLanguageDraftViewmodel extends _$FirstRunLanguageDraftViewmodel {
  @override
  FirstRunLanguageDraft build() {
    return (learningCode: null, nativeCode: null);
  }

  void setLearningLanguage(String code) {
    state = (learningCode: code, nativeCode: state.nativeCode);
  }

  void setMeaningLanguage(String code) {
    state = (learningCode: state.learningCode, nativeCode: code);
  }

  bool get isComplete => state.learningCode != null && state.nativeCode != null;

  /// True once both selections are set and identical — a distinct pair is
  /// required, so this is prevented before submit rather than surfaced as
  /// a save failure (`create-language-pair.md` §5).
  bool get isSameLanguage =>
      state.learningCode != null && state.learningCode == state.nativeCode;
}

/// Save command: create (or adopt the existing duplicate — never a
/// silent copy) and persist the selection as the active pair.
@riverpod
class SaveLanguagePairViewmodel extends _$SaveLanguagePairViewmodel {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Retires a superseded failure so a banner from a past attempt does not
  /// outlive the draft change that corrects it.
  void reset() {
    if (state is AsyncData<void>) return;
    state = const AsyncData(null);
  }

  Future<void> saveLanguagePair() async {
    final draft = ref.read(firstRunLanguageDraftViewmodelProvider);
    final learning = draft.learningCode;
    final native = draft.nativeCode;
    if (learning == null || native == null) return;
    if (state is AsyncLoading<void>) return;

    state = const AsyncLoading();
    state = await runMxAction(() async {
      final create = ref.read(createLanguagePairUseCaseProvider);
      final select = ref.read(selectLanguagePairUseCaseProvider);
      final result = await create(
        learningLanguageCode: learning,
        nativeLanguageCode: native,
      );
      await select(result.pair.id);
    });
  }
}

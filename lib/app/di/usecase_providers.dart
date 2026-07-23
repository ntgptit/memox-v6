import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_candidates_usecase.dart';
import 'package:memox_v6/app/di/study_mode_providers.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/initialise_card_progress_usecase.dart';
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/open_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/watch_library_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/create_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/delete_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/edit_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/hide_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/move_flashcard_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_audio_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_tags_usecase.dart';
import 'package:memox_v6/domain/usecases/flashcard/manage_card_translations_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/create_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/onboarding/dismiss_first_run_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/remove_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'usecase_providers.g.dart';

/// Use-case providers (WBS 5.1.2+): the only place feature viewmodels
/// obtain domain use cases — features never touch repository providers
/// directly (guard `no_direct_infrastructure_access`).

@riverpod
CreateLanguagePairUseCase createLanguagePairUseCase(Ref ref) {
  return CreateLanguagePairUseCase(
    repository: ref.watch(languagePairRepositoryProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
SelectLanguagePairUseCase selectLanguagePairUseCase(Ref ref) {
  return SelectLanguagePairUseCase(
    pairs: ref.watch(languagePairRepositoryProvider),
    preferences: ref.watch(preferenceRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
RemoveLanguagePairUseCase removeLanguagePairUseCase(Ref ref) {
  return RemoveLanguagePairUseCase(
    pairs: ref.watch(languagePairRepositoryProvider),
    decks: ref.watch(deckRepositoryProvider),
    preferences: ref.watch(preferenceRepositoryProvider),
  );
}

@riverpod
CreateDeckUseCase createDeckUseCase(Ref ref) {
  return CreateDeckUseCase(
    decks: ref.watch(deckRepositoryProvider),
    pairs: ref.watch(languagePairRepositoryProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
DismissFirstRunUseCase dismissFirstRunUseCase(Ref ref) {
  return DismissFirstRunUseCase(
    preferences: ref.watch(preferenceRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
WatchLibraryUseCase watchLibraryUseCase(Ref ref) {
  return WatchLibraryUseCase(decks: ref.watch(deckRepositoryProvider));
}

@riverpod
OpenDeckUseCase openDeckUseCase(Ref ref) {
  return OpenDeckUseCase(
    decks: ref.watch(deckRepositoryProvider),
    cards: ref.watch(flashcardRepositoryProvider),
  );
}

@riverpod
CreateFlashcardUseCase createFlashcardUseCase(Ref ref) {
  return CreateFlashcardUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
    decks: ref.watch(deckRepositoryProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
ManageCardTranslationsUseCase manageCardTranslationsUseCase(Ref ref) {
  return ManageCardTranslationsUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
  );
}

@riverpod
ManageCardTagsUseCase manageCardTagsUseCase(Ref ref) {
  return ManageCardTagsUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
ManageCardAudioUseCase manageCardAudioUseCase(Ref ref) {
  return ManageCardAudioUseCase(cards: ref.watch(flashcardRepositoryProvider));
}

@riverpod
EditFlashcardUseCase editFlashcardUseCase(Ref ref) {
  return EditFlashcardUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
    decks: ref.watch(deckRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
HideFlashcardUseCase hideFlashcardUseCase(Ref ref) {
  return HideFlashcardUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
DeleteFlashcardUseCase deleteFlashcardUseCase(Ref ref) {
  return DeleteFlashcardUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
MoveFlashcardUseCase moveFlashcardUseCase(Ref ref) {
  return MoveFlashcardUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
    decks: ref.watch(deckRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
InitialiseCardProgressUseCase initialiseCardProgressUseCase(Ref ref) {
  return InitialiseCardProgressUseCase(
    repository: ref.watch(learningProgressRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
LoadStudyCandidatesUseCase loadStudyCandidatesUseCase(Ref ref) {
  return LoadStudyCandidatesUseCase(
    repository: ref.watch(learningProgressRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
ApplyTerminalOutcomeUseCase applyTerminalOutcomeUseCase(Ref ref) {
  return ApplyTerminalOutcomeUseCase(
    repository: ref.watch(learningProgressRepositoryProvider),
  );
}

@riverpod
FinalizeStudySessionUseCase finalizeStudySessionUseCase(Ref ref) {
  return FinalizeStudySessionUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
    progress: ref.watch(learningProgressRepositoryProvider),
    applyTerminalOutcome: ref.watch(applyTerminalOutcomeUseCaseProvider),
    clock: ref.watch(appClockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
}

@riverpod
StartStudySessionUseCase startStudySessionUseCase(Ref ref) {
  return StartStudySessionUseCase(
    progress: ref.watch(learningProgressRepositoryProvider),
    cards: ref.watch(flashcardRepositoryProvider),
    sessions: ref.watch(studySessionRepositoryProvider),
    clock: ref.watch(appClockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
}

@riverpod
AnswerStudyStageUseCase answerStudyStageUseCase(Ref ref) {
  return AnswerStudyStageUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
    factory: ref.watch(studyModeFactoryProvider),
    clock: ref.watch(appClockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
}

@riverpod
LoadStudyRuntimeUseCase loadStudyRuntimeUseCase(Ref ref) {
  return LoadStudyRuntimeUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
  );
}

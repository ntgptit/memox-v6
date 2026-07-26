import 'package:memox_v6/domain/usecases/learning_progress/apply_terminal_outcome_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_candidates_usecase.dart';
import 'package:memox_v6/app/di/study_mode_providers.dart';
import 'package:memox_v6/domain/usecases/study_session/answer_study_stage_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/finalize_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/pause_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/skip_unavailable_card_usecase.dart';
import 'package:memox_v6/domain/usecases/today/load_today_projection_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';
import 'package:memox_v6/domain/usecases/today/continue_session_from_today_usecase.dart';
import 'package:memox_v6/domain/usecases/today/resolve_add_card_target_usecase.dart';
import 'package:memox_v6/domain/usecases/today/start_review_from_today_usecase.dart';
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/delete_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/load_deck_deletion_impact_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/load_reset_progress_availability_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/move_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/rename_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/reset_deck_progress_usecase.dart';
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
import 'package:memox_v6/domain/usecases/learning_progress/initialise_card_progress_usecase.dart';
import 'package:memox_v6/domain/usecases/learning_progress/load_study_queue_counts_usecase.dart';
import 'package:memox_v6/domain/usecases/onboarding/dismiss_first_run_usecase.dart';
import 'package:memox_v6/domain/usecases/preferences/restore_default_preferences_usecase.dart';
import 'package:memox_v6/domain/usecases/search/recent_searches_usecase.dart';
import 'package:memox_v6/domain/usecases/search/search_library_usecase.dart';
import 'package:memox_v6/domain/usecases/preferences/set_appearance_preference_usecase.dart';
import 'package:memox_v6/domain/usecases/preferences/set_mode_preferences_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/remove_language_pair_usecase.dart';
import 'package:memox_v6/domain/usecases/language_pair/select_language_pair_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memox_v6/domain/usecases/study_streak/record_streak_day_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/track_daily_goal_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/load_daily_progress_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/set_daily_study_goal_usecase.dart';
import 'package:memox_v6/domain/usecases/study_goal/load_daily_goal_usecase.dart';

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
SetAppearancePreferenceUseCase setAppearancePreferenceUseCase(Ref ref) {
  return SetAppearancePreferenceUseCase(
    preferences: ref.watch(preferenceRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
SetModePreferencesUseCase setModePreferencesUseCase(Ref ref) {
  return SetModePreferencesUseCase(
    preferences: ref.watch(preferenceRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
RestoreDefaultPreferencesUseCase restoreDefaultPreferencesUseCase(Ref ref) {
  return RestoreDefaultPreferencesUseCase(
    preferences: ref.watch(preferenceRepositoryProvider),
  );
}

@riverpod
SearchLibraryUseCase searchLibraryUseCase(Ref ref) {
  return SearchLibraryUseCase(search: ref.watch(searchRepositoryProvider));
}

@riverpod
RecentSearchesUseCase recentSearchesUseCase(Ref ref) {
  return RecentSearchesUseCase(
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
RenameDeckUseCase renameDeckUseCase(Ref ref) {
  return RenameDeckUseCase(
    decks: ref.watch(deckRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
DeleteDeckUseCase deleteDeckUseCase(Ref ref) {
  return DeleteDeckUseCase(decks: ref.watch(deckRepositoryProvider));
}

@riverpod
LoadDeckDeletionImpactUseCase loadDeckDeletionImpactUseCase(Ref ref) {
  return LoadDeckDeletionImpactUseCase(
    decks: ref.watch(deckRepositoryProvider),
  );
}

@riverpod
LoadResetProgressAvailabilityUseCase loadResetProgressAvailabilityUseCase(
  Ref ref,
) {
  return LoadResetProgressAvailabilityUseCase(
    decks: ref.watch(deckRepositoryProvider),
    sessions: ref.watch(studySessionRepositoryProvider),
  );
}

@riverpod
ResetDeckProgressUseCase resetDeckProgressUseCase(Ref ref) {
  return ResetDeckProgressUseCase(
    progress: ref.watch(learningProgressRepositoryProvider),
    availability: ref.watch(loadResetProgressAvailabilityUseCaseProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
MoveDeckUseCase moveDeckUseCase(Ref ref) {
  return MoveDeckUseCase(
    decks: ref.watch(deckRepositoryProvider),
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
InitialiseCardProgressUseCase initialiseCardProgressUseCase(Ref ref) {
  return InitialiseCardProgressUseCase(
    cards: ref.watch(flashcardRepositoryProvider),
    progress: ref.watch(learningProgressRepositoryProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
LoadStudyQueueCountsUseCase loadStudyQueueCountsUseCase(Ref ref) {
  return LoadStudyQueueCountsUseCase(
    progress: ref.watch(learningProgressRepositoryProvider),
    decks: ref.watch(deckRepositoryProvider),
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
    runtime: ref.watch(loadStudyRuntimeUseCaseProvider),
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
LoadTodayProjectionUseCase loadTodayProjectionUseCase(Ref ref) {
  return LoadTodayProjectionUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
    decks: ref.watch(deckRepositoryProvider),
    languagePairs: ref.watch(selectLanguagePairUseCaseProvider),
    dailyProgress: ref.watch(loadDailyProgressUseCaseProvider),
    queueCounts: ref.watch(loadStudyQueueCountsUseCaseProvider),
  );
}

@riverpod
SkipUnavailableCardUseCase skipUnavailableCardUseCase(Ref ref) {
  return SkipUnavailableCardUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
    cards: ref.watch(flashcardRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
PauseStudySessionUseCase pauseStudySessionUseCase(Ref ref) {
  return PauseStudySessionUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
    clock: ref.watch(appClockProvider),
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
    recordStreakDay: ref.watch(recordStreakDayUseCaseProvider),
    trackDailyGoal: ref.watch(trackDailyGoalUseCaseProvider),
    streaks: ref.watch(streakRepositoryProvider),
    timeZone: ref.watch(appTimeZoneProvider),
  );
}

/// Aggregates a finalized session's qualified cards into the day's goal bucket
/// (`track-daily-goal.md`).
@riverpod
LoadDailyGoalUseCase loadDailyGoalUseCase(Ref ref) {
  return LoadDailyGoalUseCase(goals: ref.watch(studyGoalRepositoryProvider));
}

@riverpod
SetDailyStudyGoalUseCase setDailyStudyGoalUseCase(Ref ref) {
  return SetDailyStudyGoalUseCase(
    goals: ref.watch(studyGoalRepositoryProvider),
    timeZone: ref.watch(appTimeZoneProvider),
    clock: ref.watch(appClockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
}

@riverpod
LoadDailyProgressUseCase loadDailyProgressUseCase(Ref ref) {
  return LoadDailyProgressUseCase(
    streaks: ref.watch(streakRepositoryProvider),
    goals: ref.watch(studyGoalRepositoryProvider),
    timeZone: ref.watch(appTimeZoneProvider),
    clock: ref.watch(appClockProvider),
  );
}

@riverpod
TrackDailyGoalUseCase trackDailyGoalUseCase(Ref ref) {
  return TrackDailyGoalUseCase(
    goals: ref.watch(studyGoalRepositoryProvider),
    timeZone: ref.watch(appTimeZoneProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
}

/// Marks the local day a finalized qualifying session contributed to
/// (`record-streak-day.md`).
@riverpod
RecordStreakDayUseCase recordStreakDayUseCase(Ref ref) {
  return RecordStreakDayUseCase(
    streaks: ref.watch(streakRepositoryProvider),
    timeZone: ref.watch(appTimeZoneProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
}

/// Resolves where a card created from Today would go
/// (`manage-today-create-actions.md` §2 node C).
@riverpod
ResolveAddCardTargetUseCase resolveAddCardTargetUseCase(Ref ref) {
  return ResolveAddCardTargetUseCase(
    decks: ref.watch(deckRepositoryProvider),
    languagePairs: ref.watch(selectLanguagePairUseCaseProvider),
  );
}

/// Revalidates Today's paused session before handing off to it
/// (`continue-session-from-today.md`).
@riverpod
ContinueSessionFromTodayUseCase continueSessionFromTodayUseCase(Ref ref) {
  return ContinueSessionFromTodayUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
  );
}

/// Revalidates Today's due projection and hands off to the session
/// (`start-review-from-today.md`).
@riverpod
StartReviewFromTodayUseCase startReviewFromTodayUseCase(Ref ref) {
  return StartReviewFromTodayUseCase(
    sessions: ref.watch(studySessionRepositoryProvider),
    decks: ref.watch(deckRepositoryProvider),
    languagePairs: ref.watch(selectLanguagePairUseCaseProvider),
    queueCounts: ref.watch(loadStudyQueueCountsUseCaseProvider),
    startSession: ref.watch(startStudySessionUseCaseProvider),
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

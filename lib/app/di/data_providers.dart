import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/data/database/app_database.dart';
import 'package:memox_v6/data/repositories/drift_deck_repository.dart';
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_language_pair_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_preference_repository.dart';
import 'package:memox_v6/data/repositories/drift_streak_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_goal_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/deck/deck_repository.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';
import 'package:memox_v6/domain/study_goal/study_goal_repository.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/study_streak/streak_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_providers.g.dart';

/// Data-layer DI graph (WBS 4.8): the shared database and the eight
/// repository ports, all keep-alive per the Riverpod foundation
/// contract.
///
/// Providers expose the **domain ports** — widgets never touch these
/// directly (guard) and DAOs stay data-layer internal, reachable only
/// through repositories by design. Tests override
/// [appDatabaseProvider] with an in-memory instance and the whole
/// graph follows.

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
}

@Riverpod(keepAlive: true)
LanguagePairRepository languagePairRepository(Ref ref) {
  return DriftLanguagePairRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
DeckRepository deckRepository(Ref ref) {
  return DriftDeckRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(appClockProvider),
  );
}

@Riverpod(keepAlive: true)
FlashcardRepository flashcardRepository(Ref ref) {
  return DriftFlashcardRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
LearningProgressRepository learningProgressRepository(Ref ref) {
  return DriftLearningProgressRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
PreferenceRepository preferenceRepository(Ref ref) {
  return DriftPreferenceRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
StudyGoalRepository studyGoalRepository(Ref ref) {
  return DriftStudyGoalRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
StreakRepository streakRepository(Ref ref) {
  return DriftStreakRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
StudySessionRepository studySessionRepository(Ref ref) {
  return DriftStudySessionRepository(ref.watch(appDatabaseProvider));
}

/// Startup fail-fast warm-up of the DI graph (WBS 4.8).
///
/// Reads every infrastructure provider once and probes the database so
/// a miswired graph or a failed open/migration surfaces at launch
/// inside the bootstrap error zone — not lazily on the first screen
/// that happens to need it.
Future<void> warmUpDiGraph(ProviderContainer container) async {
  container.read(appClockProvider);
  container.read(idGeneratorProvider);
  container.read(languagePairRepositoryProvider);
  container.read(deckRepositoryProvider);
  container.read(flashcardRepositoryProvider);
  container.read(learningProgressRepositoryProvider);
  container.read(preferenceRepositoryProvider);
  container.read(studyGoalRepositoryProvider);
  container.read(streakRepositoryProvider);
  container.read(studySessionRepositoryProvider);

  await container.read(appDatabaseProvider).probeConnection();
}

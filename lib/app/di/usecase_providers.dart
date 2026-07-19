import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/open_deck_usecase.dart';
import 'package:memox_v6/domain/usecases/deck/watch_library_usecase.dart';
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

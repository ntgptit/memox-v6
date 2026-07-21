import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/deck_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_viewmodel.g.dart';

/// Library root state (WBS 5.2.4A).

/// Root decks of the active language pair, reactive: creates/renames/
/// moves re-emit through the repository stream. No active pair yields
/// an empty library.
@riverpod
Stream<List<DeckSummary>> libraryRootDecks(Ref ref) async* {
  final pair = await ref.watch(selectLanguagePairUseCaseProvider).activePair();
  if (pair == null) {
    yield const <DeckSummary>[];
    return;
  }
  yield* ref.watch(watchLibraryUseCaseProvider).rootSummariesOf(pair.id);
}

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

/// Deck-list ordering (kit FilterRow sort chip).
enum LibrarySort { az, za }

/// Deck-list status filter (kit FilterRow filters chip), keyed off the
/// per-deck due/new counters.
enum LibraryStatusFilter { all, due, isNew }

/// The Library controls row state — sort order and status filter — held
/// separately from the reactive deck stream so toggling never re-queries.
@riverpod
class LibraryControlsViewmodel extends _$LibraryControlsViewmodel {
  @override
  ({LibrarySort sort, LibraryStatusFilter status}) build() =>
      (sort: LibrarySort.az, status: LibraryStatusFilter.all);

  void toggleSort() => state = (
    sort: state.sort == LibrarySort.az ? LibrarySort.za : LibrarySort.az,
    status: state.status,
  );

  void setStatus(LibraryStatusFilter status) =>
      state = (sort: state.sort, status: status);
}

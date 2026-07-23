import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';

/// Resets the learning progress of every card in a deck's subtree (WBS 6.1;
/// `reset-deck-progress.md`).
///
/// Command only — the confirm dialog shows the affected-card impact first
/// (irreversible). The store applies the reset atomically (no partial reset,
/// §1); only SRS progress changes, never content or hierarchy, and no session
/// is started. Returns the number of cards reset (0 for an empty scope).
class ResetDeckProgressUseCase {
  const ResetDeckProgressUseCase({
    required LearningProgressRepository progress,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _progress = progress,
       _idGenerator = idGenerator,
       _clock = clock;

  final LearningProgressRepository _progress;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  Future<int> call(String deckId) {
    return _progress.resetSubtreeProgress(
      deckId,
      idGenerator: _idGenerator,
      at: _clock.nowUtc(),
    );
  }
}

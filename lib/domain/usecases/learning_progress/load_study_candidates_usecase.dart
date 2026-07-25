import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/domain/learning_progress/learning_progress_repository.dart';
import 'package:memox_v6/domain/learning_progress/study_candidates.dart';

/// Loads the due + new study queues for a deck scope (WBS 5.4.2;
/// `surface-due-cards.md`).
///
/// Read-only: it classifies the scope's cards against the injected clock and
/// never mutates progress. [newLimit], when given, caps how many new cards are
/// introduced (the effective Study-policy daily limit lives in preferences,
/// not here); the due queue is never capped.
class LoadStudyCandidatesUseCase {
  const LoadStudyCandidatesUseCase({
    required LearningProgressRepository repository,
    required AppClock clock,
  }) : _repository = repository,
       _clock = clock;

  final LearningProgressRepository _repository;
  final AppClock _clock;

  Future<StudyCandidates> call(String scopeDeckId, {int? newLimit}) async {
    final all = await _repository.studyCandidatesInScope(
      scopeDeckId: scopeDeckId,
      nowUtc: _clock.nowUtc(),
    );
    if (newLimit == null) return all;
    return StudyCandidates(
      dueCardIds: all.dueCardIds,
      newCardIds: all.newCardIds.take(newLimit).toList(),
    );
  }
}

import 'package:memox_v6/core/random/deterministic_random.dart';
import 'package:memox_v6/domain/study_modes/match_round.dart';
import 'package:memox_v6/domain/study_modes/mode_outcome.dart';
import 'package:memox_v6/domain/study_modes/round_order_policy.dart';
import 'package:memox_v6/domain/study_modes/strategies/match_study_mode_strategy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'match_board_notifier.g.dart';

/// A meaning tile derived for the shuffle so the seeded reorder never leaks the
/// pairing (each carries only its owner card id + shown meaning).
const String _meaningShuffleModeId = 'match-meanings';

/// A left-column term tile (the mastery key) plus its own correct meaning (used
/// to build the [MatchInput] and to classify a pairing).
class MatchTermTile {
  const MatchTermTile({
    required this.cardId,
    required this.term,
    required this.meaning,
  });

  final String cardId;
  final String term;
  final String meaning;
}

/// A right-column meaning tile carrying its owner card id (the pair id).
class MatchMeaningTile {
  const MatchMeaningTile({required this.cardId, required this.meaning});

  final String cardId;
  final String meaning;
}

/// The stored first failing pick for a lapsed card, so the end-of-round flush
/// can rebuild a [MatchInput] the strategy re-derives to the same outcome.
typedef MatchLapsePick = ({String meaningCardId, String meaning});

/// The ephemeral Match board (WBS 5.6.6). It is a pure projection of the current
/// round plus the learner's in-progress pairings — it persists nothing, so a
/// mid-board app kill restarts the board on resume (durable resume is 5.6.12).
class MatchBoardState {
  const MatchBoardState({
    required this.sessionId,
    required this.roundIndex,
    required this.terms,
    required this.meanings,
    required this.round,
    required this.selectedTermId,
    required this.flashCardId,
    required this.flashMeaningId,
    required this.flashOutcome,
    required this.lapsePicks,
  });

  const MatchBoardState.empty()
    : sessionId = '',
      roundIndex = 0,
      terms = const <MatchTermTile>[],
      meanings = const <MatchMeaningTile>[],
      round = const MatchRound.empty(),
      selectedTermId = null,
      flashCardId = null,
      flashMeaningId = null,
      flashOutcome = null,
      lapsePicks = const <String, MatchLapsePick>{};

  final String sessionId;
  final int roundIndex;
  final List<MatchTermTile> terms;
  final List<MatchMeaningTile> meanings;
  final MatchRound round;

  /// The currently picked term (awaiting a meaning), or null.
  final String? selectedTermId;

  /// The term + meaning tiles of the last resolved pairing, tinted by
  /// [flashOutcome] until the next interaction (transient feedback, no timer).
  final String? flashCardId;
  final String? flashMeaningId;
  final ModeOutcome? flashOutcome;

  /// First failing pick per lapsed card, replayed at flush.
  final Map<String, MatchLapsePick> lapsePicks;

  bool get isReady => terms.isNotEmpty;
  bool get isComplete => round.isComplete;
  int get lockedCount => round.lockedCount;
  int get pairCount => round.pairCount;

  MatchBoardState _copyWith({
    MatchRound? round,
    Object? selectedTermId = _unset,
    Object? flashCardId = _unset,
    Object? flashMeaningId = _unset,
    Object? flashOutcome = _unset,
    Map<String, MatchLapsePick>? lapsePicks,
  }) {
    return MatchBoardState(
      sessionId: sessionId,
      roundIndex: roundIndex,
      terms: terms,
      meanings: meanings,
      round: round ?? this.round,
      selectedTermId: selectedTermId == _unset
          ? this.selectedTermId
          : selectedTermId as String?,
      flashCardId: flashCardId == _unset
          ? this.flashCardId
          : flashCardId as String?,
      flashMeaningId: flashMeaningId == _unset
          ? this.flashMeaningId
          : flashMeaningId as String?,
      flashOutcome: flashOutcome == _unset
          ? this.flashOutcome
          : flashOutcome as ModeOutcome?,
      lapsePicks: lapsePicks ?? this.lapsePicks,
    );
  }
}

const Object _unset = Object();

/// Command + read model for the Match board (WBS 5.6.6; `answer-study-stage.md`,
/// SM-MATCH-v1). It builds the board from the current round, classifies each
/// pairing through [MatchStudyModeStrategy], and exposes the per-card inputs the
/// screen flushes in cursor order when the round completes. Presentation-only:
/// it never touches a repository — advancing the session is the flush command's
/// job.
@riverpod
class MatchBoard extends _$MatchBoard {
  static const MatchStudyModeStrategy _strategy = MatchStudyModeStrategy();

  @override
  MatchBoardState build() {
    final runtime = ref.watch(studySessionRuntimeProvider).asData?.value;
    if (runtime == null || runtime.currentMode != StudyModeType.match) {
      return const MatchBoardState.empty();
    }
    final ids = runtime.position.roundCardIds;
    final terms = <MatchTermTile>[
      for (final id in ids)
        if (runtime.cardsById[id] case final card?)
          MatchTermTile(cardId: id, term: card.term, meaning: card.meaning),
    ];
    final seed = roundOrderSeed(
      sessionId: runtime.session.id,
      modeId: _meaningShuffleModeId,
      roundIndex: runtime.position.roundIndex,
    );
    final meanings = deterministicShuffle(<MatchMeaningTile>[
      for (final t in terms)
        MatchMeaningTile(cardId: t.cardId, meaning: t.meaning),
    ], seed);
    return MatchBoardState(
      sessionId: runtime.session.id,
      roundIndex: runtime.position.roundIndex,
      terms: terms,
      meanings: meanings,
      round: MatchRound.of(terms.map((t) => t.cardId)),
      selectedTermId: null,
      flashCardId: null,
      flashMeaningId: null,
      flashOutcome: null,
      lapsePicks: const <String, MatchLapsePick>{},
    );
  }

  /// Pick a term tile (ignored once it is locked); clears any stale flash.
  void selectTerm(String cardId) {
    if (state.round.isLocked(cardId)) return;
    state = state._copyWith(
      selectedTermId: cardId,
      flashCardId: null,
      flashMeaningId: null,
      flashOutcome: null,
    );
  }

  /// Pair the selected term with a meaning tile. Requires a term to be picked
  /// first and the meaning's owner card to be unlocked; classifies via
  /// SM-MATCH-v1 and records a lapse's first pick for the flush.
  void selectMeaning(String meaningCardId) {
    final termId = state.selectedTermId;
    if (termId == null) return;
    if (state.round.isLocked(meaningCardId)) return;

    final term = state.terms.firstWhere((t) => t.cardId == termId);
    final meaning = state.meanings.firstWhere((m) => m.cardId == meaningCardId);
    final outcome = _strategy
        .evaluate(
          MatchInput(
            sessionId: state.sessionId,
            cardId: termId,
            roundIndex: state.roundIndex,
            eventId: 'match-$termId',
            termPairId: termId,
            selectedMeaningPairId: meaningCardId,
            termMeaning: term.meaning,
            selectedMeaning: meaning.meaning,
          ),
        )
        .outcome;

    final nextRound = state.round.resolve(termPairId: termId, outcome: outcome);
    if (outcome == ModeOutcome.correct) {
      state = state._copyWith(
        round: nextRound,
        selectedTermId: null,
        flashCardId: termId,
        flashMeaningId: meaningCardId,
        flashOutcome: ModeOutcome.correct,
      );
      return;
    }
    // wrong / almost: keep the first failing pick for the flush and let the
    // learner retry (the tile stays unlocked).
    final picks = state.lapsePicks.containsKey(termId)
        ? state.lapsePicks
        : <String, MatchLapsePick>{
            ...state.lapsePicks,
            termId: (meaningCardId: meaningCardId, meaning: meaning.meaning),
          };
    state = state._copyWith(
      round: nextRound,
      selectedTermId: null,
      flashCardId: termId,
      flashMeaningId: meaningCardId,
      flashOutcome: outcome,
      lapsePicks: picks,
    );
  }

  /// The per-card inputs to flush in cursor order once the board is complete.
  /// A passed card replays a correct self-pairing; a lapsed card replays its
  /// stored failing pick so the strategy re-derives `wrong`/`almost`.
  List<MatchInput> flushInputs() {
    final board = state;
    return <MatchInput>[for (final term in board.terms) _inputFor(board, term)];
  }

  MatchInput _inputFor(MatchBoardState board, MatchTermTile term) {
    final pick = board.lapsePicks[term.cardId];
    // A passed card — or the fallback if a lapse pick is somehow missing —
    // replays a correct self-pairing; a lapsed card replays its stored pick.
    if (board.round.passedFor(term.cardId) || pick == null) {
      return MatchInput(
        sessionId: board.sessionId,
        cardId: term.cardId,
        roundIndex: board.roundIndex,
        eventId: 'match-${term.cardId}',
        termPairId: term.cardId,
        selectedMeaningPairId: term.cardId,
        termMeaning: term.meaning,
        selectedMeaning: term.meaning,
      );
    }
    return MatchInput(
      sessionId: board.sessionId,
      cardId: term.cardId,
      roundIndex: board.roundIndex,
      eventId: 'match-${term.cardId}',
      termPairId: term.cardId,
      selectedMeaningPairId: pick.meaningCardId,
      termMeaning: term.meaning,
      selectedMeaning: pick.meaning,
    );
  }
}

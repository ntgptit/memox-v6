import 'dart:async';

import 'package:memox_v6/domain/study_modes/strategies/recall_study_mode_strategy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recall_timer_notifier.g.dart';

/// The phase of one Recall card (WBS 5.6.8; `recall-and-self-grade.md` §2):
/// counting down before reveal, revealed for self-grade, or timed out (the
/// deadline auto-revealed and locks the outcome to wrong).
enum RecallPhase { counting, revealed, timedOut }

/// The presentation state for one Recall card: its phase and the live countdown.
/// Purely in-session — the strategy defines these labels as non-persistent; the
/// durable cross-exit timer (persisting `remainingMs`) lands with Exit/Resume
/// (WBS 5.6.12).
class RecallTimerState {
  const RecallTimerState({required this.phase, required this.remainingSeconds});

  final RecallPhase phase;
  final int remainingSeconds;

  /// Active interaction time elapsed so far, in milliseconds.
  int get elapsedActiveMs =>
      (kRecallTimeoutSeconds - remainingSeconds) *
      Duration.millisecondsPerSecond;
}

/// Owns the Recall countdown for a single card (WBS 5.6.8). A Riverpod notifier
/// (not a `StatefulWidget`) holds the ticking [Timer]; it starts on build,
/// decrements each second, auto-reveals + times out at zero, and stops on a
/// manual [reveal]. Keyed by `cardId` so advancing to the next card starts a
/// fresh 20-second budget. The screen maps the resulting resolution to a
/// [RecallInput]; this notifier never touches the repository or commits.
@riverpod
class RecallTimer extends _$RecallTimer {
  Timer? _ticker;

  @override
  RecallTimerState build(String cardId) {
    _ticker = Timer.periodic(kRecallTickInterval, (_) => _tick());
    ref.onDispose(() => _ticker?.cancel());
    return const RecallTimerState(
      phase: RecallPhase.counting,
      remainingSeconds: kRecallTimeoutSeconds,
    );
  }

  void _tick() {
    if (state.phase != RecallPhase.counting) return;
    final next = state.remainingSeconds - 1;
    if (next <= 0) {
      _ticker?.cancel();
      state = const RecallTimerState(
        phase: RecallPhase.timedOut,
        remainingSeconds: 0,
      );
      return;
    }
    state = RecallTimerState(
      phase: RecallPhase.counting,
      remainingSeconds: next,
    );
  }

  /// Manual reveal before the deadline: stop the clock and open self-grade.
  /// A no-op once revealed or timed out, so the deadline/tap race resolves once.
  void reveal() {
    if (state.phase != RecallPhase.counting) return;
    _ticker?.cancel();
    state = RecallTimerState(
      phase: RecallPhase.revealed,
      remainingSeconds: state.remainingSeconds,
    );
  }
}

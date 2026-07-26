import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/today/continue_session_outcome.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'continue_session_notifier.g.dart';

/// The `Resume session` command (WBS 5.7.3;
/// `continue-session-from-today.md`).
///
/// §1 and §4: "Double tap tạo một handoff" and "Handoff token chặn duplicate
/// navigation" — the in-flight guard is the token, and it lives here rather
/// than in the button so that no control can dispatch a second handoff while
/// the first is resolving.
@riverpod
class ContinueSession extends _$ContinueSession {
  @override
  AsyncValue<ContinueSessionOutcome?> build() =>
      const AsyncData<ContinueSessionOutcome?>(null);

  Future<void> resume() async {
    if (state is AsyncLoading<ContinueSessionOutcome?>) return;
    state = const AsyncLoading<ContinueSessionOutcome?>();

    ContinueSessionOutcome? outcome;
    final result = await runMxAction(() async {
      outcome = await ref.read(continueSessionFromTodayUseCaseProvider).call();
    });

    // §1: "Resume failure không xóa session hoặc Dashboard state" — a failed
    // resolve reports and changes nothing.
    state = switch (result) {
      AsyncError<void>(:final error, :final stackTrace) =>
        AsyncError<ContinueSessionOutcome?>(error, stackTrace),
      _ => AsyncData<ContinueSessionOutcome?>(outcome),
    };
  }
}

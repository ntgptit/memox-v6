import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/deck/reset_progress_availability.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_progress_availability_provider.g.dart';

/// Whether the reset-progress confirm may offer its destructive action
/// (WBS 6.1; `reset-deck-progress.md` §5, §10).
///
/// Read alongside the impact so the dialog can show the active-session state
/// instead of an action that would be refused. The command re-checks on
/// submit — this read only decides what the learner is offered.
@riverpod
Future<ResetProgressAvailability> resetProgressAvailability(
  Ref ref, {
  required String deckId,
}) {
  return ref.read(loadResetProgressAvailabilityUseCaseProvider).call(deckId);
}

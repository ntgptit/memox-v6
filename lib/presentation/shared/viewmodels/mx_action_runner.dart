import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:memox_v6/core/errors/app_failure.dart';

/// Shared async action runner (guard
/// `memox.error_handling.action_controllers_use_runner`).
///
/// Command notifiers set `AsyncLoading`, await [runMxAction] and assign the
/// result — every thrown error maps to [AppFailure] here, so controllers
/// never hand-write `AsyncError` boilerplate and UI never sees low-level
/// exception types.
Future<AsyncValue<void>> runMxAction(Future<void> Function() action) async {
  try {
    await action();
    return const AsyncData(null);
  } catch (error, stackTrace) {
    final failure = AppFailure.from(error, stackTrace);
    return AsyncError<void>(failure, stackTrace);
  }
}

/// Typed one-shot effect listener for command state (WBS 3.9).
///
/// Call from a widget `build` with the command provider; transitions into
/// error deliver the mapped [AppFailure], transitions into data deliver
/// success — exactly once per transition, the `ref.listen` contract.
void listenMxAction(
  WidgetRef ref,
  ProviderListenable<AsyncValue<void>> provider, {
  void Function(AppFailure failure)? onFailure,
  void Function()? onSuccess,
}) {
  ref.listen<AsyncValue<void>>(provider, (previous, next) {
    if (previous is AsyncLoading<void> && next is AsyncData<void>) {
      onSuccess?.call();
      return;
    }
    if (next is AsyncError<void> && previous is! AsyncError<void>) {
      final error = next.error;
      onFailure?.call(
        error is AppFailure ? error : AppFailure.from(error, next.stackTrace),
      );
    }
  });
}

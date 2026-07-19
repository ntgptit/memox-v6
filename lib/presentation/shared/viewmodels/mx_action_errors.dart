import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

/// Action-error helpers (guard `memox.error_handling.action_error_*`).
///
/// UI extracts the failure of an action `AsyncValue<void>` via [failureOf]
/// and maps it to user copy via [messageOf] — never by stringifying raw
/// errors or hand-rolling `whenOrNull` chains.
abstract final class MxActionErrors {
  /// The mapped [AppFailure] of a failed action, or `null` otherwise.
  static AppFailure? failureOf(AsyncValue<void> state) {
    if (state case AsyncError(:final error, :final stackTrace)) {
      return error is AppFailure ? error : AppFailure.from(error, stackTrace);
    }
    return null;
  }

  /// Localized user copy for [failure]; new failure variants extend this
  /// mapping alongside their l10n keys.
  static String messageOf(AppFailure failure, AppLocalizations l10n) =>
      switch (failure) {
        UnexpectedFailure() => l10n.somethingWentWrongMessage,
        DataCorruptionFailure() => l10n.dataCorruptionMessage,
      };
}

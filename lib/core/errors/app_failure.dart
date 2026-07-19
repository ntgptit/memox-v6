/// Application failure taxonomy root.
///
/// Every domain/data/platform error is mapped to an [AppFailure] before it
/// reaches presentation (ADR-005); UI never depends on low-level exception
/// types. Later waves extend this sealed library with domain variants.
sealed class AppFailure implements Exception {
  const AppFailure({required this.message, this.cause, this.stackTrace});

  /// Developer-facing description; user-facing copy is resolved via l10n.
  final String message;

  /// The original error that produced this failure, when one exists.
  final Object? cause;

  /// Stack trace captured where the original error surfaced.
  final StackTrace? stackTrace;

  /// Maps any error to the taxonomy: identity for failures, otherwise an
  /// [UnexpectedFailure] preserving cause and stack.
  static AppFailure from(Object error, StackTrace stackTrace) {
    if (error is AppFailure) return error;
    return UnexpectedFailure(cause: error, stackTrace: stackTrace);
  }

  @override
  String toString() => '$runtimeType: $message';
}

/// Fallback for errors with no dedicated failure type yet.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({required Object cause, super.stackTrace})
    : super(message: 'Unexpected failure', cause: cause);
}

/// Persisted data failed to map into its domain shape — an unknown enum
/// value, an invalid JSON payload or an impossible combination (WBS 4.5).
///
/// Repositories decide per call site whether this aborts the read or
/// falls back to a safe default; mappers never guess silently.
final class DataCorruptionFailure extends AppFailure {
  DataCorruptionFailure({
    required this.entity,
    required this.field,
    this.value,
    super.cause,
    super.stackTrace,
  }) : super(message: 'Corrupted persisted data: $entity.$field');

  /// Table or aggregate whose stored value failed to map.
  final String entity;

  /// Column or payload key that held the unmappable value.
  final String field;

  /// The offending stored value, when it is safe to carry.
  final Object? value;
}

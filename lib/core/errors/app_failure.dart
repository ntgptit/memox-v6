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

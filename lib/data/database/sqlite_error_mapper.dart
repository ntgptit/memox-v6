import 'package:drift/native.dart';
import 'package:memox_v6/core/errors/app_failure.dart';

/// SQLite error → failure taxonomy mapping (WBS 4.6).
///
/// Repositories run their writes through [mapSqliteConflicts] so trigger
/// aborts and uniqueness violations surface as typed [ConflictFailure]s
/// with stable codes; anything else stays an [UnexpectedFailure] via
/// [AppFailure.from].
Future<T> mapSqliteConflicts<T>(
  Future<T> Function() action, {
  required String entity,
}) async {
  try {
    return await action();
  } on SqliteException catch (error, stackTrace) {
    throw ConflictFailure(
      code: _conflictCode(error.message),
      entity: entity,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

String _conflictCode(String message) {
  if (message.contains('deck-mixed-content')) return 'deck-mixed-content';
  if (message.contains('deck-cycle')) return 'deck-cycle';
  if (message.contains('deck-pair-mismatch')) return 'deck-pair-mismatch';
  if (message.contains('UNIQUE constraint failed')) return 'duplicate';
  if (message.contains('FOREIGN KEY constraint failed')) {
    return 'missing-reference';
  }
  return 'constraint';
}

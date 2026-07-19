import 'package:memox_v6/core/errors/app_failure.dart';

/// Session types of BD-003 (WBS 4.5). `dbValue` is the persisted string.
enum SessionType {
  newLearning('newLearning'),
  dueReview('dueReview'),
  relearn('relearn'),
  practice('practice');

  const SessionType(this.dbValue);

  final String dbValue;

  static SessionType parse(String value) => values.firstWhere(
    (type) => type.dbValue == value,
    orElse: () => throw DataCorruptionFailure(
      entity: 'study_sessions',
      field: 'session_type',
      value: value,
    ),
  );
}

import 'package:memox_v6/core/errors/app_failure.dart';

/// Session lifecycle state (WBS 4.5); at most one session is active.
enum SessionState {
  active('active'),
  completed('completed'),
  abandoned('abandoned');

  const SessionState(this.dbValue);

  final String dbValue;

  static SessionState parse(String value) => values.firstWhere(
    (state) => state.dbValue == value,
    orElse: () => throw DataCorruptionFailure(
      entity: 'study_sessions',
      field: 'state',
      value: value,
    ),
  );
}

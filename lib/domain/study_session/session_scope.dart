import 'package:memox_v6/core/errors/app_failure.dart';

/// Study scope selection (WBS 4.5): a Leaf Deck or a subtree.
enum SessionScope {
  leaf('leaf'),
  subtree('subtree');

  const SessionScope(this.dbValue);

  final String dbValue;

  static SessionScope parse(String value) => values.firstWhere(
    (scope) => scope.dbValue == value,
    orElse: () => throw DataCorruptionFailure(
      entity: 'study_sessions',
      field: 'scope',
      value: value,
    ),
  );
}

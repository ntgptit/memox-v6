import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';

/// Study Session domain model (WBS 4.5).
class StudySession {
  const StudySession({
    required this.id,
    required this.type,
    required this.deckId,
    required this.scope,
    required this.state,
    required this.revision,
    required this.snapshotVersion,
    required this.scheduleSrs,
    required this.startedAt,
    required this.finalizedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final SessionType type;
  final String deckId;
  final SessionScope scope;
  final SessionState state;
  final int revision;
  final int snapshotVersion;
  final bool scheduleSrs;
  final DateTime startedAt;
  final DateTime? finalizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => state == SessionState.active;
}

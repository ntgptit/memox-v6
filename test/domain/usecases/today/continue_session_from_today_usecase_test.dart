import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/domain/study_session/study_session_repository.dart';
import 'package:memox_v6/domain/today/continue_session_outcome.dart';
import 'package:memox_v6/domain/usecases/today/continue_session_from_today_usecase.dart';

/// WBS 5.7.3 — `Resume session` resolves the session again before Today
/// navigates (`continue-session-from-today.md` §1).
void main() {
  final now = DateTime.utc(2026, 7, 26, 10);

  StudySession session() => StudySession(
    id: 's1',
    type: SessionType.dueReview,
    deckId: 'd1',
    scope: SessionScope.subtree,
    state: SessionState.active,
    revision: 0,
    snapshotVersion: 1,
    scheduleSrs: true,
    startedAt: now,
    finalizedAt: null,
    createdAt: now,
    updatedAt: now,
  );

  test('a live session resolves to its checkpoint', () async {
    final outcome = await ContinueSessionFromTodayUseCase(
      sessions: _FakeSessions(session()),
    )();

    expect(outcome, isA<ResumeAtCheckpoint>());
    expect((outcome as ResumeAtCheckpoint).session.id, 's1');
  });

  // §6: "Không tạo session mới." The learner asked to continue something; if
  // it finished on another surface the honest answer is that it is over, not
  // a fresh session that looks like the old one.
  test('a session finalized elsewhere is reported, not replaced', () async {
    final outcome = await ContinueSessionFromTodayUseCase(
      sessions: _FakeSessions(null),
    )();

    expect(outcome, isA<SessionNoLongerResumable>());
  });
}

class _FakeSessions implements StudySessionRepository {
  _FakeSessions(this._active);

  final StudySession? _active;

  @override
  Stream<StudySession?> watchActive() => Stream<StudySession?>.value(_active);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

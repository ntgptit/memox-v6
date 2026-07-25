import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_session_runtime_provider.dart';

/// WBS 5.6.3 — the runtime query projects an active session, or null when none.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DriftStudySessionRepository sessions;
  final now = DateTime.utc(2026, 7, 23, 14);

  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [studySessionRepositoryProvider.overrideWithValue(sessions)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    sessions = DriftStudySessionRepository(database);
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D', 'd', 0, 0);
    for (final id in <String>['a', 'b']) {
      await database.flashcardDao.insertFlashcard(
        id,
        'd1',
        id,
        id,
        'm-$id',
        0,
        0,
      );
    }
  });

  tearDown(() => database.close());

  test('returns null when no session is active', () async {
    final runtime = await containerWith().read(
      studySessionRuntimeProvider.future,
    );
    expect(runtime, isNull);
  });

  test('projects the active session onto the runtime read model', () async {
    await sessions.startSession(
      session: StudySession(
        id: 's1',
        type: SessionType.newLearning,
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
      ),
      cardSnapshots: <SessionCardSnapshot>[
        SessionCardSnapshot(
          id: 'sc-a',
          sessionId: 's1',
          cardId: 'a',
          displayOrder: 0,
          term: 'A',
          meaning: 'm-a',
          contentVersion: 1,
          progressBox: 0,
          progressRevision: 0,
        ),
        SessionCardSnapshot(
          id: 'sc-b',
          sessionId: 's1',
          cardId: 'b',
          displayOrder: 1,
          term: 'B',
          meaning: 'm-b',
          contentVersion: 1,
          progressBox: 0,
          progressRevision: 0,
        ),
      ],
      initialOrder: const SessionRoundOrder(
        id: 'ro1',
        sessionId: 's1',
        roundIndex: 1,
        seed: 1,
        cardIds: <String>['a', 'b'],
      ),
    );

    final runtime = await containerWith().read(
      studySessionRuntimeProvider.future,
    );
    expect(runtime, isNotNull);
    // newLearning resolves the five-stage plan; stage 0 is Review.
    expect(runtime!.currentMode, StudyModeType.review);
    expect(runtime.stages.length, 5);
    expect(runtime.currentCard?.cardId, 'a');
    expect(runtime.totalCards, 2);
    expect(runtime.isComplete, isFalse);
  });
}

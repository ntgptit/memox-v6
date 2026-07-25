import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// WBS 5.6.2 — start use case wires the eligible cards → snapshot → atomic
/// startSession (`start-study-session.md`; ST-SESSION-TYPE-v1).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late StartStudySessionUseCase useCase;

  final now = DateTime.utc(2026, 7, 23, 11);

  Future<void> newCard(String id, String meaning) async {
    await database.flashcardDao.insertFlashcard(
      id,
      'd1',
      id,
      id,
      meaning,
      0,
      0,
    );
    await database.learningProgressDao.insertProgress(
      'p-$id',
      id,
      0,
      null,
      0,
      0,
    );
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    useCase = StartStudySessionUseCase(
      progress: DriftLearningProgressRepository(database),
      cards: DriftFlashcardRepository(database),
      sessions: DriftStudySessionRepository(database),
      clock: _FixedClock(now),
      idGenerator: _SeqIds(),
    );
    await database.languagePairDao.insertLanguagePair(
      'lp1',
      'en',
      'vi',
      'en|vi',
      0,
      0,
    );
    await database.deckDao.insertDeck('d1', 'lp1', null, 'D', 'd', 0, 0);
  });

  tearDown(() => database.close());

  test(
    'newLearning with five distinct meanings starts and snapshots',
    () async {
      for (final meaning in <String>['one', 'two', 'three', 'four', 'five']) {
        await newCard('c-$meaning', meaning);
      }

      final session = await useCase.call(
        deckId: 'd1',
        scope: SessionScope.subtree,
        type: SessionType.newLearning,
      );

      expect(session.type, SessionType.newLearning);
      expect(session.state, SessionState.active);
      expect(session.scheduleSrs, isTrue);

      final persisted = await DriftStudySessionRepository(
        database,
      ).findById(session.id);
      expect(persisted, isNotNull);
      final snapshots = await DriftStudySessionRepository(
        database,
      ).cardSnapshots(session.id);
      expect(snapshots.length, 5);
    },
  );

  test(
    'newLearning with fewer than five distinct meanings is blocked',
    () async {
      for (final meaning in <String>['a', 'b', 'c']) {
        await newCard('c-$meaning', meaning);
      }

      await expectLater(
        useCase.call(
          deckId: 'd1',
          scope: SessionScope.subtree,
          type: SessionType.newLearning,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.code,
            'code',
            'guessPoolInsufficient',
          ),
        ),
      );
      // No session persisted.
      expect(
        await database.studySessionDao.watchActiveSession().getSingleOrNull(),
        isNull,
      );
    },
  );

  test('dueReview with an empty due queue is caught-up, no session', () async {
    await expectLater(
      useCase.call(
        deckId: 'd1',
        scope: SessionScope.subtree,
        type: SessionType.dueReview,
      ),
      throwsA(
        isA<ValidationFailure>().having((f) => f.code, 'code', 'dueCaughtUp'),
      ),
    );
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowUtc() => _now;
}

class _SeqIds implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${_n++}';
}

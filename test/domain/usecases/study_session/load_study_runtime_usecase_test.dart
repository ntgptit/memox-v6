import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/repositories/drift_flashcard_repository.dart';
import 'package:memox_v6/data/repositories/drift_learning_progress_repository.dart';
import 'package:memox_v6/data/repositories/drift_study_session_repository.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/usecases/study_session/load_study_runtime_usecase.dart';
import 'package:memox_v6/domain/usecases/study_session/start_study_session_usecase.dart';

/// WBS 5.6.3 — the runtime read model replays the session it loads
/// (`resume-study-session.md` §1: "Resume dùng session snapshot + committed
/// checkpoint"; ST-TYPE-018: a snapshotted plan is never re-resolved).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late StartStudySessionUseCase start;
  late LoadStudyRuntimeUseCase load;

  final now = DateTime.utc(2026, 7, 27, 11);

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
    final sessions = DriftStudySessionRepository(database);
    start = StartStudySessionUseCase(
      progress: DriftLearningProgressRepository(database),
      cards: DriftFlashcardRepository(database),
      sessions: sessions,
      clock: _FixedClock(now),
      idGenerator: _SeqIds(),
    );
    load = LoadStudyRuntimeUseCase(sessions: sessions);
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

  test('no active session loads nothing', () async {
    expect(await load(), isNull);
  });

  // ST-TYPE-015/016: a Relearn session with five distinct meanings runs Guess.
  // The runtime resolved the plan with the default `guessPoolSufficient:
  // false`, so resuming one silently handed the learner the binary fallback —
  // a different plan from the one their session was started under.
  test('a Guess relearn session resumes as Guess, not the fallback', () async {
    const meanings = <String>['one', 'two', 'three', 'four', 'five'];
    for (final meaning in meanings) {
      await newCard('c-$meaning', meaning);
    }

    final session = await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.relearn,
      relearnCardIds: <String>[for (final m in meanings) 'c-$m'],
    );
    expect(session.type, SessionType.relearn);

    final runtime = await load();

    expect(runtime, isNotNull);
    expect(runtime!.stages, <StudyModeType>[StudyModeType.guess]);
  });

  // The other half of the same branch: too small a pool really is the binary
  // fallback, so the fix must not have pinned Guess unconditionally.
  test('a small-pool relearn session resumes as the binary fallback', () async {
    const meanings = <String>['one', 'two'];
    for (final meaning in meanings) {
      await newCard('c-$meaning', meaning);
    }

    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.relearn,
      relearnCardIds: <String>[for (final m in meanings) 'c-$m'],
    );

    final runtime = await load();

    expect(runtime, isNotNull);
    expect(runtime!.stages, <StudyModeType>[StudyModeType.srsBinaryReview]);
  });

  test('a newLearning session resumes on its five-stage plan', () async {
    for (final meaning in <String>['one', 'two', 'three', 'four', 'five']) {
      await newCard('c-$meaning', meaning);
    }

    await start.call(
      deckId: 'd1',
      scope: SessionScope.subtree,
      type: SessionType.newLearning,
    );

    final runtime = await load();

    expect(runtime, isNotNull);
    expect(runtime!.stages.length, greaterThan(1));
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

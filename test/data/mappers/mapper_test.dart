import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/data/database/app_database.dart' as db;
import 'package:memox_v6/data/mappers/content_mapper.dart';
import 'package:memox_v6/data/mappers/progress_mapper.dart';
import 'package:memox_v6/data/mappers/session_mapper.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';

void main() {
  group('content mappers', () {
    test('flashcard rows map timestamps, flags and soft delete', () {
      const row = db.Flashcard(
        id: 'c1',
        deckId: 'd1',
        term: 'hello',
        normalizedTerm: 'hello',
        primaryMeaning: 'xin chào',
        contentVersion: 3,
        isHidden: 1,
        deletedAt: null,
        createdAt: 1000,
        updatedAt: 2000,
      );

      final card = row.toDomain();

      expect(card.isHidden, isTrue);
      expect(card.isDeleted, isFalse);
      expect(card.createdAt, DateTime.utc(1970, 1, 1, 0, 0, 1));
      expect(card.createdAt.isUtc, isTrue);
      expect(card.contentVersion, 3);
    });

    test('corrupted stored flags raise a typed failure', () {
      const row = db.Flashcard(
        id: 'c1',
        deckId: 'd1',
        term: 't',
        normalizedTerm: 't',
        primaryMeaning: 'm',
        contentVersion: 1,
        isHidden: 7,
        deletedAt: null,
        createdAt: 0,
        updatedAt: 0,
      );

      expect(
        row.toDomain,
        throwsA(
          isA<DataCorruptionFailure>()
              .having((failure) => failure.entity, 'entity', 'flashcards')
              .having((failure) => failure.field, 'field', 'is_hidden'),
        ),
      );
    });
  });

  group('progress mappers', () {
    test('progress rows keep the policy identity and due semantics', () {
      const row = db.LearningProgressData(
        id: 'p1',
        cardId: 'c1',
        box: 3,
        dueAt: 5000,
        policyId: 'leitner-8-box-v1',
        policyVersion: 1,
        revision: 2,
        repetitionCount: 4,
        lapseCount: 1,
        lastTerminalAttemptId: 'a9',
        createdAt: 0,
        updatedAt: 0,
      );

      final progress = row.toDomain();

      expect(progress.policyId, 'leitner-8-box-v1');
      expect(progress.isDueAt(DateTime.utc(1970, 1, 1, 0, 0, 5)), isTrue);
      expect(progress.isDueAt(DateTime.utc(1970, 1, 1, 0, 0, 4)), isFalse);
    });

    test('invalid preference payloads fall back to null', () {
      const valid = db.Preference(
        prefKey: 'appearance',
        valueJson: '{"mode":"dark"}',
        valueSchemaVersion: 1,
        updatedAt: 0,
      );
      const broken = db.Preference(
        prefKey: 'appearance',
        valueJson: '{not json',
        valueSchemaVersion: 1,
        updatedAt: 0,
      );

      final entry = valid.toDomainOrNull();
      expect(entry, isNotNull);
      expect(entry?.value, {'mode': 'dark'});

      expect(broken.toDomainOrNull(), isNull);
    });

    test('goal buckets and streak days map their snapshots', () {
      const bucket = db.GoalDayProgressData(
        id: 'b1',
        localDate: '2026-07-19',
        timezoneId: 'Asia/Ho_Chi_Minh',
        goalId: 'g1',
        qualifiedCardCount: 10,
        targetSnapshot: 10,
        isMet: 1,
        createdAt: 0,
        updatedAt: 0,
      );
      const day = db.StreakDay(
        id: 's1',
        localDate: '2026-07-19',
        timezoneId: 'Asia/Ho_Chi_Minh',
        qualifiedSource: 'metrics-v1',
        sourceVersion: 1,
        createdAt: 0,
      );

      expect(bucket.toDomain().isMet, isTrue);
      expect(day.toDomain().localDate, '2026-07-19');
    });
  });

  group('session mappers', () {
    db.StudySession sessionRow({String type = 'newLearning'}) =>
        db.StudySession(
          id: 's1',
          sessionType: type,
          deckId: 'd1',
          scope: 'leaf',
          state: 'active',
          revision: 0,
          snapshotVersion: 1,
          scheduleSrs: 1,
          startedAt: 0,
          finalizedAt: null,
          createdAt: 0,
          updatedAt: 0,
        );

    test('typed enums come out of the stored strings', () {
      final session = sessionRow().toDomain();

      expect(session.type, SessionType.newLearning);
      expect(session.state, SessionState.active);
      expect(session.isActive, isTrue);
      expect(session.scheduleSrs, isTrue);
    });

    test('unknown enum values raise typed corruption failures', () {
      expect(
        sessionRow(type: 'cramming').toDomain,
        throwsA(
          isA<DataCorruptionFailure>()
              .having((failure) => failure.field, 'field', 'session_type')
              .having((failure) => failure.value, 'value', 'cramming'),
        ),
      );
    });

    test('checkpoint failed sets decode and reject invalid JSON', () {
      const row = db.StudyCheckpoint(
        id: 'cp1',
        sessionId: 's1',
        stageIndex: 1,
        roundIndex: 0,
        cardPosition: 2,
        failedSetJson: '["c1","c2"]',
        timerStateJson: '{}',
        stateVersion: 1,
        updatedAt: 0,
      );

      expect(row.toDomain().failedCardIds, ['c1', 'c2']);

      const broken = db.StudyCheckpoint(
        id: 'cp1',
        sessionId: 's1',
        stageIndex: 0,
        roundIndex: 0,
        cardPosition: 0,
        failedSetJson: '{"not":"a list"}',
        timerStateJson: '{}',
        stateVersion: 1,
        updatedAt: 0,
      );

      expect(
        broken.toDomain,
        throwsA(
          isA<DataCorruptionFailure>().having(
            (failure) => failure.field,
            'field',
            'failed_set_json',
          ),
        ),
      );
    });

    test('round orders replay the persisted card order', () {
      const row = db.StudyRoundOrder(
        id: 'ro1',
        sessionId: 's1',
        roundIndex: 1,
        seed: 42,
        cardOrderJson: '["c2","c1"]',
        createdAt: 0,
      );

      final order = row.toDomain();
      expect(order.cardIds, ['c2', 'c1']);
      expect(order.seed, 42);
    });
  });
}

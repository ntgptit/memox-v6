import 'package:flutter/foundation.dart';
import 'package:memox_v6/data/database/app_database.dart';

/// Named developer fixture states (WBS 1.7).
enum DevFixtureState {
  /// Fresh install: no rows anywhere.
  empty,

  /// One language pair, one deck, one card at Box 0.
  minimum,

  /// A deck tree with sibling decks and a paged-size batch of cards.
  dense,

  /// Stored state that exercises error paths: a corrupt preference
  /// payload (reads fall back) alongside minimum content.
  error,

  /// An active session with snapshot, round order and a mid-round
  /// checkpoint — the resume path's input.
  pausedSession,

  /// Minimum content whose card is due for review right now.
  dueCard,
}

/// Developer-only seed/reset commands (WBS 1.7).
///
/// Never available in release mode: construction throws in release
/// builds so no shipped code path can invoke a seeder. Tests may pass
/// [enabled] explicitly to prove the guard.
class DevFixtures {
  DevFixtures(this._database, {bool enabled = !kReleaseMode})
    : _enabled = enabled {
    if (_enabled) return;
    throw StateError('DevFixtures are not available in release builds.');
  }

  final AppDatabase _database;
  final bool _enabled;

  static const _now = 1752885000000;
  static const _dayMs = 86400000;

  /// Deletes every row, child tables first, restoring [DevFixtureState.empty].
  Future<void> reset() {
    return _database.transaction(() async {
      const tablesInDeleteOrder = [
        'session_relearn_items',
        'study_round_orders',
        'study_checkpoints',
        'study_session_cards',
        'study_attempts',
        'study_sessions',
        'learning_progress',
        'card_audio_refs',
        'flashcard_tags',
        'tags',
        'flashcard_translations',
        'flashcards',
        'decks',
        'language_pairs',
        'preferences',
        'goal_day_progress',
        'daily_goals',
        'streak_days',
      ];
      for (final table in tablesInDeleteOrder) {
        await _database.customStatement('DELETE FROM $table');
      }
    });
  }

  /// Resets, then seeds [state].
  Future<void> seed(DevFixtureState state) async {
    await reset();
    switch (state) {
      case DevFixtureState.empty:
        return;
      case DevFixtureState.minimum:
        await _seedMinimum();
      case DevFixtureState.dense:
        await _seedDense();
      case DevFixtureState.error:
        await _seedError();
      case DevFixtureState.pausedSession:
        await _seedPausedSession();
      case DevFixtureState.dueCard:
        await _seedDueCard();
    }
  }

  Future<void> _seedMinimum() async {
    await _database.languagePairDao.insertLanguagePair(
      'fix-lp',
      'en',
      'vi',
      'en|vi',
      _now,
      _now,
    );
    await _database.deckDao.insertDeck(
      'fix-deck',
      'fix-lp',
      null,
      'Starter',
      'starter',
      _now,
      _now,
    );
    await _database.flashcardDao.insertFlashcard(
      'fix-card',
      'fix-deck',
      'hello',
      'xin chào',
      _now,
      _now,
    );
    await _database.learningProgressDao.insertProgress(
      'fix-progress',
      'fix-card',
      0,
      null,
      _now,
      _now,
    );
  }

  Future<void> _seedDense() async {
    await _database.languagePairDao.insertLanguagePair(
      'fix-lp',
      'en',
      'vi',
      'en|vi',
      _now,
      _now,
    );
    await _database.deckDao.insertDeck(
      'fix-root',
      'fix-lp',
      null,
      'Library',
      'library',
      _now,
      _now,
    );
    for (var deckIndex = 0; deckIndex < 3; deckIndex++) {
      final deckId = 'fix-deck-$deckIndex';
      await _database.deckDao.insertDeck(
        deckId,
        'fix-lp',
        'fix-root',
        'Deck $deckIndex',
        'deck $deckIndex',
        _now,
        _now,
      );
      for (var cardIndex = 0; cardIndex < 25; cardIndex++) {
        final cardId = 'fix-card-$deckIndex-$cardIndex';
        await _database.flashcardDao.insertFlashcard(
          cardId,
          deckId,
          'term $cardIndex',
          'meaning $cardIndex',
          _now + cardIndex,
          _now + cardIndex,
        );
        await _database.learningProgressDao.insertProgress(
          'fix-progress-$deckIndex-$cardIndex',
          cardId,
          0,
          null,
          _now,
          _now,
        );
      }
    }
  }

  Future<void> _seedError() async {
    await _seedMinimum();
    await _database.preferenceDao.upsertPreference(
      'appearance',
      '{broken-json',
      1,
      _now,
    );
  }

  Future<void> _seedPausedSession() async {
    await _seedMinimum();
    await _database.studySessionDao.insertSession(
      'fix-session',
      'newLearning',
      'fix-deck',
      'leaf',
      'active',
      1,
      _now,
      _now,
      _now,
    );
    await _database.sessionSnapshotDao.insertSessionCard(
      'fix-snapshot',
      'fix-session',
      'fix-card',
      0,
      'hello',
      'xin chào',
      1,
      0,
      0,
      _now,
    );
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fix-order',
      'fix-session',
      0,
      42,
      '["fix-card"]',
      _now,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fix-checkpoint',
      'fix-session',
      1,
      0,
      0,
      '[]',
      '{}',
      1,
      _now,
    );
  }

  Future<void> _seedDueCard() async {
    await _seedMinimum();
    await _database.learningProgressDao.updateProgressGuarded(
      1,
      _now - _dayMs,
      1,
      0,
      null,
      _now,
      'fix-card',
      0,
    );
  }
}

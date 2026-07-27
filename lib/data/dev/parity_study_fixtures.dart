import 'dart:convert';

import 'package:memox_v6/data/database/app_database.dart';
import 'package:memox_v6/data/dev/parity_fixtures.dart';

/// The study-session half of the parity fixture registry (WBS P0.3).
///
/// Split out of [ParityFixtures] purely by size — the four resumable
/// session seeds are much larger than the rest put together, and the
/// combined file crossed the 500-line guard limit. The contract is
/// unchanged: data only, never flow position. Each seed writes a session,
/// its card snapshots and a checkpoint so the study route *resumes* into
/// the stage under test; the spec still drives every step from there.
///
/// The active language pair is seeded by [ParityFixtures] before these
/// run, so none of them seeds it again.
class ParityStudyFixtures {
  ParityStudyFixtures(this._database);

  final AppDatabase _database;

  /// Mirrors [ParityFixtures.fixedInstantMs] so both halves stamp the
  /// same instant.
  static const int fixedInstantMs = ParityFixtures.fixedInstantMs;

  /// An active newLearning session resumed into Review, stage 0, card 1/5 — the
  /// kit `review-mode--browsing` state (WBS 5.6.5). The first card in the
  /// persisted round order is the shot's `학교` / `school`. Seeded as data (the
  /// session, its five card snapshots and the round order) so navigating to the
  /// study route resumes into Review without a start flow.
  Future<void> seedReviewSession() async {
    await _database.deckDao.insertDeck(
      'fx-rv-deck',
      'fx-lp-1',
      null,
      'Nouns',
      'nouns',
      fixedInstantMs,
      fixedInstantMs,
    );

    const cards = <(String, String, String)>[
      ('fx-rv-c0', '학교', 'school'),
      ('fx-rv-c1', '선생님', 'teacher'),
      ('fx-rv-c2', '학생', 'student'),
      ('fx-rv-c3', '책', 'book'),
      ('fx-rv-c4', '연필', 'pencil'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-rv-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-rv-session',
      'newLearning',
      'fx-rv-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-rv-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-rv-order',
      'fx-rv-session',
      1,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Guess, stage 2 (Review → Match →
  /// Guess), card 1/5 — the kit `guess-mode--waiting` state (WBS 5.6.7). The
  /// current card is the shot's `학교` / `school`; the pool's four other meanings
  /// (hospital, park, restaurant, library) are the distractors. The round index
  /// (67) is chosen so the seeded distractor + option shuffles
  /// ([GuessQuestionBuilder]) reproduce the kit's exact top-to-bottom option
  /// order, isolating the visual diff to the known CJK-term cap (the Korean
  /// prompt has no bundled glyph in the offline harness, same as review-mode) and
  /// the not-yet-built edit/audio affordances. Seeded as data (session, five card
  /// snapshots, the round order and the guess-stage checkpoint) so navigating to
  /// the study route resumes into Guess without a start flow.
  Future<void> seedGuessSession() async {
    await _database.deckDao.insertDeck(
      'fx-gs-deck',
      'fx-lp-1',
      null,
      'Places',
      'places',
      fixedInstantMs,
      fixedInstantMs,
    );

    // Card 0 is the guessed card; its meaning is the correct choice. The other
    // four supply the distractor meanings shown as options. Distractor terms are
    // never rendered in the Guess prompt, so their script is immaterial.
    const cards = <(String, String, String)>[
      ('fx-gs-c0', '학교', 'school'),
      ('fx-gs-c1', '병원', 'hospital'),
      ('fx-gs-c2', '공원', 'park'),
      ('fx-gs-c3', '식당', 'restaurant'),
      ('fx-gs-c4', '도서관', 'library'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-gs-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-gs-session',
      'newLearning',
      'fx-gs-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-gs-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    // The guess round carries round index 67 (see the doc comment): the checkpoint
    // and its round order share it so the loader resolves this order for stage 2.
    const guessRoundIndex = 67;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-gs-order',
      'fx-gs-session',
      guessRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-gs-checkpoint',
      'fx-gs-session',
      2,
      guessRoundIndex,
      0,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Match, stage 1 (Review → Match
  /// → Guess → Recall → Fill) — the kit `match-mode` states (WBS 5.6.6).
  ///
  /// Match is the one mode that had no fixture, no spec and no census row: it
  /// was skipped everywhere the other five modes were covered. Seeded as data
  /// (session, five card snapshots, the round order and the match-stage
  /// checkpoint) so navigating to the study route resumes into Match without a
  /// start flow, exactly as the other mode fixtures do.
  ///
  /// Both sides of a Match board are rendered, unlike Guess where distractor
  /// terms never appear — so every term here is real Korean rather than
  /// filler, or the board would read as half-broken.
  Future<void> seedMatchSession() async {
    await _database.deckDao.insertDeck(
      'fx-mt-deck',
      'fx-lp-1',
      null,
      'Everyday verbs',
      'everyday verbs',
      fixedInstantMs,
      fixedInstantMs,
    );

    // The kit's own board, pair for pair (`MatchMode.jsx`: LEFT = time, love,
    // friend, food, school / RIGHT = 사랑, 학교, 음식, 시간, 친구). Seeding the
    // same cards makes the comparison about composition rather than about
    // which words happened to be chosen.
    const cards = <(String, String, String)>[
      ('fx-mt-c0', '사랑', 'love'),
      ('fx-mt-c1', '학교', 'school'),
      ('fx-mt-c2', '음식', 'food'),
      ('fx-mt-c3', '시간', 'time'),
      ('fx-mt-c4', '친구', 'friend'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-mt-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-mt-session',
      'newLearning',
      'fx-mt-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-mt-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    // Match is stage index 1; the checkpoint and its round order share the
    // round index so the loader resolves this order for stage 1, card 0.
    const matchRoundIndex = 2;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-mt-order',
      'fx-mt-session',
      matchRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-mt-checkpoint',
      'fx-mt-session',
      1,
      matchRoundIndex,
      0,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Recall, stage 3 (Review → Match →
  /// Guess → Recall), card 1/5 — the kit `recall-mode` states (WBS 5.6.8). The
  /// current card is the shot's `친구` / `friend`. The spec reveals the answer
  /// (tap Show) to reach the stable `recall-mode--revealed` state before
  /// capturing, since the before-reveal countdown ticks. Seeded as data (session,
  /// five card snapshots, the round order and the recall-stage checkpoint) so
  /// navigating to the study route resumes into Recall without a start flow.
  Future<void> seedRecallSession() async {
    await _database.deckDao.insertDeck(
      'fx-rc-deck',
      'fx-lp-1',
      null,
      'People',
      'people',
      fixedInstantMs,
      fixedInstantMs,
    );

    const cards = <(String, String, String)>[
      ('fx-rc-c0', '친구', 'friend'),
      ('fx-rc-c1', '가족', 'family'),
      ('fx-rc-c2', '이웃', 'neighbor'),
      ('fx-rc-c3', '동료', 'colleague'),
      ('fx-rc-c4', '손님', 'guest'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-rc-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-rc-session',
      'newLearning',
      'fx-rc-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-rc-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    // Recall is stage index 3; its round carries a distinct session-global round
    // index. The checkpoint and its round order share it so the loader resolves
    // this order for stage 3, card 0.
    const recallRoundIndex = 4;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-rc-order',
      'fx-rc-session',
      recallRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-rc-checkpoint',
      'fx-rc-session',
      3,
      recallRoundIndex,
      0,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }

  /// An active newLearning session resumed into Fill, stage 4 (Review → Match →
  /// Guess → Recall → Fill), card 1/5 — the kit `fill-mode--waiting` state (WBS
  /// 5.6.9). The prompt shows the meaning `friend`; the learner types the term.
  /// The waiting state shows only Latin content (meaning + placeholder), so it is
  /// free of the CJK-term cap. Seeded as data (session, five card snapshots, the
  /// round order and the fill-stage checkpoint) so navigating to the study route
  /// resumes into Fill without a start flow.
  /// The Fill stage as `study-session--answer-save-error` stages it: the kit
  /// shot is a 25-card session on its 21st card, prompting `school`.
  ///
  /// `seedFillSession` is a five-card session on its first card, which is
  /// right for `fill-mode--waiting` and wrong here — the counter and the
  /// prompt are most of what a capture compares outside the dialog.
  Future<void> seedFillSessionAtShotPosition() async {
    await _database.deckDao.insertDeck(
      'fx-fl-deck',
      'fx-lp-1',
      null,
      'Words',
      'words',
      fixedInstantMs,
      fixedInstantMs,
    );

    const shotCardIndex = 20;
    const shotPrompt = 'school';
    const shotTerm = 'hakgyo';
    const totalCards = 25;
    // Only the card the shot prompts carries the kit's content; the rest
    // exist to make the counter read 21/25, and are never rendered.
    (String, String, String) cardAt(int index) => index == shotCardIndex
        ? ('fx-fl-c$index', shotTerm, shotPrompt)
        : ('fx-fl-c$index', 'term$index', 'meaning$index');
    final cards = <(String, String, String)>[
      for (var i = 0; i < totalCards; i++) cardAt(i),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-fl-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-fl-session',
      'newLearning',
      'fx-fl-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-fl-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    const fillRoundIndex = 5;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-fl-order',
      'fx-fl-session',
      fillRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-fl-checkpoint',
      'fx-fl-session',
      4,
      fillRoundIndex,
      shotCardIndex,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }

  Future<void> seedFillSession() async {
    await _database.deckDao.insertDeck(
      'fx-fl-deck',
      'fx-lp-1',
      null,
      'Words',
      'words',
      fixedInstantMs,
      fixedInstantMs,
    );

    // The term (typed answer) is never shown in the waiting state; the meaning is
    // the prompt. Latin content keeps the compared state renderable in the
    // offline harness.
    const cards = <(String, String, String)>[
      ('fx-fl-c0', 'chingu', 'friend'),
      ('fx-fl-c1', 'gajok', 'family'),
      ('fx-fl-c2', 'iut', 'neighbor'),
      ('fx-fl-c3', 'dongryo', 'colleague'),
      ('fx-fl-c4', 'sonnim', 'guest'),
    ];
    for (final (id, term, meaning) in cards) {
      await _database.flashcardDao.insertFlashcard(
        id,
        'fx-fl-deck',
        term,
        term,
        meaning,
        fixedInstantMs,
        fixedInstantMs,
      );
      await _database.learningProgressDao.insertProgress(
        'p-$id',
        id,
        0,
        null,
        fixedInstantMs,
        fixedInstantMs,
      );
    }

    await _database.studySessionDao.insertSession(
      'fx-fl-session',
      'newLearning',
      'fx-fl-deck',
      'subtree',
      'active',
      1,
      fixedInstantMs,
      fixedInstantMs,
      fixedInstantMs,
    );
    for (var i = 0; i < cards.length; i++) {
      final (id, term, meaning) = cards[i];
      await _database.sessionSnapshotDao.insertSessionCard(
        'sc-$id',
        'fx-fl-session',
        id,
        i,
        term,
        meaning,
        1,
        0,
        0,
        fixedInstantMs,
      );
    }
    // Fill is stage index 4; the checkpoint and its round order share the round
    // index so the loader resolves this order for stage 4, card 0.
    const fillRoundIndex = 5;
    await _database.sessionSnapshotDao.insertRoundOrder(
      'fx-fl-order',
      'fx-fl-session',
      fillRoundIndex,
      1,
      jsonEncode(cards.map((card) => card.$1).toList()),
      fixedInstantMs,
    );
    await _database.sessionCheckpointDao.upsertCheckpoint(
      'fx-fl-checkpoint',
      'fx-fl-session',
      4,
      fillRoundIndex,
      0,
      '[]',
      '{}',
      1,
      fixedInstantMs,
    );
  }
}

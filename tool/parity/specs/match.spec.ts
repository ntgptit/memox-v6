import { expect, test } from '@playwright/test';
import { deepLinkEntry, expectRoute, tapControl } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

/**
 * Match was the one study mode covered nowhere: no fixture, no spec and no
 * `MX-VIS-*` row, while Review, Guess, Recall and Fill each had all three. The
 * kit draws six `match-mode` states and `match_screen.dart` ships, so the gap
 * was in the census rather than in the product.
 */

// MX-VIS-062 · Match · Playing (board dealt, nothing selected)
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: A["Resume"] → B["Load snapshot + checkpoint + attempts"] →
//            F["Validate checkpoint"] → G["Open committed stage/card"]
test('MX-VIS-062 resumes into the Match playing stage', async ({
  page,
}, testInfo) => {
  // Same resume entry the other four modes use: the fixture seeds a committed
  // active newLearning session parked at the Match stage, and reopening the app
  // at the study route is the flow's entry node — the committed stage is opened
  // from the checkpoint rather than by walking a start flow through Review.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-062',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Match stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Match')).toBeVisible();

  // Both sides of the board render — unlike Guess, where distractor terms are
  // never shown — so a term and a meaning are asserted before capturing.
  await expect(page.getByText('사랑')).toBeVisible();
  await expect(page.getByText('school')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-062',
    shot: 'match-mode--playing',
    screen: 'Match',
    state: 'playing',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode:
      'A["Resume"] → B["Load snapshot + checkpoint + attempts"] → F["Validate checkpoint"] → G["Open committed stage/card"]',
    fixture: 'MX-VIS-062',
    route: '/study',
  });
});

// MX-VIS-063 · Match · Selected (one tile picked, awaiting its pair)
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: G["Open committed stage/card"] → H["Answer the stage"]
test('MX-VIS-063 selecting one tile marks it and waits for its pair', async ({
  page,
}, testInfo) => {
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-063',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Match stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Match')).toBeVisible();

  // The kit selects the second left-hand tile, `love`. Both columns are
  // seeded from the kit's own pairs and shuffled by the round-order seed;
  // `love` lands second here too, so the highlight falls in the same row.
  await tapControl(page, 'love');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-063',
    shot: 'match-mode--selected',
    screen: 'Match',
    state: 'selected',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode: 'G["Open committed stage/card"] → H["Answer the stage"]',
    fixture: 'MX-VIS-063',
    route: '/study',
  });
});

// MX-VIS-064 · Match · correct
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: G["Open committed stage/card"] → H["Answer the stage"]
test('MX-VIS-064 a matched pair reads correct', async ({ page }, testInfo) => {
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-064',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Match stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Match')).toBeVisible();

  // The kit tones left index 1 with right index 0 — `love` + `사랑`, a true pair. Both sit at those positions here, so the feedback lands on the same tiles. The flash is held until the next interaction (no timer), so the frame is stable.
  await tapControl(page, 'love');
  await tapControl(page, '사랑');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-064',
    shot: 'match-mode--correct',
    screen: 'Match',
    state: 'correct',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode: 'G["Open committed stage/card"] → H["Answer the stage"]',
    fixture: 'MX-VIS-064',
    route: '/study',
  });
});

// MX-VIS-065 · Match · wrong
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: G["Open committed stage/card"] → H["Answer the stage"]
test('MX-VIS-065 a mismatched pair reads wrong', async ({ page }, testInfo) => {
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-065',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Match stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Match')).toBeVisible();

  // The kit tones left index 1 with right index 1 — `love` + `학교`, which is not a pair. Same positions here.
  await tapControl(page, 'love');
  await tapControl(page, '학교');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-065',
    shot: 'match-mode--wrong',
    screen: 'Match',
    state: 'wrong',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode: 'G["Open committed stage/card"] → H["Answer the stage"]',
    fixture: 'MX-VIS-065',
    route: '/study',
  });
});

// MX-VIS-066 · Match · almost
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: G["Open committed stage/card"] → H["Answer the stage"]
//
// The register described this as "the near-miss cue (SM-MATCH-* classification)"
// — the duplicate-normalized-meaning outcome. It is not. `MatchMode.jsx` tones
// three tiles a side `matched` and shows 12/20: `almost` here means the board is
// almost *finished*, not that a pairing was almost right. A near-miss fixture
// (two cards sharing a normalized meaning) would have measured the wrong state.
test('MX-VIS-066 a board three pairs from done', async ({ page }, testInfo) => {
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-066',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Match stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Match')).toBeVisible();

  // Three of the five pairs, cleared the way a learner clears them.
  for (const [meaning, term] of [
    ['time', '시간'],
    ['food', '음식'],
    ['school', '학교'],
  ]) {
    await tapControl(page, meaning);
    await tapControl(page, term);
  }

  // The kit's frame is a board at rest: three pairs cleared, nothing selected
  // and nothing flashing. The last match leaves its pair flashing until the
  // next interaction, and every interaction used to leave a selection behind —
  // so this frame was unreachable until a selected tile could be cancelled.
  await tapControl(page, 'love');
  await tapControl(page, 'love');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-066',
    shot: 'match-mode--almost',
    screen: 'Match',
    state: 'almost',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode: 'G["Open committed stage/card"] → H["Answer the stage"]',
    fixture: 'MX-VIS-066',
    route: '/study',
  });
});

// MX-VIS-067 · Match · complete
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: H["Answer the stage"] → I["Stage complete"]
test('MX-VIS-067 clearing every pair completes the round', async ({
  page,
}, testInfo) => {
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-067',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Match stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Match')).toBeVisible();

  for (const [meaning, term] of [
    ['love', '사랑'],
    ['school', '학교'],
    ['food', '음식'],
    ['time', '시간'],
    ['friend', '친구'],
  ]) {
    await tapControl(page, meaning);
    await tapControl(page, term);
  }

  // The board is replaced by the round-complete state — the proof the journey
  // actually reached it, rather than capturing a board with one pair left.
  await expect(page.getByText('Round complete!')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-067',
    shot: 'match-mode--complete',
    screen: 'Match',
    state: 'complete',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode: 'H["Answer the stage"] → I["Stage complete"]',
    fixture: 'MX-VIS-067',
    route: '/study',
  });
});

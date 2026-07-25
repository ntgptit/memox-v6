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

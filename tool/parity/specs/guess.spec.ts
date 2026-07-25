import { expect, test } from '@playwright/test';
import { deepLinkEntry, expectRoute } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-051 · Guess · Waiting (no choice made)
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: A["Resume"] → B["Load snapshot + checkpoint + attempts"] →
//            F["Validate checkpoint"] → G["Open committed stage/card"]
test('MX-VIS-051 resumes into the Guess waiting stage', async ({
  page,
}, testInfo) => {
  // Resume genuinely starts at a deep link: the fixture seeds a committed
  // active newLearning session parked at the Guess stage (data), and reopening
  // the app at the study route is the resume entry node — the committed stage
  // (Guess) is opened from the checkpoint, not reached by shortcutting a start
  // flow through Review and Match.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-051',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Guess stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Guess')).toBeVisible();
  // The five seeded meanings render as the single-select options.
  await expect(page.getByText('school')).toBeVisible();
  await expect(page.getByText('hospital')).toBeVisible();
  await expect(page.getByText('library')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-051',
    shot: 'guess-mode--waiting',
    screen: 'Guess',
    state: 'waiting',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode:
      'A["Resume"] → B["Load snapshot + checkpoint + attempts"] → F["Validate checkpoint"] → G["Open committed stage/card"]',
    fixture: 'MX-VIS-051',
    route: '/study',
  });
});

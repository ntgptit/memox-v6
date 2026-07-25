import { expect, test } from '@playwright/test';
import { deepLinkEntry, expectRoute } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-053 · Fill · Waiting (empty input, before Check)
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: A["Resume"] → B["Load snapshot + checkpoint + attempts"] →
//            F["Validate checkpoint"] → G["Open committed stage/card"]
test('MX-VIS-053 resumes into the Fill waiting stage', async ({
  page,
}, testInfo) => {
  // Resume genuinely starts at a deep link: the fixture seeds a committed
  // active newLearning session parked at the Fill stage (data), and reopening
  // the app at the study route is the resume entry node.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-053',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Fill stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByRole('heading', { name: 'Fill' })).toBeVisible();
  // The meaning prompt shows; the term input is still empty (waiting state).
  await expect(page.getByText('friend')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Check' })).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-053',
    shot: 'fill-mode--waiting',
    screen: 'Fill',
    state: 'waiting',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode:
      'A["Resume"] → B["Load snapshot + checkpoint + attempts"] → F["Validate checkpoint"] → G["Open committed stage/card"]',
    fixture: 'MX-VIS-053',
    route: '/study',
  });
});

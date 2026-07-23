import { expect, test } from '@playwright/test';
import { deepLinkEntry, expectRoute } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-050 · Review · Browsing
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: A["Resume"] → B["Load snapshot + checkpoint + attempts"] →
//            F["Validate checkpoint"] → G["Open committed stage/card"]
test('MX-VIS-050 resumes into the Review browsing stage', async ({
  page,
}, testInfo) => {
  // Resume genuinely starts at a deep link: the fixture seeds a committed
  // active newLearning session (data), and reopening the app at the study
  // route is the resume entry node — the current stage (Review) is opened
  // from the committed checkpoint, not reached by shortcutting a start flow.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-050',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Review')).toBeVisible();
  await expect(page.getByText('school')).toBeVisible();
  await expect(page.getByText('Swipe to continue')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-050',
    shot: 'review-mode--browsing',
    screen: 'Review',
    state: 'browsing',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode:
      'A["Resume"] → B["Load snapshot + checkpoint + attempts"] → F["Validate checkpoint"] → G["Open committed stage/card"]',
    fixture: 'MX-VIS-050',
    route: '/study',
  });
});

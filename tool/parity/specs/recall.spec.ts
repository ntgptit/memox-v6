import { expect, test } from '@playwright/test';
import { deepLinkEntry, expectRoute } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-052 · Recall · Revealed (answer shown, self-grade offered)
// Master flow: docs/business/study-session/resume-study-session.md §3
// Flow node: A["Resume"] → B["Load snapshot + checkpoint + attempts"] →
//            F["Validate checkpoint"] → G["Open committed stage/card"]
test('MX-VIS-052 resumes into Recall and reveals the answer', async ({
  page,
}, testInfo) => {
  // Resume genuinely starts at a deep link: the fixture seeds a committed
  // active newLearning session parked at the Recall stage (data), and reopening
  // the app at the study route is the resume entry node.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    fixture: 'MX-VIS-052',
    route: '/study',
    justification:
      'resume-study-session §3 begins by reopening an app that holds a committed active session; the study route is that flow’s entry node (open committed stage/card), and the Recall stage is the committed checkpoint, not a bypass of the start flow.',
  });

  await expectRoute(page, '/study');
  // Role-based: the hint text also contains "Recall"/"Show", so match the
  // heading and the button, not any text.
  await expect(page.getByRole('heading', { name: 'Recall' })).toBeVisible();

  // The before-reveal state runs a live countdown, so it never settles. Reveal
  // the answer (the kit `revealed` state) first: that stops the timer, giving a
  // stable frame to compare, and exercises the real reveal interaction.
  await page.getByRole('button', { name: /Show/ }).click();
  await expect(page.getByText('friend')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Got it' })).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-052',
    shot: 'recall-mode--revealed',
    screen: 'Recall',
    state: 'revealed',
    masterFlow: 'docs/business/study-session/resume-study-session.md',
    flowNode:
      'A["Resume"] → B["Load snapshot + checkpoint + attempts"] → F["Validate checkpoint"] → G["Open committed stage/card"]',
    fixture: 'MX-VIS-052',
    route: '/study',
  });
});

import { expect, test } from '@playwright/test';
import { deepLinkEntry, expectRoute } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-054 · Study Result · Standard
// Master flow: docs/business/study-session/finalize-study-session.md §3
// Flow node: E["Commit completion idempotently"] → G["Study Result"]
test('MX-VIS-054 shows the standard study result', async ({
  page,
}, testInfo) => {
  // The result is the terminal node of the finalize flow; a finished, finalized
  // session is not an active row a resume could reach, so the committed summary
  // is supplied through parity_overrides (studyResultProvider). The study route
  // renders the result when a committed summary is present.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    fixture: 'MX-VIS-054',
    route: '/study',
    justification:
      'finalize-study-session §3 ends at the Study Result after committing completion; a finished session is not a resumable active row, so the committed summary is the seeded precondition and the study route renders it — the finalize orchestration itself is unit-tested.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Session complete')).toBeVisible();
  await expect(page.getByText('88%')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-054',
    shot: 'study-result--standard',
    screen: 'Study Result',
    state: 'standard',
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    flowNode: 'E["Commit completion idempotently"] → G["Study Result"]',
    fixture: 'MX-VIS-054',
    route: '/study',
  });
});

// MX-VIS-077 · Study Result · Finalize error
// Master flow: docs/business/study-session/finalize-study-session.md §3
// Flow node: E["Commit completion idempotently"] -- "Failure" --> F["Finalize error · Retry"]
test('MX-VIS-077 shows the finalize error with both ways on', async ({
  page,
}, testInfo) => {
  // §3's failure edge. The write that fails is the one a journey would have
  // to break to reach this, so it is pinned in parity_overrides rather than
  // staged — the same contract as the other failure states, and no invented
  // content: the screen renders its own copy over a real AsyncError.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    fixture: 'MX-VIS-077',
    route: '/study',
    justification:
      'finalize-study-session §3 branches to the finalize error when the commit fails; the failing commit is the precondition, and the finalize orchestration itself is unit-tested.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Couldn’t save your results')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Retry' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Not now' })).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-077',
    shot: 'study-result--finalize-error',
    screen: 'Study Result',
    state: 'finalize-error',
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    flowNode:
      'E["Commit completion idempotently"] -- "Failure" --> F["Finalize error · Retry"]',
    fixture: 'MX-VIS-077',
    route: '/study',
  });
});

// MX-VIS-080 · Study Result · Goal met
// Master flow: docs/business/study-goal/complete-daily-goal.md §3
// Flow node: D["Persist completion event"] → F["Goal-met result state"]
test('MX-VIS-080 shows the goal-met study result', async ({
  page,
}, testInfo) => {
  // Same terminal-state argument as MX-VIS-054: the result renders a committed
  // summary, and a finalized session is not an active row a resume could reach.
  // What this seeds is the contribution that crossed the target.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-goal/complete-daily-goal.md',
    fixture: 'MX-VIS-080',
    route: '/study',
    justification:
      'complete-daily-goal §3 routes the crossed-target transition to the goal-met result state; the committed summary carrying that contribution is the seeded precondition, and the transition itself is unit-tested.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Daily goal reached!')).toBeVisible();
  await expect(page.getByText('Daily goal completed!')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-080',
    shot: 'study-result--goal-met',
    screen: 'Study Result',
    state: 'goal-met',
    masterFlow: 'docs/business/study-goal/complete-daily-goal.md',
    flowNode: 'D["Persist completion event"] → F["Goal-met result state"]',
    fixture: 'MX-VIS-080',
    route: '/study',
  });
});

// MX-VIS-081 · Study Result · Finalizing
// Master flow: docs/business/study-session/finalize-study-session.md §3
// Flow node: A["Required queue complete"] --> B["Finalizing…"]
test('MX-VIS-081 shows the finalizing view', async ({ page }, testInfo) => {
  // §3 node B is the state while the commit is in flight, so the commit that
  // never resolves is the precondition rather than a staged screen — the same
  // contract as the other in-flight states.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    fixture: 'MX-VIS-081',
    route: '/study',
    justification:
      'finalize-study-session §3 holds at Finalizing while the commit runs; a commit pinned in flight is that state, and the finalize orchestration itself is unit-tested.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Saving your results…')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-081',
    shot: 'study-result--finalizing',
    screen: 'Study Result',
    state: 'finalizing',
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    flowNode: 'A["Required queue complete"] --> B["Finalizing…"]',
    fixture: 'MX-VIS-081',
    route: '/study',
  });
});

// MX-VIS-082 · Study Result · Retry finalize
// Master flow: docs/business/study-session/finalize-study-session.md §3
// Flow node: F["Finalize error · Retry"] --> B["Finalizing…"]
test('MX-VIS-082 shows the retrying finalize view', async ({
  page,
}, testInfo) => {
  // §9 lists `retry` as its own state beside `finalizing`: the same view,
  // reframed for a learner who has already watched one save fail.
  await deepLinkEntry(page, {
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    fixture: 'MX-VIS-082',
    route: '/study',
    justification:
      'finalize-study-session §6 sends Retry back through the same finalize request; the re-attempt held in flight is that state, and the retry identity itself is unit-tested.',
  });

  await expectRoute(page, '/study');
  await expect(page.getByText('Retrying…')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-082',
    shot: 'study-result--retry-finalize',
    screen: 'Study Result',
    state: 'retry-finalize',
    masterFlow: 'docs/business/study-session/finalize-study-session.md',
    flowNode: 'F["Finalize error · Retry"] --> B["Finalizing…"]',
    fixture: 'MX-VIS-082',
    route: '/study',
  });
});

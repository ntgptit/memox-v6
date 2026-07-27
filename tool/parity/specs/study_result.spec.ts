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

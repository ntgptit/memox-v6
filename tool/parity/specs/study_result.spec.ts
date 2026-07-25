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

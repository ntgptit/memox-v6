import { expect, test } from '@playwright/test';
import { enterFlow, expectRoute } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-001 · First-run landing · Default
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: C["First-use landing"]
test('MX-VIS-001 reaches the first-use landing from app launch', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-001',
  });

  // A → B(Fresh install? = Có) → C. The fixture supplies only the
  // empty-store precondition; the production first-run guard performs
  // the transition from app launch to the landing.
  await expectRoute(page, '/first-run');
  await expect(page.getByText('Build your learning library')).toBeVisible();
  await expect(
    page.getByRole('button', { name: 'Create your first deck' }),
  ).toBeVisible();
  await expect(page.getByRole('button', { name: 'Not now' })).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-001',
    shot: 'create-deck-firstrun--landing',
    screen: 'First-run landing',
    state: 'Default',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'C["First-use landing"]',
    fixture: 'MX-VIS-001',
    route: '/first-run',
  });
});

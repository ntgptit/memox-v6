import { expect, test } from '@playwright/test';
import { enterFlow } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-069 · Today · Loaded
// Master flow: docs/business/today-dashboard/load-today-dashboard.md §2
// Flow node: A["Open Today"] → B["Load Session/Due/Goal/Streak/Deck summaries"] → C{"Primary state"} → E["Start review"]
test('MX-VIS-069 opens Today onto the due-cards primary action', async ({
  page,
}, testInfo) => {
  // Launch *is* the flow's entry node: Today is the root destination, so the
  // dashboard composes on the first frame after the first-run gate declines
  // to fire. Nothing is navigated to — which is why the assertions below are
  // on content rather than on a route.
  await enterFlow(page, {
    masterFlow: 'docs/business/today-dashboard/load-today-dashboard.md',
    fixture: 'MX-VIS-069',
  });

  // Asserted on accessible names rather than text nodes. Flutter Web merges a
  // section's text into the name of the node that owns it, so `getByText`
  // finds nothing for copy that sits inside a card or a button — the same
  // reason the Library spec matches deck rows by role and name.

  // B → C → E: cards are due and no session is resumable, so the projection
  // picks Start review. The count is the whole library of the active pair,
  // which is what makes 24 the sum of the three decks below.
  await expect(
    page.getByRole('button', { name: /Continue studying 24 cards due/ }),
  ).toBeVisible();

  // The supporting sections, each from its own source: the goal bucket, the
  // streak day records, the Box-8 share, and the deck rows ordered by their
  // most recent grade.
  await expect(
    page.getByRole('group', { name: /Daily goal 70%/ }),
  ).toBeVisible();
  // The strip merges into one node, so both stats are asserted together.
  await expect(
    page.getByText('Today 12 day streak 55% library mastered'),
  ).toBeVisible();
  await expect(page.getByRole('group', { name: 'Recent decks' })).toBeVisible();
  await expect(
    page.getByRole('button', { name: /TOPIK I — Vocabulary/ }).first(),
  ).toBeVisible();

  // The greeting reads the app's zone, not the host's — the parity build pins
  // an offset that puts the fixed instant in the evening.
  await expect(page.getByText('Good evening')).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-069',
    shot: 'dashboard--loaded',
    screen: 'Today',
    state: 'Loaded',
    masterFlow: 'docs/business/today-dashboard/load-today-dashboard.md',
    flowNode:
      'A["Open Today"] → B["Load Session/Due/Goal/Streak/Deck summaries"] → C{"Primary state"} → E["Start review"]',
    fixture: 'MX-VIS-069',
    route: '/',
  });
});

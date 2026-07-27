import { expect, test } from '@playwright/test';
import { enterFlow, expectRoute, fillField, tapControl } from '../flows';
import { expectKitParity } from '../kit';

/**
 * Search parity (WBS 10.2; `search-decks.md`, `search-library-content.md`).
 *
 * The Search screen had no `MX-VIS` row at all until `int-105`, while four
 * rounds of this session changed it — so §6.5's parity bar had nothing to
 * apply to. The kit ships five `search--*` states; this covers the one the
 * changes actually landed on, and the rest stay registered and unmeasured
 * rather than pretended.
 */

// MX-VIS-084 · Search · Results
// Master flow: docs/business/search/search-library-content.md §2
// Flow node: A["Open Search"] → D["Normalize + search with token"] → G["Ranked Deck/Card results"]
test('MX-VIS-084 lists ranked results for a typed query', async ({
  page,
}, testInfo) => {
  // The fixture seeds the kit's own sample — three cards across two decks,
  // one hidden — because a ratio measured over different content measures the
  // content. Reached the way a learner reaches search: Library's app-bar
  // action, not a deep link.
  await enterFlow(page, {
    masterFlow: 'docs/business/search/search-library-content.md',
    fixture: 'MX-VIS-084',
  });

  await tapControl(page, 'Library');
  await tapControl(page, 'Search');
  await expectRoute(page, '/search');

  // The kit's own query: `하` matches all three seeded terms.
  await fillField(page, /Search/i, '하', { blur: false });
  await expect(page.getByText('to study').first()).toBeVisible();

  // The kit's list includes a hidden card, drawn dimmed rather than dropped.
  // `int-98` made that a filter the learner turns on — `search-rank-v1`'s
  // "Hidden/deleted content bị loại trước ranking" is the default — so the
  // state the shot photographs is reached with the chip on.
  await tapControl(page, 'Hidden');
  await expect(page.getByText('to do (auxiliary)').first()).toBeVisible();

  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-084',
    shot: 'search--results',
    screen: 'Search',
    state: 'Results',
    masterFlow: 'docs/business/search/search-library-content.md',
    flowNode:
      'A["Open Search"] → D["Normalize + search with token"] → G["Ranked Deck/Card results"]',
    fixture: 'MX-VIS-084',
  });
});

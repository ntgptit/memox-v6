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
  // The fixture seeds one leaf deck of five cards, reached the way a learner
  // reaches search: Library's app-bar action, not a deep link.
  await enterFlow(page, {
    masterFlow: 'docs/business/search/search-library-content.md',
    fixture: 'MX-VIS-084',
  });

  await tapControl(page, 'Library');
  await tapControl(page, 'Search');
  await expectRoute(page, '/search');

  // A query that matches a card term and nothing else, so the list is the
  // ranked-results state rather than the mixed one.
  await fillField(page, /Search/i, 'on', { blur: false });
  await expect(page.getByText('one').first()).toBeVisible();

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

import { expect, test } from '@playwright/test';
import { enterFlow, expectRoute, tapControl } from '../flows';
import { expectKitParity } from '../kit';

/**
 * Mode Picker parity (WBS 5.6.1; `study-deck.md` §4, §6).
 *
 * The screen was built in `int-109` and registered unmeasured, which
 * `int-105` calls bookkeeping. This is the number.
 */

// MX-VIS-090 · Mode Picker · Default
// Master flow: docs/business/deck/study-deck.md §3
// Flow node: A["Study Deck"] → B["Resolve eligible card scope"] → E["Mode Picker"]
test('MX-VIS-090 offers the practice modes over a deck scope', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/study-deck.md',
    fixture: 'MX-VIS-090',
  });

  // Reached the way §2 says a deck is studied: open the deck, then its own
  // settings — not a deep link (WBS §6.6).
  await tapControl(page, 'Library');
  await tapControl(page, 'Numbers & counting');
  const deckRoute = await expectRoute(page, /^\/deck\/[^/]+$/);
  await tapControl(page, 'Deck options');
  await tapControl(page, 'Practice');
  await expectRoute(page, `${deckRoute}/practice`);
  await expect(page.getByText('Card source').first()).toBeVisible();

  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-090',
    shot: 'mode-picker--default',
    screen: 'Mode Picker',
    state: 'Default',
    masterFlow: 'docs/business/deck/study-deck.md',
    flowNode:
      'A["Study Deck"] → B["Resolve eligible card scope"] → E["Mode Picker"]',
    fixture: 'MX-VIS-090',
  });
});

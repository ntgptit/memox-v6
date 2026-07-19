import { expect, test } from '@playwright/test';
import {
  enterFlow,
  expectRoute,
  fillField,
  holdDemoFrame,
  tapControl,
} from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// MX-VIS-018 · Library · Empty
// Master flow: docs/business/deck/browse-nested-decks.md §3
// Flow node: M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → Q["Library · empty"]
test('MX-VIS-018 reaches the empty Library from a root destination', async ({
  page,
}, testInfo) => {
  // The fixture seeds an active language pair only, so the first-run
  // gate stays closed and launch settles on the Today root destination.
  // Library is reached the way a user reaches it: by tapping its tab.
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    fixture: 'MX-VIS-018',
  });

  // Launch settles on Today. This is asserted by content, not by route:
  // the initial location is reached without a navigation, so go_router
  // has not written a hash yet and the URL route is still empty.
  await expect(page.getByText('MemoX Home')).toBeVisible();

  // M → N: the tab entry. This also asserts the persistent tab bar is
  // present on a root destination that is not Library, which is the
  // whole point of the shell owning it.
  await tapControl(page, 'Library');
  await expectRoute(page, '/library');

  // N → O → Q: no root deck, so the empty branch renders. `Build your
  // learning library` is shared with the first-run landing, so the
  // route assertion above is what distinguishes the two screens.
  await expect(page.getByText('Build your learning library')).toBeVisible();
  await expect(
    page.getByText('Create a deck or import cards to get started.'),
  ).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-018',
    shot: 'library--empty',
    screen: 'Library',
    state: 'Empty',
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    flowNode:
      'M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → Q["Library · empty"]',
    fixture: 'MX-VIS-018',
    route: '/library',
  });

  // Q → T → S: the capture is an intermediate node. The journey is only
  // complete once the empty branch has been left through its primary
  // action and the created deck is visible in the reactive root list.
  await tapControl(page, 'Create deck');

  // The field label reaches the browser as the input's accessible name,
  // not as a text node, so the dialog is detected through its textbox.
  const nameField = page.getByRole('textbox', { name: /Deck name/i });
  await expect(nameField).toBeVisible();

  await fillField(page, /Deck name/i, 'Beginner Grammar');

  // The empty-state CTA and the dialog's submit share the `Create deck`
  // label, and Flutter keeps the route beneath a dialog in the semantics
  // tree. Submit through the last match — the dialog is mounted above the
  // screen — and let the assertions below prove the right one was hit.
  await page.getByRole('button', { name: 'Create deck' }).last().click();

  await expect(nameField).toHaveCount(0);
  await expect(page.getByText('Beginner Grammar')).toBeVisible();
  await expect(page.getByText('Build your learning library')).toBeHidden();
  await expectRoute(page, '/library');
  await holdDemoFrame(page);
});

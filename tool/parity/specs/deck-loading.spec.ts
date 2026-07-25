import { expect, test, type Page } from '@playwright/test';
import { enterFlow, expectRoute, tapControl } from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

// The two deck-detail loading states. Both fixtures pin only the card
// stream on a controller that never emits, so the capture is a still
// frame rather than a race against the real read finishing — the same
// in-flight contract MX-VIS-011 uses. The child-deck stream still
// resolves, which is what lets the screen tell the two kit compositions
// apart.

/**
 * Asserts a deck row for [name] is on screen.
 *
 * A deck row carries a trailing study action, which makes it a parent
 * semantics node rather than a leaf — Flutter Web then exposes the row's
 * name as an `aria-label` instead of as rendered text, so `getByText`
 * finds nothing. Matching the accessible name is also what this harness
 * asserts everywhere else: it is what a screen reader announces.
 */
async function expectDeckRow(page: Page, name: string): Promise<void> {
  await expect(page.getByRole('button', { name }).first()).toBeVisible();
}

// MX-VIS-037 · Deck detail — parent branch · Loading
// Master flow: docs/business/deck/browse-nested-decks.md §3
// Flow node: M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → S["Library · root deck list"] → A["Open Parent"] → B["Load path + direct children + aggregate counts"]
test('MX-VIS-037 reaches the parent branch while its cards are still loading', async ({
  page,
}, testInfo) => {
  // Seeded: an active pair and one root deck that owns four child decks.
  // Data only — the deck is reached by tapping through Library, never by
  // deep-linking to its route.
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    fixture: 'MX-VIS-037',
  });

  // Launch settles on Today; Library is entered the way a user enters it.
  await tapControl(page, 'Library');
  await expectRoute(page, '/library');

  // O → S: the seeded root deck is listed.
  await expectDeckRow(page, 'Korean TOPIK I');

  // S → A → B: opening the deck starts the load. The card stream never
  // emits, so the screen holds at B.
  await tapControl(page, 'Korean TOPIK I');
  await expectRoute(page, '/deck/fx-parent');

  // Wait for arrival before capturing. `Deck options` only exists on the
  // deck-detail app bar, so asserting it proves the push transition has
  // finished — capturing straight after the tap catches a frame mid-push,
  // which is not a state the kit has a shot of.
  await expect(
    page.getByRole('button', { name: 'Deck options' }),
  ).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-037',
    shot: 'subdeck-list--loading',
    screen: 'Deck detail — parent branch',
    state: 'Loading',
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    flowNode:
      'M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → S["Library · root deck list"] → A["Open Parent"] → B["Load path + direct children + aggregate counts"]',
    fixture: 'MX-VIS-037',
    route: '/deck/fx-parent',
  });

  // B is an intermediate node, so the capture is not the end of the
  // journey. A load that never resolves must still not be a trap: the
  // contextual app bar returns to the root deck list, which is the
  // observable terminal outcome for this branch.
  await tapControl(page, 'Back');
  await expectRoute(page, '/library');
  await expectDeckRow(page, 'Korean TOPIK I');
});

// MX-VIS-043 · Deck detail — leaf branch · Loading
// Master flow: docs/business/deck/browse-nested-decks.md §3
// Flow node: M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → S["Library · root deck list"] → A["Open Parent"] → B["Load path + direct children + aggregate counts"] → C{"Result"} -- "Leaf" --> K["Card list"]
test('MX-VIS-043 reaches the leaf branch while its cards are still loading', async ({
  page,
}, testInfo) => {
  // Seeded: an active pair and one root deck that owns cards and no child
  // decks. Having no children is what resolves the branch to Leaf.
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    fixture: 'MX-VIS-043',
  });

  await tapControl(page, 'Library');
  await expectRoute(page, '/library');

  await expectDeckRow(page, 'Numbers & counting');

  await tapControl(page, 'Numbers & counting');
  await expectRoute(page, '/deck/fx-leaf');
  await expect(
    page.getByRole('button', { name: 'Deck options' }),
  ).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-043',
    shot: 'flashcard-list--loading',
    screen: 'Deck detail — leaf branch',
    state: 'Loading',
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    flowNode:
      'M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → S["Library · root deck list"] → A["Open Parent"] → B["Load path + direct children + aggregate counts"] → C{"Result"} -- "Leaf" --> K["Card list"]',
    fixture: 'MX-VIS-043',
    route: '/deck/fx-leaf',
  });

  await tapControl(page, 'Back');
  await expectRoute(page, '/library');
  await expectDeckRow(page, 'Numbers & counting');
});

// MX-VIS-036 · Deck detail — parent branch · Loaded
// Master flow: docs/business/deck/browse-nested-decks.md §3
// Flow node: M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → S["Library · root deck list"] → A["Open Parent"] → B["Load path + direct children + aggregate counts"] → C{"Result"} -- "Loaded" --> D["Child deck list"]
test('MX-VIS-036 opens a parent deck onto its child list', async ({
  page,
}, testInfo) => {
  // Seeded: a parent whose five children carry the shot's exact counts, so
  // the aggregate header is produced by the data rather than asserted.
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    fixture: 'MX-VIS-036',
  });

  await tapControl(page, 'Library');
  await expectRoute(page, '/library');
  await expectDeckRow(page, 'Korean TOPIK I');

  await tapControl(page, 'Korean TOPIK I');
  await expectRoute(page, '/deck/fx-loaded');

  // C → D: the child list, under the same FilterRow the Library root shows
  // (kit `SubdeckList.jsx` renders `crumbs + filter + list`).
  await expect(page.getByRole('button', { name: 'A–Z' })).toBeVisible();
  await expectDeckRow(page, 'Greetings & introductions');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-036',
    shot: 'subdeck-list--loaded',
    screen: 'Deck detail — parent branch',
    state: 'Loaded',
    masterFlow: 'docs/business/deck/browse-nested-decks.md',
    flowNode:
      'M["Root destination · tap Library tab"] → N["Load root decks của active pair"] → O{"Root load result"} → S["Library · root deck list"] → A["Open Parent"] → B["Load path + direct children + aggregate counts"] → C{"Result"} -- "Loaded" --> D["Child deck list"]',
    fixture: 'MX-VIS-036',
    route: '/deck/fx-loaded',
  });

  // D → H: the list is only proven navigable by opening a child, and Back
  // must return here rather than out to the Library.
  await tapControl(page, 'Greetings & introductions');
  await expectRoute(page, '/deck/fx-l1');
  await tapControl(page, 'Back');
  await expectRoute(page, '/deck/fx-loaded');
  await expectDeckRow(page, 'Greetings & introductions');
});

import { expect, test, type Page } from '@playwright/test';
import {
  enterFlow,
  expectRoute,
  fillField,
  holdDemoFrame,
  tapControl,
} from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

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

// MX-VIS-049 · Card Editor · Create
// Master flow: docs/business/flashcard/create-flashcard.md §3
// Flow node: A["Open Card Editor"] → B["Load target + Language Pair"] → C["Enter term / meaning / optional content"]
// Prerequisite flow: docs/business/deck/create-deck.md §3
// Prerequisite nodes: A["App launch hoàn tất"] → C["First-use landing"] → E["Step 1 · Learning setup"] → H["Step 2 · First Deck setup"] → K["Library · first deck ready"] → Q["User chủ động mở deck"] → U["Empty deck"]
test('MX-VIS-049 fresh launch creates the first Deck and saves the first Card', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/flashcard/create-flashcard.md',
    prerequisiteFlows: ['docs/business/deck/create-deck.md'],
    fixture: 'MX-VIS-049',
  });

  // create-deck.md: app launch → fresh install → first-use landing.
  await expectRoute(page, '/first-run');
  await tapControl(page, 'Create your first deck');
  await expectRoute(page, '/first-run/language');

  // Step 1: create and select the required Language Pair through the
  // two visible selector sheets.
  await tapControl(page, 'What are you learning?');
  await tapControl(page, 'Korean');
  await tapControl(page, 'Show meanings in');
  await tapControl(page, 'English');
  await tapControl(page, 'Continue');
  await expectRoute(page, '/first-run/deck');

  // Step 2: create the first empty Deck. Success must land in Library;
  // the user then explicitly opens it from the contextual callout.
  await fillField(page, /Deck name/i, 'Beginner Grammar');
  await tapControl(page, 'Create deck');
  await expectRoute(page, '/library');
  await expectDeckRow(page, 'Beginner Grammar');
  // The first-deck callout that used to carry an `Open deck` action was
  // superseded (owner, 2026-07-21, MX-VIS-021): first-run success now
  // returns to the plain Library deck list per `create-deck.md` §7, so the
  // deck is opened from its row like any other.
  await tapControl(page, 'Beginner Grammar');
  const deckRoute = await expectRoute(page, /^\/deck\/[^/]+$/);

  // Empty Deck → Add card enters create-flashcard.md at A. The production
  // editor loads the target/pair at B and settles on the form at C.
  await tapControl(page, 'Add card');
  const editorRoute = `${deckRoute}/new-card`;
  await expectRoute(page, editorRoute);
  await expect(page.getByText('New card')).toBeVisible();
  await expect(page.getByRole('textbox', { name: /한국어/ })).toBeVisible();
  await expect(page.getByRole('textbox', { name: /English/i })).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-049',
    shot: 'flashcard-editor--create',
    screen: 'Card Editor',
    state: 'Create',
    masterFlow: 'docs/business/flashcard/create-flashcard.md',
    flowNode:
      'A["Open Card Editor"] → B["Load target + Language Pair"] → C["Enter term / meaning / optional content"]',
    fixture: 'MX-VIS-049',
    route: editorRoute,
  });

  // C → D(valid) → F(no duplicate) → H(atomic save) → J(success).
  // The test is incomplete until the committed Card is visible in the
  // reactive Leaf list after the Editor closes.
  await fillField(page, /한국어/, '안녕하세요');
  await fillField(page, /English/i, 'Hello');
  await tapControl(page, 'Save');
  await expectRoute(page, deckRoute);
  await expect(page.getByText('안녕하세요')).toBeVisible();
  await expect(page.getByText('Hello')).toBeVisible();
  await holdDemoFrame(page);
});

/**
 * Walks the first-run prerequisite up to an open, empty deck and returns its
 * route. Shared by every Card Editor state: the editor's precondition is a
 * Language Pair and a target Deck, and all three of these journeys build them
 * through the production first-run UI rather than seeding them.
 */
async function openFirstDeck(page: Page): Promise<string> {
  await expectRoute(page, '/first-run');
  await tapControl(page, 'Create your first deck');
  await expectRoute(page, '/first-run/language');
  await tapControl(page, 'What are you learning?');
  await tapControl(page, 'Korean');
  await tapControl(page, 'Show meanings in');
  await tapControl(page, 'English');
  await tapControl(page, 'Continue');
  await expectRoute(page, '/first-run/deck');
  await fillField(page, /Deck name/i, 'Beginner Grammar');
  await tapControl(page, 'Create deck');
  await expectRoute(page, '/library');
  await expectDeckRow(page, 'Beginner Grammar');
  await tapControl(page, 'Beginner Grammar');
  return expectRoute(page, /^\/deck\/[^/]+$/);
}

// MX-VIS-060 · Card Editor · Additional translation
// Master flow: docs/business/flashcard/manage-card-translations.md §3
// Flow node: A["Open card translations"] → B["Add translation"] → C["Persisted · listed"]
// Prerequisite flow: docs/business/flashcard/create-flashcard.md §3
// Prerequisite nodes: A["Open Card Editor"] → H["Atomic save"] → J["Success · card in list"]
test('MX-VIS-060 a translation added under Meaning persists and lists', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/flashcard/manage-card-translations.md',
    prerequisiteFlows: ['docs/business/flashcard/create-flashcard.md'],
    fixture: 'MX-VIS-060',
  });

  const deckRoute = await openFirstDeck(page);

  await tapControl(page, 'Add card');
  await expectRoute(page, `${deckRoute}/new-card`);
  await fillField(page, /한국어/, '안녕하세요');
  await fillField(page, /English/i, 'Hello');
  await fillField(page, /Tags/i, '#TOPIK_I, #인사');
  await tapControl(page, 'Save');
  await expectRoute(page, deckRoute);
  await expect(page.getByText('안녕하세요')).toBeVisible();

  await tapControl(page, '안녕하세요');
  await tapControl(page, 'Edit');
  const editorRoute = await expectRoute(
    page,
    /^\/deck\/[^/]+\/card\/[^/]+\/edit$/,
  );

  // Disclosed the way a user reaches it — the `+` on the Meaning label —
  // because the kit keeps the resting form Term → Meaning → Tags. That
  // control is named "Add another meaning" and the one that commits a typed
  // translation is named "Add translation": they are different actions and
  // must not share an accessible name.
  await tapControl(page, 'Add another meaning');
  await fillField(page, /Add translation/i, 'Xin chào');
  await tapControl(page, 'Add translation');

  await expect(page.getByText('Xin chào')).toBeVisible();

  // Same reason as MX-VIS-059: the kit leaves Save at full strength in this
  // view, while this app disables it until the *card content* diverges — and
  // a translation persists on its own, so adding one leaves the form clean.
  // Amending the meaning to the shot's text makes the comparison like-for-
  // like instead of a dimmed control against an enabled one.
  await fillField(page, /English/i, 'Hello (formal)');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-060',
    shot: 'flashcard-editor--additional-translation',
    screen: 'Card Editor',
    state: 'Additional translation',
    masterFlow: 'docs/business/flashcard/manage-card-translations.md',
    flowNode:
      'A["Open card translations"] → B["Add translation"] → C["Persisted · listed"]',
    fixture: 'MX-VIS-060',
    route: editorRoute,
  });

  await holdDemoFrame(page);
});

// MX-VIS-059 · Card Editor · Edit
// Master flow: docs/business/flashcard/edit-flashcard.md §3
// Flow node: A["Open card for edit"] → B["Load current content + version"] → C["Edit fields"]
// Prerequisite flow: docs/business/flashcard/create-flashcard.md §3
// Prerequisite nodes: A["Open Card Editor"] → H["Atomic save"] → J["Success · card in list"]
test('MX-VIS-059 reopening a saved card prefills it for editing', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/flashcard/edit-flashcard.md',
    prerequisiteFlows: ['docs/business/flashcard/create-flashcard.md'],
    fixture: 'MX-VIS-059',
  });

  const deckRoute = await openFirstDeck(page);

  // Edit has a precondition a fixture cannot fake: a committed card with a
  // content version to guard the save against. So it is created through the
  // real path first.
  // The card is built to match the one the kit draws in this state — meaning
  // "Hello (formal)", tagged #TOPIK_I and #인사 — because a parity capture
  // compares content as well as composition, and every one of those is
  // something a user types on this very form.
  await tapControl(page, 'Add card');
  await expectRoute(page, `${deckRoute}/new-card`);
  await fillField(page, /한국어/, '안녕하세요');
  await fillField(page, /English/i, 'Hello');
  await fillField(page, /Tags/i, '#TOPIK_I, #인사');
  await tapControl(page, 'Save');
  await expectRoute(page, deckRoute);
  await expect(page.getByText('안녕하세요')).toBeVisible();

  await tapControl(page, '안녕하세요');
  await tapControl(page, 'Edit');
  const editorRoute = await expectRoute(
    page,
    /^\/deck\/[^/]+\/card\/[^/]+\/edit$/,
  );

  // edit-flashcard.md §3: the form arrives prefilled from the stored card,
  // and Save stays disabled until something actually diverges (§6).
  //
  // The prefill is asserted by the pixel comparison below, not by
  // `toHaveValue`. On CanvasKit the labelled proxy carries only what the
  // engine editor has *typed*; text placed in a controller before the field
  // was ever focused never reaches the DOM node, so the proxy reads empty
  // while the canvas paints the value correctly. The controllers themselves
  // are covered by the widget test "prefills the card and keeps a clean Save
  // disabled".
  await expect(page.getByText('Edit card')).toBeVisible();

  // The kit's edit state is a *dirty* edit — its JSX sets
  // `isDirty = view === 'edit'` and leaves Save at full strength, where this
  // app disables Save until something diverges (`edit-flashcard.md` §6). So
  // the card is saved as "Hello" and amended here to the "Hello (formal)" the
  // shot shows: the rendered content matches and the form is legitimately
  // dirty, instead of comparing an enabled control against a disabled one.
  await fillField(page, /English/i, 'Hello (formal)');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-059',
    shot: 'flashcard-editor--edit',
    screen: 'Card Editor',
    state: 'Edit',
    masterFlow: 'docs/business/flashcard/edit-flashcard.md',
    flowNode:
      'A["Open card for edit"] → B["Load current content + version"] → C["Edit fields"]',
    fixture: 'MX-VIS-059',
    route: editorRoute,
  });

  await holdDemoFrame(page);
});

// MX-VIS-058 · Card Editor · Validation
// Master flow: docs/business/flashcard/create-flashcard.md §3
// Flow node: C["Enter term / meaning / optional content"] → D["Invalid · inline field errors"]
test('MX-VIS-058 clearing a required field shows its inline error', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/flashcard/create-flashcard.md',
    fixture: 'MX-VIS-058',
  });

  const deckRoute = await openFirstDeck(page);
  await tapControl(page, 'Add card');
  const editorRoute = `${deckRoute}/new-card`;
  await expectRoute(page, editorRoute);

  // A required field reports its error once *touched*, not on arrival — a
  // pristine form must not greet the user with two complaints. So the way to
  // reach the kit's both-errors state is the way a user reaches it: type
  // something into each field, then clear it again.
  await fillField(page, /한국어/, '안');
  await fillField(page, /한국어/, '');
  await fillField(page, /English/i, 'H');
  await fillField(page, /English/i, '');

  await expect(page.getByText('Enter a term.')).toBeVisible();
  await expect(page.getByText('Enter a meaning.')).toBeVisible();

  // Move focus off the text fields before capturing. `fillField` blurs with
  // Tab, and in this form Tab lands on the *next* text field — so a caret
  // keeps blinking and three consecutive settles never agree. The deck
  // context pill is inert text, so clicking it parks focus harmlessly.
  await page.getByText('Beginner Grammar').first().click({ force: true });

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-058',
    shot: 'flashcard-editor--validation',
    screen: 'Card Editor',
    state: 'Validation',
    masterFlow: 'docs/business/flashcard/create-flashcard.md',
    flowNode:
      'C["Enter term / meaning / optional content"] → D["Invalid · inline field errors"]',
    fixture: 'MX-VIS-058',
    route: editorRoute,
  });

  await holdDemoFrame(page);
});

// MX-VIS-056 · Card Editor · Submitting
// Master flow: docs/business/flashcard/create-flashcard.md §3
// Flow node: A["Open Card Editor"] → C["Enter term / meaning / optional content"] → H["Atomic save"]
test('MX-VIS-056 a save in flight freezes the form and shows Saving', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/flashcard/create-flashcard.md',
    fixture: 'MX-VIS-056',
  });

  const deckRoute = await openFirstDeck(page);
  await tapControl(page, 'Add card');
  const editorRoute = `${deckRoute}/new-card`;
  await expectRoute(page, editorRoute);

  await fillField(page, /한국어/, '안녕하세요');
  await fillField(page, /English/i, 'Hello');
  await tapControl(page, 'Save');

  // The write is pinned on a completer nothing resolves, so this frame is
  // held rather than raced: the fields freeze and Save reads "Saving…".
  //
  // Exact match, not /Saving/i: the create-another toggle is announced as
  // "Create another card after saving" and matches that pattern too.
  await expect(
    page.getByRole('button', { name: 'Saving…', exact: true }),
  ).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-056',
    shot: 'flashcard-editor--submitting',
    screen: 'Card Editor',
    state: 'Submitting',
    masterFlow: 'docs/business/flashcard/create-flashcard.md',
    flowNode:
      'A["Open Card Editor"] → C["Enter term / meaning / optional content"] → H["Atomic save"]',
    fixture: 'MX-VIS-056',
    route: editorRoute,
  });

  await holdDemoFrame(page);
});

// MX-VIS-057 · Card Editor · Submit error
// Master flow: docs/business/flashcard/edit-flashcard.md §3
// Flow node: D["Save edited card"] → F["Save failure · edits retained · retry"]
// Prerequisite flow: docs/business/flashcard/create-flashcard.md §3
// Prerequisite nodes: A["Open Card Editor"] → H["Atomic save"] → J["Success · card in list"]
test('MX-VIS-057 a failed edit keeps the changes and offers retry', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/flashcard/edit-flashcard.md',
    prerequisiteFlows: ['docs/business/flashcard/create-flashcard.md'],
    fixture: 'MX-VIS-057',
  });

  const deckRoute = await openFirstDeck(page);

  // The kit draws this state in the *edit* variant — its app bar reads "Edit
  // card", because the kit gives "New card" only to the create view. So the
  // journey saves a card first and then re-opens it, rather than failing a
  // create and comparing a "New card" bar against an "Edit card" shot.
  await tapControl(page, 'Add card');
  await expectRoute(page, `${deckRoute}/new-card`);
  await fillField(page, /한국어/, '안녕하세요');
  await fillField(page, /English/i, 'Hello');
  await tapControl(page, 'Save');
  await expectRoute(page, deckRoute);
  await expect(page.getByText('안녕하세요')).toBeVisible();

  // Tapping a card row opens its lifecycle sheet; `Edit` is the control,
  // `Edit card` is the screen title it leads to.
  await tapControl(page, '안녕하세요');
  await tapControl(page, 'Edit');
  const editorRoute = await expectRoute(
    page,
    /^\/deck\/[^/]+\/card\/[^/]+\/edit$/,
  );
  await expect(page.getByText('Edit card')).toBeVisible();

  await fillField(page, /English/i, 'Hi there');
  await tapControl(page, 'Save');

  // edit-flashcard.md: a failed save is recoverable in place — the editor
  // stays open, the banner explains, and the edited draft survives.
  await expect(page.getByRole('textbox', { name: /English/i })).toHaveValue(
    'Hi there',
  );
  await expectRoute(page, editorRoute);

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-057',
    shot: 'flashcard-editor--submit-error',
    screen: 'Card Editor',
    state: 'Submit error',
    masterFlow: 'docs/business/flashcard/edit-flashcard.md',
    flowNode:
      'D["Save edited card"] → F["Save failure · edits retained · retry"]',
    fixture: 'MX-VIS-057',
    route: editorRoute,
  });

  await holdDemoFrame(page);
});

// MX-VIS-055 · Card Editor · Duplicate
// Master flow: docs/business/flashcard/resolve-duplicate-flashcard.md §3
// Flow node: A["Duplicate candidate"] → B["Compare draft/source and existing"] → C{"Decision"}
// Prerequisite flow: docs/business/flashcard/create-flashcard.md §3
// Prerequisite nodes: A["Open Card Editor"] → C["Enter term / meaning / optional content"] → D["Valid"] → F["Duplicate candidate found"]
test('MX-VIS-055 a second card with an existing term raises the duplicate review', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/flashcard/resolve-duplicate-flashcard.md',
    prerequisiteFlows: ['docs/business/flashcard/create-flashcard.md'],
    fixture: 'MX-VIS-055',
  });

  // The duplicate state needs a deck that already holds the card being
  // duplicated, and detection reads normalized content the real create path
  // writes — so the first card is saved through production UI, not seeded.
  const deckRoute = await openFirstDeck(page);

  // First card: the one the duplicate will collide with.
  await tapControl(page, 'Add card');
  const editorRoute = `${deckRoute}/new-card`;
  await expectRoute(page, editorRoute);
  await fillField(page, /한국어/, '안녕하세요');
  await fillField(page, /English/i, 'Hello');
  await tapControl(page, 'Save');
  await expectRoute(page, deckRoute);
  await expect(page.getByText('안녕하세요')).toBeVisible();

  // Re-enter from the populated leaf. This entry point shipped disabled
  // (`onPressed: null`) until 2026-07-25, which made every duplicate state
  // unreachable in the product, not merely untested.
  await tapControl(page, 'Add card');
  await expectRoute(page, editorRoute);

  // resolve-duplicate-flashcard.md §1: detection runs on normalized content
  // before commit and never mutates. The draft survives the review (§1), so
  // the fields still hold what was typed.
  await fillField(page, /한국어/, '안녕하세요');
  await fillField(page, /English/i, 'Hi there');
  await tapControl(page, 'Save');

  // §5: the banner is the entry point — View existing (emphasized) and Add
  // anyway (ghost override). The 4-way compare/merge surface is authored at
  // implementation time per specs/flashcard-editor.md, so it is not part of
  // this state.
  await expect(page.getByText(/already exists/i)).toBeVisible();
  await expectRoute(page, editorRoute);

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-055',
    shot: 'flashcard-editor--duplicate',
    screen: 'Card Editor',
    state: 'Duplicate',
    masterFlow: 'docs/business/flashcard/resolve-duplicate-flashcard.md',
    flowNode:
      'A["Duplicate candidate"] → B["Compare draft/source and existing"] → C{"Decision"}',
    fixture: 'MX-VIS-055',
    route: editorRoute,
  });

  await holdDemoFrame(page);
});

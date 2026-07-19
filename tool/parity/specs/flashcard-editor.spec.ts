import { expect, test } from '@playwright/test';
import {
  enterFlow,
  expectRoute,
  fillField,
  holdDemoFrame,
  tapControl,
} from '../flows';
import { expectKitParity, expectStableCapture } from '../kit';

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
  await expect(page.getByText('Beginner Grammar')).toBeVisible();
  await tapControl(page, 'Open deck');
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

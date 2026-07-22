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
 * The two first-run wizard steps (`create-deck.md` §3, nodes E and H).
 *
 * Every test here re-walks the wizard from app launch rather than sharing
 * state: the wizard is the only way into these steps, and proving it is
 * reachable is half of what the gate is for.
 */

/**
 * The kit shots type real content into the form, and the gate is a pixel
 * diff, so the spec must use the kit's exact strings rather than
 * placeholders of its own.
 */
const KIT_DECK_NAME = 'Korean TOPIK I';
const KIT_DECK_DESCRIPTION = 'Vocabulary and grammar for TOPIK I';

/** The kit's own over-long name (`CreateDeckFirstRun.jsx` LONG_NAME). */
const KIT_LONG_DECK_NAME =
  'Advanced Korean Honorific Speech Registers and Formal Writing for the Full TOPIK II Band';

/** A → B(Fresh install) → C → D("Create first deck") → E. */
async function reachStepOne(page: Page): Promise<void> {
  await expectRoute(page, '/first-run');
  await tapControl(page, 'Create your first deck');
  await expectRoute(page, '/first-run/language');
}

/** E: the kit's canonical pair, selected through both sheets. */
async function selectKitLanguagePair(page: Page): Promise<void> {
  await tapControl(page, 'What are you learning?');
  await tapControl(page, 'Korean');
  await tapControl(page, 'Show meanings in');
  await tapControl(page, 'Vietnamese');
}

/** E → H. */
async function reachStepTwo(page: Page): Promise<void> {
  await tapControl(page, 'Continue');
  await expectRoute(page, '/first-run/deck');
}

/**
 * H → I → J("Thành công") → K. Success returns to the Library deck list
 * with the new deck in it (create-deck.md §7); asserting the deck is
 * visible there is what makes each capture part of a journey.
 */
async function submitDeckAndExpectLibrary(
  page: Page,
  name: string,
): Promise<void> {
  await tapControl(page, 'Create deck');
  await expectRoute(page, '/library');
  await expect(page.getByText(name)).toBeVisible();
}

// MX-VIS-004 · First-run language (step 1) · Complete selection
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: E["Step 1 · Learning setup"]
test('MX-VIS-004 completes the step 1 language selection', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-004',
  });

  await reachStepOne(page);
  await selectKitLanguagePair(page);

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-004',
    shot: 'create-deck-firstrun--step1',
    screen: 'First-run language (step 1)',
    state: 'Complete selection',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'E["Step 1 · Learning setup"]',
    fixture: 'MX-VIS-004',
    route: '/first-run/language',
  });

  // The selection is only proven complete if it lets the wizard advance.
  await reachStepTwo(page);
  await fillField(page, /Deck name/i, KIT_DECK_NAME);
  await submitDeckAndExpectLibrary(page, KIT_DECK_NAME);
  await holdDemoFrame(page);
});

// MX-VIS-009 · First-run deck setup (step 2) · Name filled
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: H["Step 2 · First Deck setup"]
test('MX-VIS-009 fills the first deck name in step 2', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-009',
  });

  await reachStepOne(page);
  await selectKitLanguagePair(page);
  await reachStepTwo(page);
  await fillField(page, /Deck name/i, KIT_DECK_NAME);

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-009',
    shot: 'create-deck-firstrun--step2',
    screen: 'First-run deck setup (step 2)',
    state: 'Name filled',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'H["Step 2 · First Deck setup"]',
    fixture: 'MX-VIS-009',
    route: '/first-run/deck',
  });

  await submitDeckAndExpectLibrary(page, KIT_DECK_NAME);
  await holdDemoFrame(page);
});

// MX-VIS-010 · First-run deck setup (step 2) · Optional section expanded
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: H["Step 2 · First Deck setup"]
test('MX-VIS-010 expands the optional section in step 2', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-010',
  });

  await reachStepOne(page);
  await selectKitLanguagePair(page);
  await reachStepTwo(page);
  await fillField(page, /Deck name/i, KIT_DECK_NAME);

  // The section is collapsed by default and its control toggles to `Hide`,
  // so the label doubles as the assertion that it actually expanded.
  await tapControl(page, 'Show');
  await expect(page.getByRole('button', { name: 'Hide' })).toBeVisible();

  // The kit shot has the description already typed, so the capture belongs
  // after it is filled, not before.
  await fillField(page, /Description/i, KIT_DECK_DESCRIPTION);

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-010',
    shot: 'create-deck-firstrun--step2-optional',
    screen: 'First-run deck setup (step 2)',
    state: 'Optional section expanded',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'H["Step 2 · First Deck setup"]',
    fixture: 'MX-VIS-010',
    route: '/first-run/deck',
  });

  await submitDeckAndExpectLibrary(page, KIT_DECK_NAME);
  await holdDemoFrame(page);
});

// MX-VIS-012 · First-run deck setup (step 2) · Submit failure banner
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: H["Step 2 · First Deck setup"] → I["Creating…"] → J{"Kết quả"} -- "Lỗi" --> H
test('MX-VIS-012 keeps the draft and offers a retry when create fails', async ({
  page,
}, testInfo) => {
  // The fixture breaks the deck write path before the user acts; the
  // journey below is the production one, all the way to the real button.
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-012',
  });

  await reachStepOne(page);
  await selectKitLanguagePair(page);
  await reachStepTwo(page);
  await fillField(page, /Deck name/i, KIT_DECK_NAME, { blur: false });

  // H → I → J("Lỗi") → back to H with the draft intact.
  await tapControl(page, 'Create deck');
  await expectRoute(page, '/first-run/deck');
  await expect(
    page.getByText('Couldn’t create the deck. Your information is still here.'),
  ).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-012',
    shot: 'create-deck-firstrun--submit-failure',
    screen: 'First-run deck setup (step 2)',
    state: 'Submit failure banner',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'J{"Kết quả"} -- "Lỗi" --> H["Step 2 · First Deck setup"]',
    fixture: 'MX-VIS-012',
    route: '/first-run/deck',
  });

  // The promise the banner makes — "your information is still here" — is
  // the part worth asserting: the typed name survived, and the CTA now
  // names the retry rather than repeating the original action.
  await expect(page.getByRole('textbox', { name: /Deck name/i })).toHaveValue(
    KIT_DECK_NAME,
  );
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
  await holdDemoFrame(page);
});

// MX-VIS-011 · First-run deck setup (step 2) · Submitting
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: H["Step 2 · First Deck setup"] → I["Creating…"]
test('MX-VIS-011 holds the submitting state while the deck is created', async ({
  page,
}, testInfo) => {
  // The fixture pins the create command on a completer nothing resolves,
  // so node I is a still frame instead of a race against the real write.
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-011',
  });

  await reachStepOne(page);
  await selectKitLanguagePair(page);
  await reachStepTwo(page);
  await fillField(page, /Deck name/i, KIT_DECK_NAME, { blur: false });

  await tapControl(page, 'Create deck');

  // The CTA naming the work in flight is what proves node I was entered.
  await expect(
    page.getByRole('button', { name: 'Creating…' }),
  ).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-011',
    shot: 'create-deck-firstrun--submitting',
    screen: 'First-run deck setup (step 2)',
    state: 'Submitting',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'I["Creating…"]',
    fixture: 'MX-VIS-011',
    route: '/first-run/deck',
  });

  // §7 Submitting: the whole form is inert, and a second press cannot
  // start a second write.
  await expect(page.getByRole('textbox', { name: /Deck name/i })).toBeDisabled();
  await expect(page.getByRole('button', { name: 'Creating…' })).toBeDisabled();
  await holdDemoFrame(page);
});

// MX-VIS-005 · First-run language (step 1) · Validation error
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: E["Step 1 · Learning setup"]
test('MX-VIS-005 flags a required language the user left empty', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-005',
  });

  await reachStepOne(page);

  // Opening the picker and leaving without a choice is the only way a
  // required selector ends up visibly empty, so that is what the kit
  // draws an error for. The sheet dismisses on Escape (its barrier's
  // keyboard equivalent), which is a real key event, not an app call.
  await tapControl(page, 'What are you learning?');
  await page.keyboard.press('Escape');
  // The live-region wrapper and its text both carry the message, so the
  // match is intentionally the first of the two.
  const learningError = page.getByText('Choose a language to learn.').first();
  await expect(learningError).toBeVisible();

  // The second field is filled, matching the shot — the error belongs to
  // the empty field alone, not to the step.
  await tapControl(page, 'Show meanings in');
  await tapControl(page, 'Vietnamese');

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-005',
    shot: 'create-deck-firstrun--step1-validation',
    screen: 'First-run language (step 1)',
    state: 'Validation error',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'E["Step 1 · Learning setup"]',
    fixture: 'MX-VIS-005',
    route: '/first-run/language',
  });

  // The step cannot advance while a required field is empty, and it
  // recovers as soon as the user chooses.
  await expect(page.getByRole('button', { name: 'Continue' })).toBeDisabled();
  await tapControl(page, 'What are you learning?');
  await tapControl(page, 'Korean');
  await expect(learningError).toBeHidden();
  await reachStepTwo(page);
  await holdDemoFrame(page);
});

// MX-VIS-014 · First-run deck setup (step 2) · Name too long
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: H["Step 2 · First Deck setup"] → J{"Kết quả"} -- "Lỗi" --> H
test('MX-VIS-014 rejects a deck name past the limit and keeps it', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-014',
  });

  await reachStepOne(page);
  await selectKitLanguagePair(page);
  await reachStepTwo(page);

  // The kit's own over-long string, so the rendered truncation matches.
  await fillField(page, /Deck name/i, KIT_LONG_DECK_NAME, { blur: false });
  await tapControl(page, 'Create deck');

  // A field error is merged into the field's own accessible name, unlike
  // the step-1 message which is a sibling node — so this asserts what a
  // screen reader would announce for the field itself.
  await expect(
    page.getByRole('textbox', { name: /Use a shorter deck name\./ }),
  ).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-014',
    shot: 'create-deck-firstrun--name-too-long',
    screen: 'First-run deck setup (step 2)',
    state: 'Name too long',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'J{"Kết quả"} -- "Lỗi" --> H["Step 2 · First Deck setup"]',
    fixture: 'MX-VIS-014',
    route: '/first-run/deck',
  });

  // The rejection keeps what was typed, and shortening it recovers.
  await expect(page.getByRole('textbox', { name: /Deck name/i })).toHaveValue(
    KIT_LONG_DECK_NAME,
  );
  await fillField(page, /Deck name/i, KIT_DECK_NAME, { blur: false });
  await submitDeckAndExpectLibrary(page, KIT_DECK_NAME);
  await holdDemoFrame(page);
});

// MX-VIS-015 · First-run deck setup (step 2) · Resume draft
// Master flow: docs/business/deck/create-deck.md §3
// Flow node: H["Step 2 · First Deck setup"]
test('MX-VIS-015 restores the draft when the user comes back to step 2', async ({
  page,
}, testInfo) => {
  await enterFlow(page, {
    masterFlow: 'docs/business/deck/create-deck.md',
    fixture: 'MX-VIS-015',
  });

  await reachStepOne(page);
  await selectKitLanguagePair(page);
  await reachStepTwo(page);
  await fillField(page, /Deck name/i, KIT_DECK_NAME, { blur: false });

  // Leaving through `Change` and coming back is what a draft has to
  // survive, so the journey does exactly that rather than faking a
  // restored state.
  await tapControl(page, 'Change');
  await expectRoute(page, '/first-run/language');
  await reachStepTwo(page);

  await expect(page.getByText('We kept your draft.').first()).toBeVisible();

  await expectStableCapture(page);
  await expectKitParity(page, testInfo, {
    id: 'MX-VIS-015',
    shot: 'create-deck-firstrun--resume-draft',
    screen: 'First-run deck setup (step 2)',
    state: 'Resume draft',
    masterFlow: 'docs/business/deck/create-deck.md',
    flowNode: 'H["Step 2 · First Deck setup"]',
    fixture: 'MX-VIS-015',
    route: '/first-run/deck',
  });

  // The restored value is asserted after the capture, and only once the
  // field is focused: a rebuilt screen paints the controller's text, but
  // Flutter does not mount an engine editor until the field is touched,
  // so an unfocused field reports no value to the browser.
  await fillField(page, /Deck name/i, KIT_DECK_NAME, { blur: false });
  await expect(page.getByRole('textbox', { name: /Deck name/i })).toHaveValue(
    KIT_DECK_NAME,
  );

  // `Start over` is the callout's promise: it discards what was kept.
  await tapControl(page, 'Start over');
  await expect(page.getByText('We kept your draft.')).toHaveCount(0);
  await expect(page.getByRole('textbox', { name: /Deck name/i })).toHaveValue('');
  await holdDemoFrame(page);
});

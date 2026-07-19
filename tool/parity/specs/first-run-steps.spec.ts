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
 * H → I → J("Thành công") → K. Asserting the created deck in Library is
 * what makes each capture part of a journey instead of a screenshot.
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

// MX-VIS-010 (Optional section expanded) is deliberately not here yet. Its
// kit shot renders the Description field at single-line height; the app
// builds it with `multiline: true`, which measures ~4.4% — above the gate.
// Whether the description is single- or multi-line is a business/design
// question, not a styling tweak, so it is tracked as its own remediation
// rather than silently forced to match the shot.

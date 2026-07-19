import { expect, type Page } from '@playwright/test';
import { settle } from './kit';

/**
 * Master flow traversal helpers (WBS §6.6).
 *
 * Every parity spec enters through `enterFlow`, which performs the one
 * legitimate navigation: the app launch node that every
 * `docs/business/**` §3 chart starts from. From there a spec reaches its
 * state by clicking what a user clicks.
 *
 * Deep-linking straight to a route is a gate bypass: it skips the
 * router's first-run redirect, the guards and the cross-object handoffs,
 * which is precisely the class of defect an E2E flow exists to catch.
 * `deepLinkEntry` exists only for states whose Master flow entry *is* a
 * deep link (notification tap, browser refresh, restored URL) and it
 * demands a written justification.
 */

export interface FlowEntry {
  /** Owning business document, e.g. `docs/business/deck/create-deck.md`. */
  masterFlow: string;
  /** Earlier business flows traversed before the owning flow begins. */
  prerequisiteFlows?: readonly string[];
  /** Parity fixture id seeded before the app boots. */
  fixture: string;
}

/** App launch — the entry node of every Master flow chart. */
export async function enterFlow(page: Page, entry: FlowEntry): Promise<void> {
  await blockNetworkEgress(page);
  await page.goto(`/?fixture=${encodeURIComponent(entry.fixture)}`);
  await enableFlutterAccessibility(page);
  await settle(page);
}

/**
 * Entry for flows whose chart genuinely starts at a deep link.
 * [justification] is recorded so a shortcut can never pass review by
 * looking like an ordinary navigation.
 */
export async function deepLinkEntry(
  page: Page,
  entry: FlowEntry & { route: string; justification: string },
): Promise<void> {
  expect(
    entry.justification.length,
    'deepLinkEntry requires a written justification (WBS §6.6)',
  ).toBeGreaterThan(20);
  await blockNetworkEgress(page);
  await page.goto(
    `/#${entry.route}?fixture=${encodeURIComponent(entry.fixture)}`,
  );
  await enableFlutterAccessibility(page);
  await settle(page);
}

/** Keeps the local-first run offline while still allowing the harness host. */
async function blockNetworkEgress(page: Page): Promise<void> {
  await page.route('**/*', async (route) => {
    const url = new URL(route.request().url());
    if (url.hostname === 'localhost' || url.hostname === '127.0.0.1') {
      await route.continue();
      return;
    }
    await route.abort('blockedbyclient');
  });
}

/**
 * Flutter Web requires one trusted browser gesture before exposing its
 * semantics DOM. This framework-owned activation is not a business-flow
 * shortcut; all product navigation still happens through visible app controls.
 */
async function enableFlutterAccessibility(page: Page): Promise<void> {
  const activator = page.getByRole('button', { name: 'Enable accessibility' });
  await activator.waitFor({ state: 'visible', timeout: 60_000 });
  // The engine deliberately parks this placeholder outside the painted
  // viewport. Move only this disposable framework node on-screen, then let
  // Playwright dispatch a trusted pointer gesture. Flutter removes the node
  // immediately, before any product frame is captured.
  await activator.evaluate((node: HTMLElement) => {
    node.style.position = 'fixed';
    node.style.inset = '0 auto auto 0';
    node.style.width = '48px';
    node.style.height = '48px';
    node.style.zIndex = '2147483647';
  });
  await activator.click({ force: true });
  await activator.waitFor({ state: 'detached', timeout: 15_000 });
}

/**
 * Clicks a control by its accessible name.
 *
 * Flutter Web exposes controls through the semantics tree; matching on
 * the accessible name means the spec asserts what a screen reader would
 * announce, so a control that is unreachable to assistive tech fails
 * here too.
 */
export async function tapControl(page: Page, name: string | RegExp): Promise<void> {
  const control = page.getByRole('button', { name });
  await expect(control.first()).toBeVisible();
  await control.first().click();
  await settle(page);
}

/** Clicks any semantics node carrying [name], for non-button surfaces. */
export async function tapByLabel(page: Page, name: string | RegExp): Promise<void> {
  const node = page.getByLabel(name);
  await expect(node.first()).toBeVisible();
  await node.first().click();
  await settle(page);
}

/** Types through trusted keyboard events, then blurs through focus traversal. */
export async function fillField(
  page: Page,
  name: string | RegExp,
  value: string,
  { blur = true }: { blur?: boolean } = {},
): Promise<void> {
  const semanticField = page.getByRole('textbox', { name }).first();
  await expect(semanticField).toHaveCount(1);
  await expect(semanticField).toBeVisible();
  await semanticField.click();

  // CanvasKit exposes a labelled accessibility input and a separate,
  // unlabelled engine editor. Product focus starts through semantics;
  // trusted key events must then target the editor hosted here so Flutter's
  // TextEditingController receives them and rebuilds form state.
  const fieldBox = await semanticField.boundingBox();
  expect(fieldBox, 'Flutter text field must have a hit-testable box').not.toBeNull();
  const candidates = page.locator(
    'input[data-semantics-role="text-field"], '
      + 'textarea[data-semantics-role="text-field"]',
  );
  const editorIndex = await candidates.evaluateAll((nodes, target) => {
    return nodes.findIndex((node) => {
      const rect = node.getBoundingClientRect();
      const centerX = rect.x + rect.width / 2;
      const centerY = rect.y + rect.height / 2;
      const inside =
        centerX >= target.x &&
        centerX <= target.x + target.width &&
        centerY >= target.y &&
        centerY <= target.y + target.height;
      const isInnerEditor =
        rect.width < target.width || rect.height < target.height;
      return inside && isInnerEditor;
    });
  }, fieldBox!);
  expect(
    editorIndex,
    'Flutter engine editor must overlap the selected semantics field',
  ).toBeGreaterThanOrEqual(0);
  const editor = candidates.nth(editorIndex);
  await editor.press('Control+A');
  await editor.press('Backspace');
  await editor.pressSequentially(value);
  await expect(editor).toHaveValue(value);
  if (blur) await editor.press('Tab');
  await settle(page);
}

/** Asserts and returns the settled route (hash-routed on Flutter Web). */
export async function expectRoute(
  page: Page,
  expected: string | RegExp,
): Promise<string> {
  const currentRoute = () =>
    new URL(page.url()).hash.replace(/^#/, '').split('?')[0];

  if (typeof expected === 'string') {
    await expect.poll(currentRoute, { timeout: 15_000 }).toBe(expected);
    return currentRoute();
  }
  await expect.poll(currentRoute, { timeout: 15_000 }).toMatch(expected);
  return currentRoute();
}

/** Keeps the final frame visible only for an explicitly requested demo run. */
export async function holdDemoFrame(page: Page): Promise<void> {
  const holdMs = Number.parseInt(process.env.PARITY_HOLD_MS ?? '0', 10);
  if (!Number.isFinite(holdMs) || holdMs <= 0) return;
  await page.waitForTimeout(holdMs);
}

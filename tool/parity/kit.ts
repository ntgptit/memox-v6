import { expect, type Page, type TestInfo } from '@playwright/test';
import { copyFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  compareWithKitShot,
  KIT_PARITY_THRESHOLD,
  KIT_SHOTS_ROOT,
  REPO_ROOT,
} from './compare';

/**
 * Capture + comparison helpers for parity specs (WBS P0.2/P0.4).
 *
 * `expectKitParity` implements VP-05 through VP-08: settle, capture,
 * compare, emit artifacts, evaluate the 3% threshold. Every call writes
 * expected/actual/diff plus the §6.5 output record, whether it passes or
 * fails — a passing state still owes its evidence.
 */

export const EVIDENCE_ROOT = join(REPO_ROOT, 'evidence', 'parity');

export interface ParityState {
  /** `MX-VIS-*` id from the WBS Phase 0 register. */
  id: string;
  /** Kit shot basename without the `--<theme>` suffix. */
  shot: string;
  /** Screen name as registered. */
  screen: string;
  /** State name as registered. */
  state: string;
  /** Owning business doc, e.g. `docs/business/deck/create-deck.md`. */
  masterFlow: string;
  /** The node in that doc's §3 chart this capture corresponds to. */
  flowNode: string;
  /** Fixture id seeded through `?fixture=`. */
  fixture: string;
  /** Route the flow is expected to have landed on. */
  route: string;
}

/**
 * Waits until the frame is safe to capture.
 *
 * Flutter Web paints asynchronously, so a naive screenshot races the
 * first frame and produces a diff that has nothing to do with styling.
 * This waits for Flutter's rendered view (proof the app booted and built),
 * for webfonts, and then for two animation frames. Product specs separately
 * assert named semantics controls, so this deliberately avoids depending on
 * Flutter's private semantics-node tag names, which change between engines.
 */
export async function settle(page: Page): Promise<void> {
  await page.waitForFunction(
    () => document.querySelector('flt-glass-pane') != null,
    undefined,
    { timeout: 60_000 },
  );
  await page.evaluate(() => document.fonts.ready);
  await page.evaluate(
    () =>
      new Promise<void>((resolve) =>
        requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
      ),
  );
  await page.waitForTimeout(250);
}

/**
 * VP-05..VP-08. Captures the current frame, diffs it against the kit
 * shot for this project's theme, writes artifacts and asserts <=3%.
 */
export async function expectKitParity(
  page: Page,
  testInfo: TestInfo,
  parityState: ParityState,
): Promise<number> {
  const theme = testInfo.project.name;
  const shotName = `${parityState.shot}--${theme}`;

  await settle(page);
  const actual = await page.screenshot();
  const result = compareWithKitShot(actual, shotName);

  const evidenceDir = join(EVIDENCE_ROOT, `${parityState.id}--${theme}`);
  mkdirSync(evidenceDir, { recursive: true });
  writeFileSync(join(evidenceDir, 'actual.png'), actual);
  writeFileSync(join(evidenceDir, 'diff.png'), result.diffPng);
  copyFileSync(
    join(KIT_SHOTS_ROOT, `${shotName}.png`),
    join(evidenceDir, 'expected.png'),
  );

  const percentage = result.ratio * 100;
  const passed = result.ratio <= KIT_PARITY_THRESHOLD;

  // The §6.5 output contract, one record per state x theme.
  writeFileSync(
    join(evidenceDir, 'result.json'),
    `${JSON.stringify(
      {
        wbsId: parityState.id,
        screen: parityState.screen,
        state: parityState.state,
        masterFlow: parityState.masterFlow,
        flowNode: parityState.flowNode,
        kitReference: `${shotName}.png`,
        route: parityState.route,
        fixture: parityState.fixture,
        viewport: '390x780 @2x',
        theme,
        spec: testInfo.file.replace(REPO_ROOT, '').replace(/\\/g, '/'),
        expected: 'expected.png',
        actual: 'actual.png',
        diff: 'diff.png',
        differencePercentage: Number(percentage.toFixed(2)),
        result: passed ? 'PASS' : 'FAIL',
        kitSize: result.kitSize,
        actualSize: result.actualSize,
      },
      null,
      2,
    )}\n`,
  );

  expect(
    result.ratio,
    `${parityState.id} ${shotName} differs by ${percentage.toFixed(2)}% ` +
      `(gate: <=3%). Master flow: ${parityState.masterFlow} -> ${parityState.flowNode}. ` +
      `Artifacts: evidence/parity/${parityState.id}--${theme}/`,
  ).toBeLessThanOrEqual(KIT_PARITY_THRESHOLD);

  return percentage;
}

/**
 * Asserts the capture is stable: three consecutive settles must produce
 * the same bytes. An unstable state is not gate-ready (parity DoD 4).
 */
export async function expectStableCapture(page: Page): Promise<void> {
  const captures: string[] = [];
  for (let attempt = 0; attempt < 3; attempt++) {
    await settle(page);
    captures.push((await page.screenshot()).toString('base64'));
  }
  expect(
    new Set(captures).size,
    'capture is not deterministic across three consecutive settles',
  ).toBe(1);
}

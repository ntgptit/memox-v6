import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PNG } from 'pngjs';

/**
 * Kit visual-parity comparator (WBS P0.2).
 *
 * A direct port of the metric frozen with WBS 3.15
 * (`test/support/kit_parity.dart`) so the Playwright merge gate and the
 * in-test pre-push layer measure the same thing and cannot silently
 * disagree:
 *
 * - per-pixel diff on the physical 2x grid,
 * - per-channel tolerance (absorbs anti-aliasing blend differences),
 * - +/-1 logical px spatial slack, i.e. 2 physical px (absorbs the
 *   sub-pixel glyph-advance drift between the kit's browser rasterizer
 *   and Flutter's).
 *
 * Wrong colours and layout offsets of 2+ logical px stay fully visible.
 */

/** Pre-merge threshold (owner rule, 2026-07-19): a state passes under 3%. */
export const KIT_PARITY_THRESHOLD = 0.03;

const CHANNEL_TOLERANCE = 24;
const SPATIAL_SLACK_PHYSICAL_PX = 2;

/** Repo root, resolved from this file so cwd never matters. */
export const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

export const KIT_SHOTS_ROOT = join(
  REPO_ROOT,
  'docs/design/MemoX Design System_v4/ui_kits/memox-app/shots',
);

export interface ParityResult {
  ratio: number;
  differingPixels: number;
  comparedPixels: number;
  kitSize: { width: number; height: number };
  actualSize: { width: number; height: number };
  diffPng: Buffer;
}

export function compareWithKitShot(
  actualPng: Buffer,
  shotName: string,
): ParityResult {
  const kit = PNG.sync.read(readFileSync(join(KIT_SHOTS_ROOT, `${shotName}.png`)));
  const actual = PNG.sync.read(actualPng);

  const width = Math.min(kit.width, actual.width);
  const height = Math.min(kit.height, actual.height);

  const diff = new PNG({ width, height });
  let differing = 0;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const matched = matchesNear(kit, actual, x, y, width, height);
      writeDiffPixel(diff, actual, x, y, width, matched);
      if (!matched) differing++;
    }
  }

  const compared = width * height;
  return {
    ratio: compared === 0 ? 1 : differing / compared,
    differingPixels: differing,
    comparedPixels: compared,
    kitSize: { width: kit.width, height: kit.height },
    actualSize: { width: actual.width, height: actual.height },
    diffPng: PNG.sync.write(diff),
  };
}

/**
 * True when any kit pixel within the slack radius matches the actual
 * pixel at (x, y) on every colour channel within tolerance.
 */
function matchesNear(
  kit: PNG,
  actual: PNG,
  x: number,
  y: number,
  width: number,
  height: number,
): boolean {
  const actualOffset = (y * actual.width + x) * 4;
  const slack = SPATIAL_SLACK_PHYSICAL_PX;

  for (let dy = -slack; dy <= slack; dy++) {
    const ky = y + dy;
    if (ky < 0 || ky >= height) continue;
    for (let dx = -slack; dx <= slack; dx++) {
      const kx = x + dx;
      if (kx < 0 || kx >= width) continue;
      const kitOffset = (ky * kit.width + kx) * 4;

      let maxDelta = 0;
      for (let channel = 0; channel < 3; channel++) {
        const delta = Math.abs(
          kit.data[kitOffset + channel] - actual.data[actualOffset + channel],
        );
        if (delta > maxDelta) maxDelta = delta;
      }
      if (maxDelta <= CHANNEL_TOLERANCE) return true;
    }
  }
  return false;
}

/** Differing pixels paint magenta; matching pixels keep a dimmed actual. */
function writeDiffPixel(
  diff: PNG,
  actual: PNG,
  x: number,
  y: number,
  width: number,
  matched: boolean,
): void {
  const target = (y * width + x) * 4;
  if (!matched) {
    diff.data[target] = 255;
    diff.data[target + 1] = 0;
    diff.data[target + 2] = 255;
    diff.data[target + 3] = 255;
    return;
  }
  const source = (y * actual.width + x) * 4;
  diff.data[target] = 128 + (actual.data[source] >> 1);
  diff.data[target + 1] = 128 + (actual.data[source + 1] >> 1);
  diff.data[target + 2] = 128 + (actual.data[source + 2] >> 1);
  diff.data[target + 3] = 255;
}

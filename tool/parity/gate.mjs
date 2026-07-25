import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * The §6.5 merge gate, as a verdict rather than a reading.
 *
 * `report.mjs` says how many runs passed; this decides whether that is
 * acceptable. A raw "every run must pass" cannot be enforced today — five
 * state-themes are blocked on a kit contradiction or on shot content no
 * journey produces — and a gate that always fails is a gate nobody keeps.
 *
 * So the rule is a ratchet against `known-gaps.json`:
 *
 * - a failure that is NOT listed is a regression, and fails the gate;
 * - a listed gap that has started PASSING also fails the gate, because the
 *   list may only shrink and a stale entry silently re-opens the hole;
 * - a listed gap still failing is reported and tolerated.
 *
 * The second rule is the one that keeps this honest. Without it the file
 * becomes a place to park failures forever.
 */
const parityRoot = dirname(fileURLToPath(import.meta.url));
const summaryPath = join(
  parityRoot,
  '..',
  '..',
  'evidence',
  'parity',
  'summary.json',
);

if (!existsSync(summaryPath)) {
  throw new Error(
    'No parity summary exists; run report.mjs after Playwright first',
  );
}

const summary = JSON.parse(readFileSync(summaryPath, 'utf8'));
const { gaps } = JSON.parse(
  readFileSync(join(parityRoot, 'known-gaps.json'), 'utf8'),
);

const keyOf = (result) => `${result.wbsId}--${result.theme}`;
const regressions = [];
const fixed = [];
const tolerated = [];

for (const result of summary.results) {
  const key = keyOf(result);
  const isGap = Object.hasOwn(gaps, key);
  if (result.result === 'PASS') {
    if (isGap) fixed.push(key);
    continue;
  }
  if (isGap) {
    tolerated.push(`${key} (${result.differencePercentage}%)`);
    continue;
  }
  regressions.push(`${key} (${result.differencePercentage}%)`);
}

// A gap whose state was not measured at all this run cannot be judged; say so
// rather than treating silence as either outcome.
const measured = new Set(summary.results.map(keyOf));
const unmeasured = Object.keys(gaps).filter((key) => !measured.has(key));

for (const key of tolerated) {
  process.stdout.write(`  known gap, still failing: ${key}\n`);
}
for (const key of unmeasured) {
  process.stdout.write(`  known gap, not measured this run: ${key}\n`);
}

if (fixed.length > 0) {
  process.stderr.write(
    `\nThese runs now PASS but are still listed in known-gaps.json:\n` +
      `${fixed.map((key) => `  - ${key}`).join('\n')}\n\n` +
      'Remove them from that file (and update the MX-VIS register) so the\n' +
      'gate keeps holding the line it has actually reached.\n',
  );
}

if (regressions.length > 0) {
  process.stderr.write(
    `\nParity regressions — failing and not a recorded gap:\n` +
      `${regressions.map((key) => `  - ${key}`).join('\n')}\n\n` +
      'Either fix the state or, if it is genuinely blocked, add it to\n' +
      'known-gaps.json with the reason and record it in the MX-VIS register.\n',
  );
}

if (fixed.length > 0 || regressions.length > 0) {
  process.exitCode = 1;
} else {
  process.stdout.write(
    `Parity gate passed: ${summary.passed}/${summary.measuredStateThemes} runs pass, ` +
      `${tolerated.length} recorded gap(s) outstanding.\n`,
  );
}

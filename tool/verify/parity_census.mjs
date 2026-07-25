import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * The `P0.6` census clause: no `MX-VIS-*` state may be silently unaccounted
 * for, and no register row may claim a result the evidence contradicts.
 *
 * Three failure modes, each one a way for the register to drift away from what
 * was actually measured:
 *
 * 1. A row claims **PASS** while the evidence says otherwise. A status line is
 *    a human assertion; `evidence/parity/summary.json` is the machine's. When
 *    they disagree the document is wrong, and it is the document people read
 *    when deciding whether a screen may merge.
 * 2. A row reports a **FAIL** that `tool/parity/known-gaps.json` does not
 *    list. Then the prose and the gate disagree about what is allowed to be
 *    red, and the gate is the one that stops a merge.
 * 3. A row is neither measured nor carries a recorded reason for not being
 *    measured — the census hole `P0.6` exists to close. An ID nobody can say
 *    anything about reads exactly like one that is fine.
 * 4. A row points at a kit shot that does not exist — a typo or a renamed
 *    shot, which makes the row unmeasurable while still reading as complete.
 * 5. Evidence exists for an id the register never lists. This is the mirror of
 *    (3) and it actually happened: `MX-VIS-050`-`054` were measured by the
 *    suite for weeks while missing from the register, so their figures lived
 *    only in run notes. Checking rows against evidence cannot see that; only
 *    checking evidence against rows can.
 *
 * Evidence is optional: a clean checkout has none and the structural half of
 * the audit still runs. Only the cross-check in (1) needs measurements.
 */
const verifyRoot = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(verifyRoot, '..', '..');
const registerPath = join(
  repoRoot,
  'docs',
  'wbs',
  'memox-v6-development-wbs.md',
);
const workItemRegisterPath = join(
  repoRoot,
  'docs',
  'traceability',
  'work-item-register.md',
);
const summaryPath = join(repoRoot, 'evidence', 'parity', 'summary.json');
const gapsPath = join(repoRoot, 'tool', 'parity', 'known-gaps.json');
const shotsPath = join(
  repoRoot,
  'docs',
  'design',
  'MemoX Design System_v4',
  'ui_kits',
  'memox-app',
  'shots',
);

/** Status prefixes that state, explicitly, why a row carries no measurement. */
const ACCOUNTED_UNMEASURED = [
  'blocked',
  'pending',
  'structurally unreachable',
  'out of scope',
  'composition built',
  'enforced',
  'measured',
  'deferred',
  'not measurable',
  'superseded',
];

const rows = readFileSync(registerPath, 'utf8')
  .split('\n')
  .filter((line) => /^\| MX-VIS-\d{3} \|/.test(line))
  .map((line) => {
    const cells = line.split('|').map((cell) => cell.trim());
    // | id | screen | state | kit reference | status |
    return { id: cells[1], kitReference: cells[4] ?? '', status: cells[5] ?? '' };
  });

if (rows.length === 0) {
  throw new Error('Parity census found no MX-VIS rows; the register moved');
}

const measured = new Map();
let evidenceAvailable = false;
if (existsSync(summaryPath)) {
  evidenceAvailable = true;
  const summary = JSON.parse(readFileSync(summaryPath, 'utf8'));
  for (const result of summary.results) {
    const current = measured.get(result.wbsId) ?? [];
    current.push(result);
    measured.set(result.wbsId, current);
  }
}

const gapIds = new Set(
  existsSync(gapsPath)
    ? Object.keys(JSON.parse(readFileSync(gapsPath, 'utf8')).gaps).map((key) =>
        key.split('--')[0],
      )
    : [],
);

// A row naming a FAIL reports a split result rather than claiming a pass: the
// register's legend is explicit that an ID passes only when both themes do.
const admitsFailure = (status) => /\bFAIL\b/i.test(status);
const claimsPass = (status) =>
  /\bPASS\b/.test(status) && !admitsFailure(status);
const isAccounted = (status) => {
  const plain = status.replaceAll('*', '').trim().toLowerCase();
  return ACCOUNTED_UNMEASURED.some((prefix) => plain.startsWith(prefix));
};

// Kit shots, stripped of their theme suffix — the name a row references.
const shots = existsSync(shotsPath)
  ? new Set(
      readdirSync(shotsPath)
        .filter((file) => file.endsWith('.png'))
        .map((file) => file.replace(/--(light|dark)\.png$/, '')),
    )
  : new Set();

const referenced = new Set();
const danglingShots = [];
for (const row of rows) {
  const reference = row.kitReference.replaceAll('`', '').trim();
  // A row may declare that the kit has no shot for its state — those read
  // "*no kit reference*" and are held to the accounted-status rule instead.
  if (reference === '' || reference === '—') continue;
  if (/no kit reference/i.test(reference)) continue;
  referenced.add(reference);
  if (shots.size > 0 && !shots.has(reference)) {
    danglingShots.push(`${row.id} references \`${reference}\`, which has no shot`);
  }
}

const contradicted = [];
const unrecordedFailures = [];
const unaccounted = [];
const drifted = [];
const staleClaims = [];

// How far a recorded percentage may sit from the measured one before the row
// counts as stale. Captures are byte-deterministic within a run
// (`expectStableCapture`), so this is not run-to-run jitter — it is the margin
// below which re-recording every row costs more than it tells anyone.
const RECORDED_TOLERANCE_PP = 0.1;
const recordedIn = (status) => {
  const match = /([0-9.]+)% light \/ ([0-9.]+)% dark/.exec(status);
  if (match === null) return null;
  return { light: Number(match[1]), dark: Number(match[2]) };
};
const knownIds = new Set(rows.map((row) => row.id));
const unlisted = [...measured.keys()].filter((id) => !knownIds.has(id));

for (const row of rows) {
  const results = measured.get(row.id);

  if (admitsFailure(row.status)) {
    if (!gapIds.has(row.id)) {
      unrecordedFailures.push(
        `${row.id} reports a FAIL with no tool/parity/known-gaps.json entry`,
      );
    }
    continue;
  }

  if (evidenceAvailable && results && claimsPass(row.status)) {
    const failing = results.filter((result) => result.result !== 'PASS');
    if (failing.length > 0) {
      contradicted.push(
        `${row.id} claims PASS but ${failing
          .map((r) => `${r.theme} measured ${r.differencePercentage}%`)
          .join(', ')}`,
      );
      continue;
    }

    // A row that still passes can still be lying about *how well*. These
    // numbers drift silently: a change three screens away moves a shared
    // widget, every ratio shifts, and the register keeps quoting the old
    // figure. Seventeen rows had drifted when this check was written, one of
    // them by 0.8pp — enough to hide a real regression inside a passing state.
    const recorded = recordedIn(row.status);
    if (recorded !== null) {
      const stale = results
        .filter(
          (result) =>
            Math.abs(result.differencePercentage - recorded[result.theme]) >
            RECORDED_TOLERANCE_PP,
        )
        .map(
          (result) =>
            `${result.theme} records ${recorded[result.theme]}% but measured ` +
            `${result.differencePercentage}%`,
        );
      if (stale.length > 0) {
        drifted.push(`${row.id} — ${stale.join('; ')}`);
      }
    }
    continue;
  }

  if (results || claimsPass(row.status) || isAccounted(row.status)) continue;
  unaccounted.push(`${row.id} — status: ${row.status.slice(0, 70)}`);
}

// Coverage claims frozen into register prose. `P0.4` carried "covering **11
// of 49** `MX-VIS-*` IDs" long after both numbers had moved, which pointed the
// owner at the wrong blocker for the gate that halts every UI work package.
// The counts are right here; a sentence asserting different ones is wrong by
// construction.
if (evidenceAvailable) {
  const claim = /\*\*(\d+) of (\d+)\*\* `MX-VIS-\*` IDs/g;
  // Both registers: the MX-VIS table lives in the WBS doc, the `P0.*` child
  // rows in the traceability one, and the claim can be written in either.
  // The first cut scanned only `registerPath` — the WBS — and so read past
  // the very sentence that motivated the check.
  const registerText = [registerPath, workItemRegisterPath]
    .filter(existsSync)
    .map((path) => readFileSync(path, 'utf8'))
    .join('\n');
  for (const match of registerText.matchAll(claim)) {
    const claimedMeasured = Number(match[1]);
    const claimedTotal = Number(match[2]);
    if (claimedMeasured !== measured.size || claimedTotal !== rows.length) {
      staleClaims.push(
        `"${match[0]}" but the census counts ${measured.size} measured of ` +
          `${rows.length} rows`,
      );
    }
  }
}

const report =
  `Parity census: ${rows.length} MX-VIS rows; ` +
  (evidenceAvailable
    ? `${measured.size} measured in the current evidence`
    : 'no local evidence — structural audit only');

const bullet = (entries) => entries.map((entry) => `  - ${entry}`).join('\n');

if (
  contradicted.length === 0 &&
  drifted.length === 0 &&
  staleClaims.length === 0 &&
  unrecordedFailures.length === 0 &&
  unaccounted.length === 0 &&
  unlisted.length === 0 &&
  danglingShots.length === 0
) {
  process.stdout.write(`${report}. Every row is accounted for.\n`);
  if (shots.size > 0) {
    // Informational, not a gate. Most unenumerated shots belong to features
    // that do not exist yet, which `P0.1` does not ask for — it enumerates
    // every *implemented* screen. Printed on every run so the census's true
    // coverage stays visible instead of being rediscovered.
    process.stdout.write(
      `Kit shot coverage: ${referenced.size}/${shots.size} shots have a row ` +
        `(${shots.size - referenced.size} without one).\n`,
    );
  }
} else {
  if (contradicted.length > 0) {
    process.stderr.write(
      `\nRows claiming a result the evidence contradicts:\n${bullet(contradicted)}\n`,
    );
  }
  if (staleClaims.length > 0) {
    process.stderr.write(
      `
Register prose claiming coverage the census contradicts:
${bullet(
        staleClaims,
      )}
`,
    );
  }
  if (drifted.length > 0) {
    process.stderr.write(
      `
Rows whose recorded percentage no longer matches the evidence:
${bullet(
        drifted,
      )}
`,
    );
  }
  if (unrecordedFailures.length > 0) {
    process.stderr.write(
      `\nRows reporting a failure the parity gate does not know about:\n` +
        `${bullet(unrecordedFailures)}\n`,
    );
  }
  if (danglingShots.length > 0) {
    process.stderr.write(
      `
Rows referencing a kit shot that does not exist:
${bullet(danglingShots)}
`,
    );
  }
  if (unlisted.length > 0) {
    process.stderr.write(
      `
Measured states the register never lists:
${bullet(unlisted)}

` +
        `Add a row for each, with its screen, state, kit reference and result.
`,
    );
  }
  if (unaccounted.length > 0) {
    process.stderr.write(
      `\nRows neither measured nor accounted for:\n${bullet(unaccounted)}\n\n` +
        `Give each a measurement, or a status beginning with one of:\n` +
        `  ${ACCOUNTED_UNMEASURED.join(', ')}\n`,
    );
  }
  process.exitCode = 1;
}

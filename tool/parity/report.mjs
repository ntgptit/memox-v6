import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const parityRoot = dirname(fileURLToPath(import.meta.url));
const evidenceRoot = join(parityRoot, '..', '..', 'evidence', 'parity');

if (!existsSync(evidenceRoot)) {
  throw new Error('No parity evidence directory exists; run Playwright first');
}

const results = readdirSync(evidenceRoot, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => join(evidenceRoot, entry.name, 'result.json'))
  .filter(existsSync)
  .map((path) => JSON.parse(readFileSync(path, 'utf8')))
  .sort((left, right) =>
    `${left.wbsId}--${left.theme}`.localeCompare(`${right.wbsId}--${right.theme}`),
  );

const passed = results.filter((result) => result.result === 'PASS').length;
const summary = {
  thresholdPercentage: 3,
  generatedAtUtc: new Date().toISOString(),
  measuredStateThemes: results.length,
  passed,
  failed: results.length - passed,
  results,
};

writeFileSync(
  join(evidenceRoot, 'summary.json'),
  `${JSON.stringify(summary, null, 2)}\n`,
  'utf8',
);
process.stdout.write(
  `Parity summary: ${passed}/${results.length} measured state-theme runs passed.\n`,
);

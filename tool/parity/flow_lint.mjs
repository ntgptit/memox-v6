import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const parityRoot = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(parityRoot, '..', '..');
const specsRoot = join(parityRoot, 'specs');

if (!existsSync(specsRoot)) throw new Error('tool/parity/specs is missing');

const specFiles = readdirSync(specsRoot, { withFileTypes: true })
  .filter((entry) => entry.isFile() && entry.name.endsWith('.spec.ts'))
  .map((entry) => join(specsRoot, entry.name));

if (specFiles.length === 0) throw new Error('No Playwright parity specs found');

const failures = [];
for (const specFile of specFiles) {
  const source = readFileSync(specFile, 'utf8');
  const display = relative(repoRoot, specFile).replaceAll('\\', '/');
  const ids = [...source.matchAll(/^\/\/ (MX-VIS-\d+) · .+$/gm)];
  const flows = [...source.matchAll(/^\/\/ Master flow: (docs\/business\/.+\.md) §3$/gm)];
  const prerequisiteFlows = [
    ...source.matchAll(
      /^\/\/ Prerequisite flow: (docs\/business\/.+\.md) §3$/gm,
    ),
  ];
  const nodes = [...source.matchAll(/^\/\/ Flow node: (.+)$/gm)];

  if (ids.length === 0) failures.push(`${display}: missing MX-VIS header`);
  if (flows.length !== ids.length) {
    failures.push(`${display}: each MX-VIS header needs one Master flow header`);
  }
  if (nodes.length !== ids.length) {
    failures.push(`${display}: each MX-VIS header needs one Flow node header`);
  }

  for (const match of [...flows, ...prerequisiteFlows]) {
    const docPath = join(repoRoot, ...match[1].split('/'));
    if (!existsSync(docPath)) {
      failures.push(`${display}: Master flow doc does not exist: ${match[1]}`);
      continue;
    }
    const doc = readFileSync(docPath, 'utf8');
    if (!/^# 3\. Master flow\s*$/m.test(doc)) {
      failures.push(`${display}: ${match[1]} has no '# 3. Master flow' section`);
    }
  }

  if (/\bpage\.goto\s*\(/.test(source)) {
    failures.push(
      `${display}: direct page.goto is forbidden; use enterFlow/deepLinkEntry`,
    );
  }

  for (const match of ids) {
    const occurrences = source.match(new RegExp(match[1], 'g'))?.length ?? 0;
    if (occurrences < 2) {
      failures.push(`${display}: ${match[1]} is not bound to an executable test`);
    }
  }
}

if (failures.length > 0) {
  throw new Error(`Master-flow conformance lint failed:\n${failures.join('\n')}`);
}

process.stdout.write(
  `Master-flow conformance lint passed (${specFiles.length} spec file(s)).\n`,
);

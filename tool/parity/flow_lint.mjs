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
  // The section number is read from the citation rather than assumed to be 3.
  // It was pinned at §3 because every doc the lint was written against
  // numbers its master flow there — but that is where those docs happen to
  // put it, not a rule. `load-today-dashboard.md` has no Entry points
  // section, so its master flow is §2, and a citation naming §2 was rejected
  // for being accurate. Reading the number back means the check now verifies
  // the citation instead of requiring one constant.
  const flows = [
    ...source.matchAll(/^\/\/ Master flow: (docs\/business\/.+\.md) §(\d+)$/gm),
  ];
  const prerequisiteFlows = [
    ...source.matchAll(
      /^\/\/ Prerequisite flow: (docs\/business\/.+\.md) §(\d+)$/gm,
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
    const section = match[2];
    // Heading level varies between docs; the section number is what the
    // citation claims, so that is what is checked.
    const heading = new RegExp(`^#{1,3} ${section}\. Master flow\s*$`, 'm');
    if (!heading.test(doc)) {
      failures.push(
        `${display}: ${match[1]} has no '${section}. Master flow' section`,
      );
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

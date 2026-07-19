#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, extname, join, relative, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import process from 'node:process';

const repoRoot = resolve(import.meta.dirname, '..', '..');
const args = process.argv.slice(2);
const docsOnly = args.includes('--docs');
const quick = args.includes('--quick');
const updateGoldens = args.includes('--update-goldens');
const testTargets = [];

for (let index = 0; index < args.length; index += 1) {
  if (args[index] !== '--test') continue;
  const target = args[index + 1];
  if (!target || target.startsWith('--')) {
    throw new Error('--test requires one path; repeat --test for additional paths.');
  }
  testTargets.push(target);
  index += 1;
}

const results = [];

function command(name, commandName, commandArgs, options = {}) {
  process.stdout.write(`\n==> ${name}\n`);
  const result = spawnSync(commandName, commandArgs, {
    cwd: options.cwd ?? repoRoot,
    encoding: 'utf8',
    shell: process.platform === 'win32',
    stdio: 'inherit',
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    results.push({ name, status: 'fail' });
    throw new Error(`${name} failed with exit code ${result.status}`);
  }
  results.push({ name, status: 'pass' });
}

function output(commandName, commandArgs, cwd = repoRoot) {
  const result = spawnSync(commandName, commandArgs, {
    cwd,
    encoding: 'utf8',
    shell: process.platform === 'win32',
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(result.stderr || result.stdout);
  return result.stdout.trim();
}

function walk(directory, acceptedExtensions, files = []) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (['.git', '.dart_tool', 'build', 'node_modules'].includes(entry.name)) continue;
    const path = join(directory, entry.name);
    if (entry.isDirectory()) walk(path, acceptedExtensions, files);
    if (entry.isFile() && (!acceptedExtensions || acceptedExtensions.has(extname(entry.name).toLowerCase()))) files.push(path);
  }
  return files;
}

function normalizeLocalTarget(rawTarget) {
  let target = rawTarget.trim().replace(/^<|>$/g, '');
  if (!target || /^(?:https?:|mailto:|data:|javascript:|app:|skill:|#)/i.test(target)) return null;
  target = target.split('#', 1)[0].split('?', 1)[0];
  if (!target) return null;
  try {
    return decodeURIComponent(target);
  } catch {
    return target;
  }
}

function checkDocumentation() {
  const docsRoot = join(repoRoot, 'docs');
  const allFiles = walk(docsRoot, null);
  const linkFiles = allFiles.filter((file) => ['.md', '.html'].includes(extname(file).toLowerCase()));
  const textExtensions = new Set([
    '.arb', '.cjs', '.css', '.html', '.js', '.json', '.jsx', '.md', '.mjs',
    '.svg', '.ts', '.tsx', '.txt', '.xml', '.yaml', '.yml',
  ]);
  const textFiles = allFiles.filter((file) => textExtensions.has(extname(file).toLowerCase()));
  const broken = [];
  const markdownLink = /\[[^\]]*\]\(([^)]+)\)/g;
  const htmlLink = /(?:href|src)=["']([^"']+)["']/gi;

  for (const file of textFiles) readFileSync(file, 'utf8');

  for (const file of linkFiles) {
    const content = readFileSync(file, 'utf8');
    const patterns = extname(file).toLowerCase() === '.html' ? [htmlLink] : [markdownLink];
    for (const pattern of patterns) {
      pattern.lastIndex = 0;
      for (const match of content.matchAll(pattern)) {
        const target = normalizeLocalTarget(match[1]);
        if (!target) continue;
        const resolvedTarget = target.startsWith('/')
          ? resolve(repoRoot, `.${target}`)
          : resolve(dirname(file), target);
        if (!existsSync(resolvedTarget)) {
          broken.push(`${relative(repoRoot, file)} -> ${match[1]}`);
        }
      }
    }
  }

  const wbsPath = join(repoRoot, 'docs', 'wbs', 'memox-v6-development-wbs.md');
  const duplicateIds = [];
  const unresolvedDependencies = [];
  const dependencyCycles = [];
  let numericWbsCount = 0;
  if (existsSync(wbsPath)) {
    const wbsContent = readFileSync(wbsPath, 'utf8');
    const ids = [];
    const rowId = /^\|\s*((?:\d+\.)+\d+|DG-\d+|FD-\d+)(?:\s+CP)?\s*\|/gm;
    for (const match of wbsContent.matchAll(rowId)) ids.push(match[1]);
    for (const id of new Set(ids)) {
      if (ids.filter((candidate) => candidate === id).length > 1) duplicateIds.push(id);
    }

    const numericIds = new Set(ids.filter((id) => /^\d/.test(id)));
    numericWbsCount = numericIds.size;
    const graph = new Map([...numericIds].map((id) => [id, []]));
    const expandRange = (start, end) => {
      if (!end) return [start];
      const startParts = start.split('.').map(Number);
      const endParts = end.split('.').map(Number);
      const sameParent = startParts.length === endParts.length
        && startParts.slice(0, -1).every((part, index) => part === endParts[index]);
      if (!sameParent || endParts.at(-1) < startParts.at(-1)) return [start, end];
      return Array.from(
        { length: endParts.at(-1) - startParts.at(-1) + 1 },
        (_, index) => [...startParts.slice(0, -1), startParts.at(-1) + index].join('.'),
      );
    };

    for (const line of wbsContent.split(/\r?\n/)) {
      const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
      if (cells.length < 4) continue;
      const itemId = cells[0].replace(/\s+CP$/, '');
      if (!numericIds.has(itemId)) continue;
      const dependencyCell = cells[3].replaceAll('`', '');
      const dependencies = [];
      const rangePattern = /(\d+(?:\.\d+)+)(?:\s*[–-]\s*(\d+(?:\.\d+)+))?/g;
      for (const match of dependencyCell.matchAll(rangePattern)) {
        dependencies.push(...expandRange(match[1], match[2]));
      }
      for (const dependency of new Set(dependencies)) {
        if (!numericIds.has(dependency)) unresolvedDependencies.push(`${itemId} -> ${dependency}`);
        else graph.get(itemId).push(dependency);
      }
    }

    const visiting = new Set();
    const visited = new Set();
    const visit = (id, trail = []) => {
      if (visiting.has(id)) {
        dependencyCycles.push([...trail, id].join(' -> '));
        return;
      }
      if (visited.has(id)) return;
      visiting.add(id);
      for (const dependency of graph.get(id)) visit(dependency, [...trail, id]);
      visiting.delete(id);
      visited.add(id);
    };
    for (const id of numericIds) visit(id);

    const registerPath = join(repoRoot, 'docs', 'traceability', 'work-item-register.md');
    const prefixes = [];
    const itemStatuses = new Map();
    const readyPackets = new Map();
    if (existsSync(registerPath)) {
      const registerContent = readFileSync(registerPath, 'utf8');
      const prefixPattern = /^\|\s*`(\d+(?:\.\d+)*\.\*)`\s*\|/gm;
      for (const match of registerContent.matchAll(prefixPattern)) {
        prefixes.push(match[1].slice(0, -1));
      }
      for (const line of registerContent.split(/\r?\n/)) {
        const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
        if (cells.length < 2) continue;
        const itemId = cells[0].replaceAll('`', '');
        if (!numericIds.has(itemId)) continue;
        const status = cells[1].replaceAll('*', '');
        if (!['Ready', 'Done'].includes(status)) continue;
        itemStatuses.set(itemId, status);
        if (status !== 'Ready') continue;
        const packetMatch = (cells[5] ?? '').match(/`(docs\/wbs\/implementation-packets\/[^]+?\.md)`/);
        if (!packetMatch) {
          unresolvedDependencies.push(`${itemId} -> Ready item missing implementation packet`);
          continue;
        }
        readyPackets.set(itemId, packetMatch[1]);
      }
    }
    for (const id of numericIds) {
      if (!prefixes.some((prefix) => id.startsWith(prefix))) {
        unresolvedDependencies.push(`${id} -> missing traceability prefix default`);
      }
    }
    for (const [id, packet] of readyPackets) {
      const packetPath = join(repoRoot, ...packet.split('/'));
      if (!existsSync(packetPath)) {
        unresolvedDependencies.push(`${id} -> missing packet ${packet}`);
        continue;
      }
      const packetContent = readFileSync(packetPath, 'utf8');
      for (const heading of ['## Canonical inputs', '## Scope', '## Acceptance and test procedure']) {
        if (!packetContent.includes(heading)) {
          unresolvedDependencies.push(`${id} -> packet missing section ${heading}`);
        }
      }
      for (const dependency of graph.get(id)) {
        if (itemStatuses.get(dependency) !== 'Done') {
          unresolvedDependencies.push(`${id} -> Ready dependency ${dependency} is not Done`);
        }
      }
    }
  }

  if (broken.length || duplicateIds.length || unresolvedDependencies.length || dependencyCycles.length) {
    if (broken.length) process.stderr.write(`Broken local links:\n${broken.join('\n')}\n`);
    if (duplicateIds.length) process.stderr.write(`Duplicate WBS IDs: ${duplicateIds.join(', ')}\n`);
    if (unresolvedDependencies.length) process.stderr.write(`Unresolved WBS/trace references:\n${unresolvedDependencies.join('\n')}\n`);
    if (dependencyCycles.length) process.stderr.write(`WBS dependency cycles:\n${dependencyCycles.join('\n')}\n`);
    throw new Error('documentation contract check failed');
  }

  results.push({ name: 'documentation inventory, links, WBS graph and traceability', status: 'pass' });
  process.stdout.write(
    `Inventoried ${allFiles.length} docs files; read ${textFiles.length} textual files; `
    + `checked ${linkFiles.length} Markdown/HTML links and ${numericWbsCount} numeric WBS items.\n`,
  );
}

function writePassMarker(mode) {
  const markerPath = join(repoRoot, '.dart_tool', 'memox_verify_pass.json');
  mkdirSync(dirname(markerPath), { recursive: true });
  writeFileSync(markerPath, `${JSON.stringify({
    status: 'pass',
    mode,
    commit: output('git', ['rev-parse', 'HEAD']),
    verifiedAtUtc: new Date().toISOString(),
    results,
  }, null, 2)}\n`, 'utf8');
}

try {
  checkDocumentation();
  command(
    'design checklist structure',
    'python',
    ['docs/design/mobile-design-kit-audit-v5/scripts/validate.py'],
  );
  command(
    'design token manifest',
    'node',
    ['tool/design/token_manifest.mjs', '--check'],
  );

  const guardRoot = join(repoRoot, 'tools', 'code-verification-guard');
  const guardTests = [
    'tests/test_memox_architecture_guard_rules.py',
    'tests/test_memox_v6_ruleset_contract.py',
  ];
  if (guardTests.every((path) => existsSync(join(guardRoot, path)))) {
    command(
      'guard ruleset regression tests',
      'pytest',
      ['-q', ...guardTests],
      { cwd: guardRoot },
    );
  }

  command(
    'code verification guard',
    'python',
    ['tools/code-verification-guard/guard/run.py', 'check', '--project', '.', '--ruleset', 'memox', '--profile', 'local'],
  );

  if (!docsOnly) {
    if (!quick) {
      command('flutter pub get', 'flutter', ['pub', 'get']);
      command('flutter gen-l10n', 'flutter', ['gen-l10n']);

      const pubspec = readFileSync(join(repoRoot, 'pubspec.yaml'), 'utf8');
      if (/^\s*build_runner\s*:/m.test(pubspec)) {
        command('build_runner', 'dart', ['run', 'build_runner', 'build']);
      }

      const dartFiles = output('git', ['ls-files', '*.dart']).split(/\r?\n/).filter(Boolean);
      // Windows caps the command line around 32k characters; batch the
      // file list so the format check keeps working as the tree grows.
      const FORMAT_BATCH = 80;
      const batchCount = Math.ceil(dartFiles.length / FORMAT_BATCH);
      for (let start = 0; start < dartFiles.length; start += FORMAT_BATCH) {
        const batch = dartFiles.slice(start, start + FORMAT_BATCH);
        const label = batchCount > 1
          ? `dart format check (${start / FORMAT_BATCH + 1}/${batchCount})`
          : 'dart format check';
        command(label, 'dart', ['format', '--output=none', '--set-exit-if-changed', ...batch]);
      }
    }

    command('flutter analyze', 'flutter', ['analyze']);
    command('flutter test', 'flutter', [
      'test',
      ...(updateGoldens ? ['--update-goldens'] : []),
      ...testTargets,
    ]);
  }

  if (updateGoldens) {
    // A baseline-regeneration run is not verification evidence: goldens
    // were rewritten, not compared. Re-run without the flag for a marker.
    process.stdout.write('\nGoldens updated; pass marker not written — re-run without --update-goldens.\n');
    process.exit(0);
  }

  const mode = docsOnly ? 'docs' : quick ? 'quick' : 'full';
  writePassMarker(mode);
  process.stdout.write(`\nMemoX verification passed (${mode}).\n`);
  for (const result of results) process.stdout.write(`- ${result.name}: ${result.status}\n`);
} catch (error) {
  process.stderr.write(`\nMemoX verification failed: ${error.message}\n`);
  process.exitCode = 1;
}

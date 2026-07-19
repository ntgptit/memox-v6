#!/usr/bin/env node

import {
  appendFileSync,
  existsSync,
  readFileSync,
  readdirSync,
} from 'node:fs';
import { extname, join, relative, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const repoRoot = resolve(import.meta.dirname, '..', '..');
const visualTestPattern = /matchesGolden|expectKitParity/;
const broadPathPatterns = [
  /^\.github\//,
  /^analysis_options\.yaml$/,
  /^assets\/fonts\//,
  /^build\.yaml$/,
  /^lib\/app\//,
  /^lib\/core\//,
  /^lib\/data\/database\//,
  /^lib\/l10n\//,
  /^lib\/presentation\/shared\//,
  /^l10n\.yaml$/,
  /^pubspec\.lock$/,
  /^pubspec\.yaml$/,
  /^test\/support\//,
  /^tool\/verify\//,
];

function normalizePath(path) {
  return path.replaceAll('\\', '/').replace(/^\.\//, '');
}

function walkDartTests(directory, files = []) {
  if (!existsSync(directory)) return files;
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) walkDartTests(path, files);
    if (entry.isFile() && entry.name.endsWith('_test.dart')) files.push(path);
  }
  return files;
}

export function listNonVisualTests(root = repoRoot) {
  return walkDartTests(join(root, 'test'))
    .filter((path) => !visualTestPattern.test(readFileSync(path, 'utf8')))
    .map((path) => normalizePath(relative(root, path)))
    .sort();
}

export function isDocsOnlyPath(rawPath) {
  const path = normalizePath(rawPath);
  if (path === 'AGENTS.md') return true;
  if (!path.startsWith('docs/')) return false;
  return ['.md', '.txt'].includes(extname(path).toLowerCase());
}

function testsUnder(testFiles, prefix) {
  const normalizedPrefix = normalizePath(prefix).replace(/\/$/, '');
  return testFiles.filter((path) => path.startsWith(`${normalizedPrefix}/`));
}

function exactTestForSource(path, testFiles) {
  if (!path.startsWith('lib/') || !path.endsWith('.dart')) return [];
  const candidate = `test/${path.slice(4, -5)}_test.dart`;
  return testFiles.includes(candidate) ? [candidate] : [];
}

function isVisualTest(path, root) {
  const absolutePath = join(root, ...normalizePath(path).split('/'));
  return existsSync(absolutePath)
    && visualTestPattern.test(readFileSync(absolutePath, 'utf8'));
}

export function selectScope(
  rawChanges,
  { root = repoRoot, testFiles = listNonVisualTests(root) } = {},
) {
  const changes = [...new Set(rawChanges.map(normalizePath).filter(Boolean))].sort();
  const docsOnly = changes.length > 0 && changes.every(isDocsOnlyPath);
  if (docsOnly) {
    return {
      kind: 'docs',
      docsOnly: true,
      visualChanges: false,
      reasons: ['all changed files are documentation contracts'],
      testTargets: [],
    };
  }

  const reasons = [];
  let broad = changes.length === 0;
  let visualChanges = false;
  const targets = new Set();

  if (broad) reasons.push('no changed files were resolved; using the safe broad suite');

  for (const path of changes) {
    if (broadPathPatterns.some((pattern) => pattern.test(path))) {
      broad = true;
      reasons.push(`${path} has repository-wide impact`);
      continue;
    }

    if (path.startsWith('docs/') && !isDocsOnlyPath(path)) {
      broad = true;
      visualChanges = true;
      reasons.push(`${path} is executable design evidence`);
      continue;
    }

    if (path.startsWith('test/') && path.endsWith('_test.dart')) {
      if (isVisualTest(path, root)) {
        visualChanges = true;
        reasons.push(`${path} remains in the Windows visual gate`);
      } else {
        targets.add(path);
      }
      continue;
    }

    for (const exactTarget of exactTestForSource(path, testFiles)) targets.add(exactTarget);

    const featureMatch = path.match(/^lib\/presentation\/features\/([^/]+)\//);
    if (featureMatch) {
      for (const target of testsUnder(
        testFiles,
        `test/presentation/features/${featureMatch[1]}`,
      )) targets.add(target);
      continue;
    }

    if (path.startsWith('lib/domain/')) {
      for (const target of testsUnder(testFiles, 'test/domain')) targets.add(target);
      continue;
    }
    if (path.startsWith('lib/data/')) {
      for (const target of testsUnder(testFiles, 'test/data')) targets.add(target);
      continue;
    }
    if (path.startsWith('lib/presentation/')) {
      for (const target of testsUnder(testFiles, 'test/presentation')) targets.add(target);
      continue;
    }
    if (path.startsWith('test/')) {
      broad = true;
      reasons.push(`${path} changes shared test infrastructure or fixtures`);
      continue;
    }
    if (!isDocsOnlyPath(path)) {
      broad = true;
      reasons.push(`${path} has no safe narrow test mapping`);
    }
  }

  const testTargets = broad ? [...testFiles] : [...targets].sort();
  if (!testTargets.length) {
    const smokeTarget = 'test/app/app_test.dart';
    if (testFiles.includes(smokeTarget)) testTargets.push(smokeTarget);
    reasons.push('no direct test mapping was found; using the app smoke test');
  }

  return {
    kind: broad ? 'broad' : 'targeted',
    docsOnly: false,
    visualChanges,
    reasons: [...new Set(reasons)],
    testTargets,
  };
}

export function changedFiles(base, head, root = repoRoot) {
  const result = spawnSync(
    'git',
    ['diff', '--name-only', '--diff-filter=ACMRD', `${base}...${head}`],
    { cwd: root, encoding: 'utf8', shell: process.platform === 'win32' },
  );
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(result.stderr || `git diff failed with exit code ${result.status}`);
  }
  return result.stdout.split(/\r?\n/).map((path) => path.trim()).filter(Boolean);
}

export function selectScopeFromGit(base, head, root = repoRoot) {
  return selectScope(changedFiles(base, head, root), { root });
}

function argumentValue(args, name) {
  const index = args.indexOf(name);
  if (index === -1) return null;
  const value = args[index + 1];
  if (!value || value.startsWith('--')) throw new Error(`${name} requires a value.`);
  return value;
}

function runCli() {
  const args = process.argv.slice(2);
  const base = argumentValue(args, '--base');
  const head = argumentValue(args, '--head');
  const githubOutput = argumentValue(args, '--github-output');
  if (!base || !head) throw new Error('--base and --head are required.');

  const changes = changedFiles(base, head);
  const scope = selectScope(changes);
  process.stdout.write(`${JSON.stringify({ changes, ...scope }, null, 2)}\n`);

  if (githubOutput) {
    appendFileSync(
      githubOutput,
      [
        `docs_only=${scope.docsOnly}`,
        `scope=${scope.kind}`,
        `visual_changes=${scope.visualChanges}`,
        `test_count=${scope.testTargets.length}`,
        '',
      ].join('\n'),
      'utf8',
    );
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  try {
    runCli();
  } catch (error) {
    process.stderr.write(`CI scope selection failed: ${error.message}\n`);
    process.exitCode = 1;
  }
}

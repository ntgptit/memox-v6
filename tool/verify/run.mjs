#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, extname, join, relative, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import process from 'node:process';

const repoRoot = resolve(import.meta.dirname, '..', '..');
const args = process.argv.slice(2);
const docsOnly = args.includes('--docs');
const quick = args.includes('--quick');
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
    if (entry.isFile() && acceptedExtensions.has(extname(entry.name).toLowerCase())) files.push(path);
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
  const files = walk(docsRoot, new Set(['.md', '.html']));
  const broken = [];
  const markdownLink = /\[[^\]]*\]\(([^)]+)\)/g;
  const htmlLink = /(?:href|src)=["']([^"']+)["']/gi;

  for (const file of files) {
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
  if (existsSync(wbsPath)) {
    const ids = [];
    const rowId = /^\|\s*((?:\d+\.)+\d+|DG-\d+|FD-\d+)(?:\s+CP)?\s*\|/gm;
    for (const match of readFileSync(wbsPath, 'utf8').matchAll(rowId)) ids.push(match[1]);
    for (const id of new Set(ids)) {
      if (ids.filter((candidate) => candidate === id).length > 1) duplicateIds.push(id);
    }
  }

  if (broken.length || duplicateIds.length) {
    if (broken.length) process.stderr.write(`Broken local links:\n${broken.join('\n')}\n`);
    if (duplicateIds.length) process.stderr.write(`Duplicate WBS IDs: ${duplicateIds.join(', ')}\n`);
    throw new Error('documentation contract check failed');
  }

  results.push({ name: 'documentation links and IDs', status: 'pass' });
  process.stdout.write(`Checked ${files.length} Markdown/HTML files; no broken local links or duplicate WBS IDs.\n`);
}

function guardSubmoduleIsDirty() {
  const guardRoot = join(repoRoot, 'tools', 'code-verification-guard');
  if (!existsSync(join(guardRoot, '.git'))) return false;
  return output('git', ['status', '--porcelain'], guardRoot).length > 0;
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

  if (guardSubmoduleIsDirty()) {
    command(
      'guard ruleset regression tests',
      'pytest',
      ['-q', 'tests/test_memox_architecture_guard_rules.py', 'tests/test_memox_v6_ruleset_contract.py'],
      { cwd: join(repoRoot, 'tools', 'code-verification-guard') },
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
      if (dartFiles.length) {
        command('dart format check', 'dart', ['format', '--output=none', '--set-exit-if-changed', ...dartFiles]);
      }
    }

    command('flutter analyze', 'flutter', ['analyze']);
    command('flutter test', 'flutter', ['test', ...testTargets]);
  }

  const mode = docsOnly ? 'docs' : quick ? 'quick' : 'full';
  writePassMarker(mode);
  process.stdout.write(`\nMemoX verification passed (${mode}).\n`);
  for (const result of results) process.stdout.write(`- ${result.name}: ${result.status}\n`);
} catch (error) {
  process.stderr.write(`\nMemoX verification failed: ${error.message}\n`);
  process.exitCode = 1;
}

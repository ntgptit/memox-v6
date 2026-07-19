import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const parityRoot = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
let id;
let theme;
let slowMo = 0;
let holdMs = 0;
const headed = args.includes('--headed');

for (let index = 0; index < args.length; index += 1) {
  const argument = args[index];
  if (argument === '--headed') continue;
  if (argument === '--id') {
    id = args[index + 1];
    if (!id || !/^MX-VIS-\d+$/.test(id)) {
      throw new Error('--id requires an MX-VIS-* id, for example MX-VIS-001');
    }
    index += 1;
    continue;
  }
  if (argument === '--theme') {
    theme = args[index + 1];
    if (!['light', 'dark'].includes(theme)) {
      throw new Error('--theme requires light or dark');
    }
    index += 1;
    continue;
  }
  if (argument === '--slow-mo' || argument === '--hold') {
    const value = Number.parseInt(args[index + 1] ?? '', 10);
    if (!Number.isFinite(value) || value < 0) {
      throw new Error(`${argument} requires a non-negative integer in milliseconds`);
    }
    if (argument === '--slow-mo') slowMo = value;
    if (argument === '--hold') holdMs = value;
    index += 1;
    continue;
  }
  throw new Error(`Unknown argument: ${argument}`);
}

process.env.PARITY_SLOW_MO = String(slowMo);
process.env.PARITY_HOLD_MS = String(holdMs);

function command(name, executable, commandArgs, { allowFailure = false } = {}) {
  process.stdout.write(`\n==> ${name}\n`);
  const result = spawnSync(executable, commandArgs, {
    cwd: parityRoot,
    shell: process.platform === 'win32',
    stdio: 'inherit',
  });
  if (result.error) throw result.error;
  if (result.status !== 0 && !allowFailure) {
    throw new Error(`${name} failed with exit code ${result.status}`);
  }
  return result.status ?? 1;
}

command('Master-flow conformance lint', 'node', ['flow_lint.mjs']);
command('Flutter Web parity build', 'node', ['build_web.mjs']);
const playwrightStatus = command(
  id ? `Playwright parity (${id})` : 'Playwright parity',
  'npx',
  [
    'playwright',
    'test',
    ...(id ? ['--grep', id] : []),
    ...(theme ? ['--project', theme] : []),
    ...(headed ? ['--headed'] : []),
  ],
  { allowFailure: true },
);
command('Parity evidence summary', 'node', ['report.mjs']);
if (playwrightStatus !== 0) {
  throw new Error(`Playwright parity failed with exit code ${playwrightStatus}`);
}

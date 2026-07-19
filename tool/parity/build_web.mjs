import { existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const parityRoot = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(parityRoot, '..', '..');
const output = process.env.PARITY_WEB_ROOT
  ? process.env.PARITY_WEB_ROOT
  : join(repoRoot, 'build', 'parity-web');

mkdirSync(output, { recursive: true });

const result = spawnSync(
  'flutter',
  [
    'build',
    'web',
    '--release',
    '--target=lib/app/dev/parity_main.dart',
    `--output=${output}`,
    '--dart-define=MEMOX_PARITY=true',
    '--no-web-resources-cdn',
    '--no-wasm-dry-run',
  ],
  {
    cwd: repoRoot,
    shell: process.platform === 'win32',
    stdio: 'inherit',
  },
);

if (result.error) throw result.error;
if (result.status !== 0) {
  throw new Error(`Flutter Web parity build failed with exit code ${result.status}`);
}

const requiredOutputs = [
  'index.html',
  'main.dart.js',
  'assets/AssetManifest.bin',
  'assets/FontManifest.json',
  'assets/assets/fonts/PlusJakartaSans-Variable.ttf',
];
const missingOutputs = requiredOutputs.filter(
  (path) => !existsSync(join(output, ...path.split('/'))),
);
if (missingOutputs.length > 0) {
  throw new Error(
    `Parity web bundle is incomplete; missing: ${missingOutputs.join(', ')}`,
  );
}

process.stdout.write(`Parity web bundle: ${output}\n`);

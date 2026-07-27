import { spawn, spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
// Playwright lives with the parity harness, which is where the repo installs
// it; the smoke reuses that install rather than adding a second copy.
import { chromium } from '../parity/node_modules/playwright/index.mjs';

/**
 * Tier-1 Web smoke (WBS 5.7.5 criterion 4).
 *
 * The release gate asks for Tier-1 Web and Android smoke evidence and had
 * none: `evidence/` held parity captures and nothing else, and no WBS row
 * owned a harness. This is the Web half.
 *
 * It is deliberately not a second parity suite. Parity drives
 * `lib/app/dev/parity_main.dart`, a debug entry that seeds fixtures and
 * installs provider overrides; nothing has ever checked that the **shipping**
 * entry (`lib/main.dart`) boots at all on Web. That is the one thing a smoke
 * is for: a release build of the real app, loaded in a real browser, reaching
 * its first screen with a working store and no console errors.
 *
 * Android is not covered here and is not pretended to be: it needs a device or
 * emulator this harness has no access to. Criterion 4 stays open on that half.
 */

const smokeRoot = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(smokeRoot, '..', '..');
const bundle = join(repoRoot, 'build', 'smoke-web');
const evidenceDir = join(repoRoot, 'evidence', 'smoke', 'web');
const port = Number(process.env.MEMOX_SMOKE_PORT ?? 4601);

/** Console messages that are noise rather than a failing app. */
const IGNORED_CONSOLE = [
  // Flutter's own service-worker and font-loading chatter on a cold load.
  /Failed to load resource.*favicon/i,
];

function step(name, executable, args, options = {}) {
  process.stdout.write(`\n==> ${name}\n`);
  const result = spawnSync(executable, args, {
    cwd: repoRoot,
    shell: process.platform === 'win32',
    stdio: 'inherit',
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${name} failed with exit code ${result.status}`);
  }
}

// `--skip-build` reuses the bundle already in `build/smoke-web`, so a failing
// smoke can be diagnosed without paying for the release build again.
if (!process.argv.includes('--skip-build')) {
  step('Flutter Web release build (lib/main.dart)', 'flutter', [
    'build',
    'web',
    '--release',
    '--target=lib/main.dart',
    `--output=${bundle}`,
    '--no-web-resources-cdn',
    '--no-wasm-dry-run',
  ]);
}

process.stdout.write('\n==> Serving the release bundle\n');
const server = spawn('node', [join(repoRoot, 'tool', 'parity', 'serve.mjs')], {
  cwd: repoRoot,
  shell: process.platform === 'win32',
  stdio: 'inherit',
  env: { ...process.env, PARITY_WEB_ROOT: bundle, PARITY_PORT: String(port) },
});

const consoleErrors = [];
const pageErrors = [];
let outcome = 'PASS';
let failedPage = null;
let detail = 'The shipping entry booted and reached its first screen.';

try {
  // The server binds before it prints; a short poll is cheaper than parsing
  // its output and does not depend on the message staying the same.
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 390, height: 780 } });
  failedPage = page;

  page.on('console', (message) => {
    if (message.type() !== 'error') return;
    const text = message.text();
    if (IGNORED_CONSOLE.some((pattern) => pattern.test(text))) return;
    consoleErrors.push(text);
  });
  page.on('pageerror', (error) => pageErrors.push(String(error)));

  await page.goto(`http://127.0.0.1:${port}/`, { waitUntil: 'load' });

  // The shipping entry does not force semantics on — and should not; only the
  // parity entry does that, for the harness's benefit. Flutter Web therefore
  // paints to canvas and exposes no copy to the DOM until one trusted gesture
  // activates its accessibility placeholder. Doing that here is the same
  // framework-owned activation the parity flows perform, and it is also worth
  // something on its own: a shipping build whose semantics never appear is
  // unusable with a screen reader, and this smoke would catch that.
  const activator = page.getByRole('button', { name: 'Enable accessibility' });
  await activator.waitFor({ state: 'visible', timeout: 60_000 });
  await activator.evaluate((node) => {
    node.style.position = 'fixed';
    node.style.inset = '0 auto auto 0';
    node.style.width = '48px';
    node.style.height = '48px';
    node.style.zIndex = '2147483647';
  });
  await activator.click({ force: true });
  await activator.waitFor({ state: 'detached', timeout: 15_000 });

  // A fresh install has no library, so the router's first-run gate redirects
  // `/` to the first-run landing. Waiting on its rendered title proves three
  // things at once: the bundle loaded, the Drift wasm store answered the
  // gate's query, and the first frame painted.
  //
  // (The first draft waited for the language-pair setup copy and timed out —
  // the app was right and the expectation was wrong. The failure screenshot
  // below is what showed that, which is why it is captured.)
  await page
    .getByText('Build your learning library', { exact: false })
    .first()
    .waitFor({ timeout: 60_000 });

  mkdirSync(evidenceDir, { recursive: true });
  await page.screenshot({ path: join(evidenceDir, 'first-run.png') });
  await browser.close();

  if (consoleErrors.length > 0 || pageErrors.length > 0) {
    outcome = 'FAIL';
    detail = 'The app booted but reported errors.';
  }
} catch (error) {
  outcome = 'FAIL';
  detail = String(error);
  mkdirSync(evidenceDir, { recursive: true });
  // A screenshot rather than page text: Flutter Web paints to canvas, so the
  // DOM carries none of the copy and only the picture says whether this is a
  // wrong expectation or an entry that does not boot.
  if (failedPage != null) {
    await failedPage
        .screenshot({ path: join(evidenceDir, 'failure.png') })
        .catch(() => {});
  }
} finally {
  server.kill();
}

writeFileSync(
  join(evidenceDir, 'result.json'),
  `${JSON.stringify(
    {
      criterion: 'WBS 5.7.5 (4) Tier-1 Web smoke',
      target: 'lib/main.dart',
      build: 'flutter build web --release',
      viewport: '390x780',
      route: '/',
      expects: 'first-run landing',
      result: outcome,
      detail,
      consoleErrors,
      pageErrors,
    },
    null,
    2,
  )}\n`,
);

process.stdout.write(`\n==> Tier-1 Web smoke: ${outcome} — ${detail}\n`);
if (outcome !== 'PASS') process.exit(1);

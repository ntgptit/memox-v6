import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { createReadStream, existsSync, mkdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, extname, join, normalize, resolve, sep } from 'node:path';
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
const bundle = process.env.MEMOX_SMOKE_BUNDLE
  ? join(repoRoot, process.env.MEMOX_SMOKE_BUNDLE)
  : join(repoRoot, 'build', 'smoke-web');
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

/**
 * Serves the bundle from *this* process.
 *
 * The first version spawned `tool/parity/serve.mjs` as a child. On Windows
 * that child outlived every way this script tried to stop it — a shell wrapper
 * swallowed `kill`, and a script killed mid-run never reached its cleanup at
 * all — so the server kept holding the port and the run never terminated. One
 * such orphan sat for three hours with its work long finished.
 *
 * An in-process server cannot be orphaned: when this process ends, for any
 * reason, the listener ends with it. The headers match the parity server's,
 * because the Drift wasm worker needs cross-origin isolation to start.
 */
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.symbols': 'text/plain; charset=utf-8',
};

const bundleRoot = resolve(bundle);
const bundlePrefix = `${bundleRoot}${sep}`.toLowerCase();

const server = createServer((request, response) => {
  const url = new URL(request.url ?? '/', 'http://localhost');
  const relative = normalize(decodeURIComponent(url.pathname)).replace(
    /^([/\\])+/,
    '',
  );

  let filePath = resolve(bundleRoot, relative);
  if (
    filePath.toLowerCase() !== bundleRoot.toLowerCase() &&
    !filePath.toLowerCase().startsWith(bundlePrefix)
  ) {
    response.writeHead(403).end('Forbidden');
    return;
  }
  if (existsSync(filePath) && statSync(filePath).isDirectory()) {
    filePath = join(bundleRoot, 'index.html');
  }
  if (!existsSync(filePath) && extname(relative) === '') {
    filePath = join(bundleRoot, 'index.html');
  }
  if (!existsSync(filePath)) {
    response.writeHead(404).end('Not found');
    return;
  }

  response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  response.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  response.setHeader('Cache-Control', 'no-store');
  response.setHeader(
    'Content-Type',
    MIME[extname(filePath).toLowerCase()] ?? 'application/octet-stream',
  );
  createReadStream(filePath).pipe(response);
});

process.stdout.write('\n==> Serving the release bundle\n');
await new Promise((ready) => server.listen(port, '127.0.0.1', ready));

/**
 * Turns on Flutter Web's semantics tree.
 *
 * The shipping entry does not force semantics on — and should not; only the
 * parity entry does that, for the harness's benefit. Flutter therefore paints
 * to canvas and exposes no copy to the DOM until one trusted gesture activates
 * its accessibility placeholder. This is the same framework-owned activation
 * the parity flows perform, and it is worth something on its own: a shipping
 * build whose semantics never appear is unusable with a screen reader, and
 * this smoke would catch that.
 *
 * Called again after a reload, because the new document starts without it.
 */
async function enableSemantics(page) {
  const activator = page.getByRole('button', { name: 'Enable accessibility' });
  await activator.waitFor({ state: 'visible', timeout: 60_000 });
  // The engine parks this placeholder outside the painted viewport; move only
  // this disposable framework node on-screen so a real pointer event reaches
  // it. Flutter removes it immediately afterwards.
  await activator.evaluate((node) => {
    node.style.position = 'fixed';
    node.style.inset = '0 auto auto 0';
    node.style.width = '48px';
    node.style.height = '48px';
    node.style.zIndex = '2147483647';
  });
  await activator.click({ force: true });
  await activator.waitFor({ state: 'detached', timeout: 15_000 });
}

const consoleErrors = [];
const pageErrors = [];
let outcome = 'PASS';
let failedPage = null;
let detail =
  'The shipping entry booted, skipped onboarding, and kept that across a reload.';

try {
  // The server binds before it prints; a short poll is cheaper than parsing
  // its output and does not depend on the message staying the same.
  const browser = await chromium.launch();
  // The locale is set explicitly, and that is not incidental.
  //
  // A CI runner with no `LANG` makes Chromium report `C` in
  // `navigator.languages`. `C` is a POSIX locale name, not a BCP-47 tag, and
  // Flutter's engine builds a JS `Intl.Locale` from every entry during
  // renderer init — `EnginePlatformDispatcher.parseBrowserLanguages`. That
  // throws `RangeError: Incorrect locale information provided` before any app
  // code runs, and the app never paints (`int-88`).
  //
  // So the harness pins a real tag rather than inheriting the runner's. A
  // browser reporting `C` is a property of a bare shell, not of a user: every
  // real browser normalises `navigator.languages` to BCP-47. Leaving it
  // unpinned made the smoke report an engine limitation as a product failure.
  //
  // `MEMOX_SMOKE_LOCALE` still overrides it, which is how the reproduction
  // above was found and how it can be re-checked.
  const page = await browser.newPage({
    viewport: { width: 390, height: 780 },
    locale: process.env.MEMOX_SMOKE_LOCALE ?? 'en-US',
  });
  failedPage = page;

  page.on('console', (message) => {
    if (message.type() !== 'error') return;
    const text = message.text();
    if (IGNORED_CONSOLE.some((pattern) => pattern.test(text))) return;
    consoleErrors.push(text);
  });
  page.on('pageerror', (error) =>
    pageErrors.push(`${error}
${error.stack ?? ''}`));

  await page.goto(`http://127.0.0.1:${port}/`, { waitUntil: 'load' });

  await enableSemantics(page);

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

  // Past the first screen, into the one thing a Web build can get wrong that
  // no unit test can see: whether a write survives a page load.
  //
  // `Not now` is the shortest journey that writes. `handle-empty-library-today.md`
  // §4 makes the skipped marker persistent — "Onboarding skipped marker ngăn
  // auto-open lặp" — so it has to go to the store, and the router's first-run
  // gate has to read it back. Nothing else here needs typing, which keeps this
  // smoke free of the CanvasKit text-entry machinery the parity flows carry.
  await page.getByRole('button', { name: 'Not now' }).first().click();
  await page.getByText('Today', { exact: false }).first().waitFor({
    timeout: 30_000,
  });

  // The reload is the assertion. A fresh document, a fresh engine, a fresh
  // Drift wasm worker — and if the marker did not reach durable storage the
  // gate sends this straight back to the landing.
  await page.reload({ waitUntil: 'load' });
  await enableSemantics(page);
  await page.getByText('Today', { exact: false }).first().waitFor({
    timeout: 60_000,
  });
  const backAtLanding = await page
    .getByText('Build your learning library', { exact: false })
    .first()
    .isVisible()
    .catch(() => false);
  if (backAtLanding) {
    throw new Error('the skipped marker did not survive a reload');
  }
  await page.screenshot({ path: join(evidenceDir, 'after-reload.png') });

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
  // `closeAllConnections` as well as `close`: a browser that kept a socket
  // open would otherwise hold the listener, and the whole point of moving the
  // server in-process was that this run always ends.
  server.closeAllConnections();
  await new Promise((closed) => server.close(closed));
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
      expects: 'first-run landing, then Today surviving a reload',
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

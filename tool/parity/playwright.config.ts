import { defineConfig, devices } from '@playwright/test';

/**
 * Frozen parity environment (WBS §6.5).
 *
 * Every variable here is pinned on purpose. An unpinned variable makes
 * the pixel diff non-reproducible and voids the evidence, so treat this
 * file as a contract rather than configuration to tune.
 *
 * - comparison viewport 390x780 CSS px at deviceScaleFactor 2, which
 *   captures at 780x1560 — the exact physical size of every kit shot;
 * - light and dark are separate projects driven through `colorScheme`
 *   emulation, so the production `ThemeMode.system` path stays under
 *   test rather than being bypassed by a hardcoded theme;
 * - reduced motion on, one worker, no retries: a flaky capture must
 *   surface as a failure, never be retried into a pass.
 */

const BASE_VIEWPORT = { width: 390, height: 780 };
const slowMo = Number.parseInt(process.env.PARITY_SLOW_MO ?? '0', 10);

if (!Number.isFinite(slowMo) || slowMo < 0) {
  throw new Error('PARITY_SLOW_MO must be a non-negative integer');
}

export default defineConfig({
  testDir: './specs',
  outputDir: '../../build/parity-playwright',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list'], ['json', { outputFile: '../../build/parity-report.json' }]],
  timeout: 120_000,
  expect: { timeout: 15_000 },

  use: {
    baseURL: `http://localhost:${process.env.PARITY_PORT ?? 4599}`,
    viewport: BASE_VIEWPORT,
    deviceScaleFactor: 2,
    locale: 'en-US',
    timezoneId: 'UTC',
    reducedMotion: 'reduce',
    trace: 'retain-on-failure',
    launchOptions: { slowMo },
  },

  projects: [
    {
      name: 'light',
      use: { ...devices['Desktop Chrome'], viewport: BASE_VIEWPORT, deviceScaleFactor: 2, colorScheme: 'light' },
    },
    {
      name: 'dark',
      use: { ...devices['Desktop Chrome'], viewport: BASE_VIEWPORT, deviceScaleFactor: 2, colorScheme: 'dark' },
    },
  ],

  webServer: {
    command: 'node serve.mjs',
    url: `http://localhost:${process.env.PARITY_PORT ?? 4599}/index.html`,
    cwd: '.',
    reuseExistingServer: true,
    timeout: 60_000,
  },
});

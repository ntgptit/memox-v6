import { createServer } from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { dirname, extname, join, normalize, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Static server for the parity web bundle (WBS P0.2).
 *
 * Serves `build/parity-web` with cross-origin isolation headers so the
 * Drift wasm worker can use SharedArrayBuffer, and with no-store caching
 * so a rebuilt bundle is never served stale into a capture.
 */

const parityRoot = dirname(fileURLToPath(import.meta.url));
const ROOT = process.env.PARITY_WEB_ROOT
  ? resolve(process.env.PARITY_WEB_ROOT)
  : join(parityRoot, '..', '..', 'build', 'parity-web');
const ROOT_PREFIX = `${resolve(ROOT)}${sep}`.toLowerCase();
const PORT = Number(process.env.PARITY_PORT ?? 4599);

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

const server = createServer((request, response) => {
  const url = new URL(request.url ?? '/', 'http://localhost');
  const relative = normalize(decodeURIComponent(url.pathname)).replace(
    /^([/\\])+/,
    '',
  );

  let filePath = resolve(ROOT, relative);
  if (filePath.toLowerCase() !== resolve(ROOT).toLowerCase() &&
      !filePath.toLowerCase().startsWith(ROOT_PREFIX)) {
    response.writeHead(403).end('Forbidden');
    return;
  }

  if (existsSync(filePath) && statSync(filePath).isDirectory()) {
    filePath = join(ROOT, 'index.html');
  }
  if (!existsSync(filePath) && extname(relative) === '') {
    // Single-page app fallback for refresh-safe GoRouter locations only.
    filePath = join(ROOT, 'index.html');
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

server.listen(PORT, () => {
  process.stdout.write(`parity server listening on http://localhost:${PORT}\n`);
});

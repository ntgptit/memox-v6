// MemoX offline shell (WBS 5.7.4 "offline Web variant").
//
// MemoX is local-first: the store is a Drift wasm database inside the browser,
// so losing the network should be a non-event. On Web it is not free — the
// bundle itself arrives over that network, and nothing was caching it.
//
// Flutter used to register a worker of its own. It no longer does on a first
// visit: `flutter.js` registers only when `serviceWorkerUrl` is passed
// explicitly (a path it warns is going away, flutter/flutter#156910) or when a
// registration already exists. A build that passes only `serviceWorkerVersion`
// — which is what `flutter build web` generates — therefore never creates one,
// so a cold start with no network showed nothing at all (`int-95`).
//
// The strategy is **network-first with a cache fallback**, deliberately, not
// the cache-first that a precache manifest would give:
//
//   * online behaviour is unchanged — every load is fresh, so a release can
//     never be shadowed by a stale shell, which is the standing hazard of
//     app-shell caching and the reason it needs a version/skipWaiting dance
//     that this file does not have to carry;
//   * offline is served from whatever the last online visit fetched, which is
//     exactly the shell that visit was able to run.
//
// Only same-origin GETs are cached. There are no cross-origin requests to
// begin with (`--no-web-resources-cdn` keeps CanvasKit local), and a rule that
// says so is better than one that happens to be true.

const CACHE = 'memox-offline-shell-v1';

self.addEventListener('install', (event) => {
  // Take over without waiting for the old worker's clients to close: there is
  // no stale-shell risk to manage, because nothing is served from cache while
  // the network answers.
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names.filter((name) => name !== CACHE).map((name) => caches.delete(name)),
      );
      await self.clients.claim();
    })(),
  );
});

/**
 * The cache key for a request: path and query, without the fragment.
 *
 * The app routes on the hash, so a reload of `/#/first-run` would otherwise
 * store the document under that route and every other route would miss —
 * including `/`, which is what a fresh navigation asks for. One document
 * serves every route here, so it is keyed as one.
 */
function cacheKey(url) {
  return `${url.pathname}${url.search}`;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  const key = cacheKey(url);

  event.respondWith(
    (async () => {
      try {
        const response = await fetch(request);
        // `basic` and `cors` both carry a readable body worth keeping; an
        // opaque one does not, and a cached error would outlive the condition
        // that caused it. CanvasKit and `main.dart.js` arrive as `cors` — a
        // first draft that kept only `basic` silently dropped exactly the two
        // files without which nothing boots.
        if (response.ok && response.type !== 'opaque') {
          const cache = await caches.open(CACHE);
          // Clone before the body is consumed by the caller.
          await cache.put(key, response.clone());
        }
        return response;
      } catch (networkError) {
        const cached = await caches.match(key);
        if (cached) return cached;
        // A navigation to any route resolves to the same document — the app
        // owns its routing, and offline is not the moment to 404 a deep link.
        if (request.mode === 'navigate') {
          const shell = await caches.match('/');
          if (shell) return shell;
        }
        throw networkError;
      }
    })(),
  );
});

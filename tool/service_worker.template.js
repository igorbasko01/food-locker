// Precaches every file of the web build so the app opens offline.
// PRECACHE (prepended by tool/generate_service_worker.dart) maps each path,
// relative to the scope, to its sha256; '' is index.html, which Cloudflare
// Pages serves at the scope root.
const CACHE = 'foodlocker-precache';

// Flutter fetches Roboto and its fallback fonts from Google's CDN at runtime.
// Their URLs are content-addressed, so the copy fetched on an online launch
// can serve every offline one after it.
const FONT_CACHE = 'foodlocker-fonts';
const FONT_ORIGIN = 'https://fonts.gstatic.com';

const scope = () => new URL(self.registration.scope);

// Keying by content hash lets an update re-download only the files that changed.
const keyFor = (path) => new URL(`${path}?v=${PRECACHE[path]}`, scope()).href;

// A redirected response cannot answer a navigation, so store a clean copy.
const unredirected = async (response) =>
  response.redirected
    ? new Response(await response.blob(), {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
      })
    : response;

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      await Promise.all(
        Object.keys(PRECACHE).map(async (path) => {
          const key = keyFor(path);
          if (await cache.match(key)) return;
          const response = await fetch(new URL(path, scope()), { cache: 'reload' });
          if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
          await cache.put(key, await unredirected(response));
        }),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const current = new Set(Object.keys(PRECACHE).map(keyFor));
      const cache = await caches.open(CACHE);
      for (const request of await cache.keys()) {
        if (!current.has(request.url)) await cache.delete(request);
      }
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin === FONT_ORIGIN) {
    event.respondWith(cachedFont(event));
    return;
  }
  const root = scope();
  if (url.origin !== root.origin || !url.pathname.startsWith(root.pathname)) return;

  let path = url.pathname.slice(root.pathname.length);
  if (path === 'index.html' || (request.mode === 'navigate' && !(path in PRECACHE))) {
    path = '';
  }
  if (!(path in PRECACHE)) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      return (await cache.match(keyFor(path))) ?? fetch(request);
    })(),
  );
});

async function cachedFont(event) {
  const cache = await caches.open(FONT_CACHE);
  const cached = await cache.match(event.request);
  if (cached) return cached;
  const response = await fetch(event.request);
  if (response.ok) event.waitUntil(cache.put(event.request, response.clone()));
  return response;
}

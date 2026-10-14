// Cache public application assets only. Never cache backend requests or records.
const CACHE = 'mobimed-shell-1.0.0-1';
const shell = ['.', 'index.html', 'flutter_bootstrap.js', 'flutter.js', 'main.dart.js', 'manifest.json', 'icons/Icon-192.png', 'icons/Icon-512.png'];
self.addEventListener('install', event => event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(shell))));
self.addEventListener('activate', event => event.waitUntil((async () => {
  for (const key of await caches.keys()) {
    if (key.startsWith('mobimed-shell-') && key !== CACHE) await caches.delete(key);
  }
  await self.clients.claim();
})()));
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  const scope = new URL(self.registration.scope);
  if (event.request.method !== 'GET' || url.search || event.request.headers.has('authorization') || url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) return;
  const relative = url.pathname.slice(scope.pathname.length);
  if (!(shell.includes(relative) || relative === '' || relative.startsWith('assets/') || relative.startsWith('canvaskit/'))) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    try {
      const response = await fetch(event.request);
      if (response.ok) await cache.put(event.request, response.clone());
      return response;
    } catch {
      return await cache.match(event.request) || (event.request.mode === 'navigate' ? await cache.match(new URL('index.html', scope).href) : undefined) || Response.error();
    }
  })());
});

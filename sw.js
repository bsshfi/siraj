/* سِراج | SIRAJ — يشغّل التطبيق بدون إنترنت، ويحدّثه تلقائيًا، ويعرض الإشعارات
   مع كل تحديث: غيّر CACHE هنا و VERSION في config.js */
importScripts('config.js');
const CACHE = 'siraj-v2.4';
const FILES = ['./', 'index.html', 'config.js', 'sync.js', 'app.js', 'art.js', 'stories.js', 'stories-2.js', 'stories-3.js', 'play.js', 'english.js', 'manifest.webmanifest',
  'icons/icon-192.png', 'icons/icon-512.png', 'icons/apple-touch-icon.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(FILES.map((f) => new Request(f, { cache: 'reload' })))).then(() => self.skipWaiting()));
});
self.addEventListener('message', (e) => { if (e.data === 'skip') self.skipWaiting(); });
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE && k !== 'siraj-data').map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (CONFIG.API && req.url.startsWith(CONFIG.API)) return;            // السيرفر: بدون كاش
  if (url.origin === location.origin) {
    // ملفات التطبيق: من الإنترنت أولًا (عشان التحديثات توصل)، وإذا ما فيه إنترنت من الكاش
    e.respondWith(fetch(req, { cache: 'no-cache' }).then((res) => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
      return res;
    }).catch(() => caches.match(req, { ignoreSearch: true }).then((hit) => hit || caches.match('index.html'))));
    return;
  }
  // الخطوط ومكتبة QR: من الكاش أولًا
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req).then((res) => {
    if (res && (res.ok || res.type === 'opaque')) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
    return res;
  })));
});

/* ---------- الإشعارات ---------- */
async function localData() {
  try { const r = await (await caches.open('siraj-data')).match(location.origin + '/__family'); return r ? await r.json() : {}; } catch (e) { return {}; }
}
function joinNames(list) { return list.map((k) => k.n).join(' و'); }

async function onPush() {
  let items = [];
  try {
    const sub = await self.registration.pushManager.getSubscription();
    if (sub && CONFIG.API) {
      const r = await fetch(CONFIG.API.replace(/\/$/, '') + '/pending', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ endpoint: sub.endpoint }) });
      items = (await r.json()).items || [];
    }
  } catch (e) {}
  const data = await localData();
  const kids = data.kids || {};
  if (!items.length) items = [{ t: 'msg', title: 'سِراج 🌙', body: 'عندك جديد في سِراج' }];
  const shown = items.slice(-3).map((it) => {
    let title = 'سِراج 🌙', body = '';
    if (it.t === 'bed') {
      const sel = (data.sel || []).map((id) => kids[id]).filter(Boolean);
      const list = sel.length ? sel : Object.values(kids);
      title = '🌙 حان وقت حكاية الليلة';
      body = list.length ? `يا ${joinNames(list)}، سِراج ينتظركم بقصة جديدة ✨` : 'سِراج ينتظركم بقصة جديدة ✨';
    } else if (it.t === 'done') {
      const list = (it.kids || []).map((id) => kids[id]).filter(Boolean);
      const verb = list.length > 1 ? 'خلّصوا' : list[0] && list[0].g === 'f' ? 'خلّصت' : 'خلّص';
      title = '✅ قصة الليلة';
      body = list.length ? `${joinNames(list)} ${verb} قصة الليلة 🌙` : 'خلّص الأطفال قصة الليلة 🌙';
    } else {
      title = it.title || title; body = it.body || '';
    }
    return self.registration.showNotification(title, { body, icon: 'icons/icon-192.png', badge: 'icons/icon-192.png', lang: 'ar', dir: 'rtl', tag: it.t === 'msg' ? 'msg-' + Date.now() : it.t, data: { t: it.t } });
  });
  await Promise.all(shown);
}
self.addEventListener('push', (e) => e.waitUntil(onPush()));

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
    for (const c of list) if ('focus' in c) return c.focus();
    return self.clients.openWindow('./');
  }));
});

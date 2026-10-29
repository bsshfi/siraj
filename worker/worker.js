/* سِراج | SIRAJ — السيرفر (Cloudflare Worker + D1)
   - ربط العائلة ومزامنة بياناتها (مشفّرة من الجهاز، السيرفر ما يقدر يقراها)
   - تقدّم القراءة لكل جهاز (مشفّر)
   - الإشعارات: تذكير وقت القصة، "خلصوا قصة الليلة" لوليّ الأمر، ورسائلك للكل
   - الإدارة من admin.wamdarc.com (نفس ADMIN_KEY حق push-wamdarc)
   المتغيرات المطلوبة: VAPID_PUBLIC, VAPID_PRIVATE, ADMIN_KEY  وقاعدة D1 باسم DB
*/

const ORIGINS = ['https://siraj.wamdarc.com', 'https://admin.wamdarc.com', 'https://bsshfi.github.io'];
const MAX_BLOB = 300000;

export default {
  async fetch(req, env, ctx) {
    const origin = req.headers.get('Origin') || '';
    // لوحة الإدارة تفتح أحيانًا عبر http أو bsshfi.github.io قبل ما يجهز HTTPS، فنسمح لأي نطاق من wamdarc.com
    const allow = ORIGINS.includes(origin) || /^https?:\/\/([a-z0-9-]+\.)?wamdarc\.com$/.test(origin) || /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin) ? origin : ORIGINS[0];
    const cors = {
      'Access-Control-Allow-Origin': allow,
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type,X-Admin-Key,Authorization',
      'Vary': 'Origin'
    };
    if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
    const json = (o, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { ...cors, 'Content-Type': 'application/json; charset=utf-8' } });

    try {
      const url = new URL(req.url);
      const p = url.pathname.replace(/\/+$/, '');
      const now = Date.now();
      const body = req.method === 'POST' ? await req.json().catch(() => ({})) : {};
      const okId = (x) => typeof x === 'string' && /^[a-f0-9]{16,64}$/.test(x);
      const okDev = (x) => typeof x === 'string' && /^[a-z0-9]{4,24}$/.test(x);

      await ensureSchema(env);
      if (p === '' || p === '/health') {
        const { results } = await env.DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('families','progress','subs')").all();
        return json({ ok: true, app: 'siraj', tables: (results || []).map((r) => r.name) });
      }

      /* ----- العائلة ----- */
      if (p === '/family' && req.method === 'POST') {
        const { id, blob, rev } = body;
        if (!okId(id) || typeof blob !== 'string' || blob.length > MAX_BLOB || !Number.isInteger(rev)) return json({ error: 'bad' }, 400);
        const cur = await env.DB.prepare('SELECT rev FROM families WHERE id=?').bind(id).first();
        if (cur && cur.rev >= rev) return json({ ok: false, rev: cur.rev, stale: true });
        await env.DB.prepare('INSERT INTO families (id, blob, rev, updated) VALUES (?,?,?,?) ON CONFLICT(id) DO UPDATE SET blob=excluded.blob, rev=excluded.rev, updated=excluded.updated')
          .bind(id, blob, rev, now).run();
        return json({ ok: true, rev });
      }
      let m;
      if ((m = p.match(/^\/family\/([a-f0-9]{16,64})$/)) && req.method === 'GET') {
        const row = await env.DB.prepare('SELECT blob, rev, updated FROM families WHERE id=?').bind(m[1]).first();
        return row ? json(row) : json({ error: 'notfound' }, 404);
      }

      /* ----- تقدّم القراءة ----- */
      if (p === '/progress' && req.method === 'POST') {
        const { fam, dev, blob } = body;
        if (!okId(fam) || !okDev(dev) || typeof blob !== 'string' || blob.length > MAX_BLOB) return json({ error: 'bad' }, 400);
        await env.DB.prepare('INSERT INTO progress (fam, dev, blob, updated) VALUES (?,?,?,?) ON CONFLICT(fam, dev) DO UPDATE SET blob=excluded.blob, updated=excluded.updated')
          .bind(fam, dev, blob, now).run();
        return json({ ok: true });
      }
      if ((m = p.match(/^\/progress\/([a-f0-9]{16,64})$/)) && req.method === 'GET') {
        const { results } = await env.DB.prepare('SELECT dev, blob, updated FROM progress WHERE fam=?').bind(m[1]).all();
        return json({ items: results || [] });
      }

      /* ----- الاشتراك في الإشعارات ----- */
      if (p === '/sub' && req.method === 'POST') {
        const { endpoint, fam, dev, role, bedtime, tz, off } = body;
        if (typeof endpoint !== 'string' || !/^https:\/\//.test(endpoint) || endpoint.length > 1000) return json({ error: 'bad' }, 400);
        const eid = await sha(endpoint);
        if (off) { await env.DB.prepare('DELETE FROM subs WHERE eid=?').bind(eid).run(); return json({ ok: true }); }
        const bt = typeof bedtime === 'string' && /^\d{2}:\d{2}$/.test(bedtime) ? bedtime : '';
        await env.DB.prepare(`INSERT INTO subs (eid, endpoint, fam, dev, role, bedtime, tz, updated) VALUES (?,?,?,?,?,?,?,?)
          ON CONFLICT(eid) DO UPDATE SET endpoint=excluded.endpoint, fam=excluded.fam, dev=excluded.dev, role=excluded.role, bedtime=excluded.bedtime, tz=excluded.tz, updated=excluded.updated`)
          .bind(eid, endpoint, okId(fam) ? fam : null, okDev(dev) ? dev : null, role === 'parent' ? 'parent' : 'child', bt, Number.isInteger(tz) ? tz : 180, now).run();
        return json({ ok: true });
      }

      /* ----- الإشعارات المعلّقة (يسحبها الجهاز لما يوصله الإشعار) ----- */
      if (p === '/pending' && req.method === 'POST') {
        if (typeof body.endpoint !== 'string') return json({ items: [] });
        const eid = await sha(body.endpoint);
        const row = await env.DB.prepare('SELECT pending FROM subs WHERE eid=?').bind(eid).first();
        await env.DB.prepare('UPDATE subs SET pending=NULL WHERE eid=?').bind(eid).run();
        return json({ items: row && row.pending ? JSON.parse(row.pending) : [] });
      }

      /* ----- حدث: خلصوا القصة ← إشعار لأجهزة وليّ الأمر ----- */
      if (p === '/event' && req.method === 'POST') {
        const { fam, dev, kids, story } = body;
        if (!okId(fam) || !Array.isArray(kids)) return json({ error: 'bad' }, 400);
        const item = { t: 'done', kids: kids.slice(0, 8).map(String), story: String(story || '').slice(0, 12) };
        const { results } = await env.DB.prepare("SELECT eid, endpoint, pending FROM subs WHERE fam=? AND role='parent' AND (dev IS NULL OR dev<>?)").bind(fam, okDev(dev) ? dev : '').all();
        ctx.waitUntil(deliver(env, results || [], item));
        return json({ ok: true, sent: (results || []).length });
      }

      /* ----- الإدارة (لوحة admin.wamdarc.com) ----- */
      if (p === '/broadcast' && req.method === 'POST') {
        if (!env.ADMIN_KEY) return json({ error: 'no-key' }, 503);
        if (!isAdmin(req, env)) return json({ error: 'unauthorized' }, 401);
        const src = body.ar || body;
        const title = String(src.title || 'سِراج 🌙').trim().slice(0, 80), text = String(src.body || '').trim().slice(0, 300);
        if (!title && !text) return json({ error: 'missing' }, 400);
        const { results } = await env.DB.prepare('SELECT eid, endpoint, pending FROM subs').all();
        const total = (results || []).length;
        await env.DB.prepare('INSERT INTO messages (created, title, body, total) VALUES (?,?,?,?)').bind(now, title, text, total).run();
        ctx.waitUntil(deliver(env, results || [], { t: 'msg', title, body: text }));
        return json({ ok: true, sent: total });
      }
      if (p === '/stats' && req.method === 'GET') {
        if (!env.ADMIN_KEY) return json({ error: 'no-key' }, 503);
        if (!isAdmin(req, env)) return json({ error: 'unauthorized' }, 401);
        const f = await env.DB.prepare('SELECT COUNT(*) n FROM families').first();
        const d = await env.DB.prepare('SELECT COUNT(*) n, SUM(updated > ?) active FROM progress').bind(now - 7 * 864e5).first();
        const s = await env.DB.prepare("SELECT COUNT(*) n, SUM(role='parent') parents, SUM(role='child') kids FROM subs").first();
        const hist = (await env.DB.prepare('SELECT created, title, body, total FROM messages ORDER BY n DESC LIMIT 8').all()).results || [];
        return json({ families: f.n, devices: d.n || 0, activeWeek: d.active || 0, subs: s.n, parentDevices: s.parents || 0, kidDevices: s.kids || 0, history: hist });
      }

      return json({ error: 'notfound' }, 404);
    } catch (e) {
      return json({ error: 'server', detail: String(e && e.message || e) }, 500);
    }
  },

  /* كل دقيقة: تذكير وقت القصة لأجهزة الأطفال */
  async scheduled(event, env, ctx) {
    await ensureSchema(env);
    const { results } = await env.DB.prepare("SELECT eid, endpoint, pending, bedtime, tz, last_bed FROM subs WHERE role='child' AND bedtime<>''").all();
    const due = [];
    for (const r of results || []) {
      const local = new Date(Date.now() + (r.tz || 0) * 60000);
      const hm = String(local.getUTCHours()).padStart(2, '0') + ':' + String(local.getUTCMinutes()).padStart(2, '0');
      const day = local.toISOString().slice(0, 10);
      if (hm === r.bedtime && r.last_bed !== day) { due.push(r); r._day = day; }
    }
    for (const r of due) await env.DB.prepare('UPDATE subs SET last_bed=? WHERE eid=?').bind(r._day, r.eid).run();
    if (due.length) ctx.waitUntil(deliver(env, due, { t: 'bed' }));
  }
};

/* ---------- إنشاء الجداول تلقائيًا (أول تشغيل) ---------- */
let schemaReady = false;
async function ensureSchema(env) {
  if (schemaReady) return;
  await env.DB.batch([
    env.DB.prepare('CREATE TABLE IF NOT EXISTS families (id TEXT PRIMARY KEY, blob TEXT NOT NULL, rev INTEGER NOT NULL DEFAULT 0, updated INTEGER NOT NULL)'),
    env.DB.prepare('CREATE TABLE IF NOT EXISTS progress (fam TEXT NOT NULL, dev TEXT NOT NULL, blob TEXT NOT NULL, updated INTEGER NOT NULL, PRIMARY KEY (fam, dev))'),
    env.DB.prepare("CREATE TABLE IF NOT EXISTS subs (eid TEXT PRIMARY KEY, endpoint TEXT NOT NULL, fam TEXT, dev TEXT, role TEXT, bedtime TEXT DEFAULT '', tz INTEGER DEFAULT 180, last_bed TEXT, pending TEXT, updated INTEGER)"),
    env.DB.prepare('CREATE INDEX IF NOT EXISTS subs_fam ON subs (fam)'),
    env.DB.prepare('CREATE TABLE IF NOT EXISTS messages (n INTEGER PRIMARY KEY AUTOINCREMENT, created INTEGER, title TEXT, body TEXT, total INTEGER)')
  ]);
  schemaReady = true;
}

/* ---------- مفتاح الإدارة: نفس قيمة ADMIN_KEY في push-wamdarc ---------- */
const normKey = (k) => String(k || '').replace(/[٠-٩]/g, (d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).replace(/[۰-۹]/g, (d) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(d)).replace(/\s+/g, '');
function isAdmin(req, env) {
  let k = req.headers.get('X-Admin-Key') || (req.headers.get('Authorization') || '').replace(/^Bearer\s+/i, '');
  try { k = decodeURIComponent(k); } catch (e) {}
  const a = normKey(k), b = normKey(env.ADMIN_KEY);
  if (!a || a.length !== b.length) return false;
  let r = 0; for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

/* ---------- إرسال الإشعارات ---------- */
async function deliver(env, rows, item) {
  for (const r of rows) {
    let q = [];
    try { q = r.pending ? JSON.parse(r.pending) : []; } catch (e) {}
    q.push(item);
    await env.DB.prepare('UPDATE subs SET pending=? WHERE eid=?').bind(JSON.stringify(q.slice(-5)), r.eid).run();
  }
  const jwts = {};
  for (let i = 0; i < rows.length; i += 40) {
    await Promise.all(rows.slice(i, i + 40).map(async (r) => {
      try {
        const aud = new URL(r.endpoint).origin;
        jwts[aud] = jwts[aud] || await vapidJWT(env, aud);
        const res = await fetch(r.endpoint, {
          method: 'POST',
          headers: { Authorization: `vapid t=${jwts[aud]}, k=${env.VAPID_PUBLIC}`, TTL: '43200', Urgency: 'high', 'Content-Length': '0' }
        });
        // 404/410: الاشتراك انتهى · 401/403: الاشتراك مربوط بمفتاح قديم
        if ([401, 403, 404, 410].includes(res.status)) await env.DB.prepare('DELETE FROM subs WHERE eid=?').bind(r.eid).run();
      } catch (e) {}
    }));
  }
}

/* إشعار بدون محتوى: الجهاز يسحب نصّه من /pending — فما نحتاج تشفير المحتوى */
async function vapidJWT(env, aud) {
  const pub = b64uDec(env.VAPID_PUBLIC);
  const jwk = { kty: 'EC', crv: 'P-256', x: b64uEnc(pub.slice(1, 33)), y: b64uEnc(pub.slice(33, 65)), d: env.VAPID_PRIVATE, ext: true };
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
  const enc = (o) => b64uEnc(new TextEncoder().encode(JSON.stringify(o)));
  const data = enc({ typ: 'JWT', alg: 'ES256' }) + '.' + enc({ aud, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub: 'mailto:hello@wamdarc.com' });
  const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(data));
  return data + '.' + b64uEnc(new Uint8Array(sig));
}

async function sha(s) {
  const h = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s));
  return [...new Uint8Array(h)].map((b) => b.toString(16).padStart(2, '0')).join('').slice(0, 40);
}
function b64uEnc(bytes) { let s = ''; bytes.forEach((b) => (s += String.fromCharCode(b))); return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, ''); }
function b64uDec(str) { const s = atob(str.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((str.length + 3) % 4)); return Uint8Array.from(s, (c) => c.charCodeAt(0)); }

/* سِراج | SIRAJ — ربط العائلة والمزامنة
   رمز العائلة (مثل K7QPM-4XR2D) هو المفتاح:
   - السيرفر يعرف العائلة ببصمة الرمز فقط
   - كل البيانات تنشفّر بالرمز قبل ما تطلع من الجهاز (AES-GCM)، فالسيرفر ما يقدر يقرأ أسماء الأطفال */
const Sync = (() => {
  const ALPH = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  const te = new TextEncoder(), td = new TextDecoder();
  const keys = {};

  function newCode() {
    const a = crypto.getRandomValues(new Uint8Array(10));
    let s = ''; a.forEach((b) => (s += ALPH[b % ALPH.length]));
    return s.slice(0, 5) + '-' + s.slice(5);
  }
  // يقبل الرمز بأي شكل: مع مسافات أو حروف مخفية، أو داخل رسالة/رابط الربط كامل، أو بأرقام عربية
  function clean(c) {
    c = String(c || '').replace(/[٠-٩]/g, (d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).replace(/[۰-۹]/g, (d) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(d)).toUpperCase();
    const m = c.match(/JOIN=([A-Z0-9]{5}-?[A-Z0-9]{5})/) || c.match(/(?:^|[^A-Z0-9])([A-Z0-9]{5}-[A-Z0-9]{5})(?![A-Z0-9])/);
    return (m ? m[1] : c).replace(/[^A-Z0-9]/g, '');
  }
  function norm(c) {
    c = clean(c);
    if (c.length !== 10 || [...c].some((x) => !ALPH.includes(x))) return '';
    return c.slice(0, 5) + '-' + c.slice(5);
  }
  function pretty(c) { c = clean(c).slice(0, 10); return c.length > 5 ? c.slice(0, 5) + '-' + c.slice(5) : c; }
  const hex = (buf) => [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
  function b64(bytes) { let s = ''; for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000)); return btoa(s); }
  const unb64 = (s) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));

  async function famId(code) { return hex(await crypto.subtle.digest('SHA-256', te.encode('siraj-id:' + code))).slice(0, 32); }
  async function key(code) {
    if (keys[code]) return keys[code];
    const base = await crypto.subtle.importKey('raw', te.encode(code), 'PBKDF2', false, ['deriveKey']);
    keys[code] = await crypto.subtle.deriveKey({ name: 'PBKDF2', salt: te.encode('siraj-salt-v1'), iterations: 100000, hash: 'SHA-256' },
      base, { name: 'AES-GCM', length: 256 }, false, ['encrypt', 'decrypt']);
    return keys[code];
  }
  async function seal(code, obj) {
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const ct = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, await key(code), te.encode(JSON.stringify(obj))));
    const out = new Uint8Array(12 + ct.length); out.set(iv); out.set(ct, 12);
    return b64(out);
  }
  async function open(code, blob) {
    const raw = unb64(blob);
    const pt = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: raw.slice(0, 12) }, await key(code), raw.slice(12));
    return JSON.parse(td.decode(pt));
  }

  const online = () => !!CONFIG.API && navigator.onLine !== false;
  async function api(path, body) {
    const ctl = new AbortController(); const t = setTimeout(() => ctl.abort(), 12000);
    try {
      const r = await fetch(CONFIG.API.replace(/\/$/, '') + path, body === undefined ? { signal: ctl.signal, cache: 'no-store' }
        : { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), signal: ctl.signal });
      const j = await r.json().catch(() => ({}));
      if (!r.ok && r.status !== 404) throw new Error(j.error || r.status);
      return { status: r.status, ...j };
    } finally { clearTimeout(t); }
  }

  return {
    newCode, norm, pretty, online,
    async pushFamily(code, fam, rev) { return api('/family', { id: await famId(code), blob: await seal(code, fam), rev }); },
    async pullFamily(code) {
      const r = await api('/family/' + await famId(code));
      if (r.status === 404 || !r.blob) return null;
      return { fam: await open(code, r.blob), rev: r.rev };
    },
    async pushProgress(code, dev, data) { return api('/progress', { fam: await famId(code), dev, blob: await seal(code, data) }); },
    async pullProgress(code) {
      const r = await api('/progress/' + await famId(code));
      const out = [];
      for (const it of r.items || []) { try { out.push({ dev: it.dev, updated: it.updated, ...(await open(code, it.blob)) }); } catch (e) {} }
      return out;
    },
    async event(code, dev, kids, story) { return api('/event', { fam: await famId(code), dev, kids, story }); },
    async sub(code, dev, role, bedtime, subscription, off) {
      return api('/sub', { endpoint: subscription.endpoint, fam: code ? await famId(code) : null, dev, role, bedtime, tz: -new Date().getTimezoneOffset(), off: !!off });
    }
  };
})();

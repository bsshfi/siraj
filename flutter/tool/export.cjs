/* يصدّر بيانات سراج من نسخة الويب (جذر المستودع) إلى ملفات يقرأها تطبيق Flutter:
   assets/data/stories.json  — كل القصص
   assets/scenes/<name>.svg  — رسمة كل مشهد (بدون الأطفال)
   assets/avatars/boy.svg, girl.svg — شخصيات افتراضية
   يشتغل في GitHub Actions قبل البناء، فأي قصة جديدة في الموقع تدخل التطبيق تلقائيًا. */
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.resolve(__dirname, '..', 'assets');
const files = ['art.js', 'stories.js', 'stories-2.js', 'stories-3.js', 'stories-4.js', 'stories-5.js', 'stories-6.js', 'stories-7.js', 'young.js', 'extra.js'];
const noop = () => {}, el = () => ({ style: {}, classList: { add: noop, remove: noop, toggle: noop }, appendChild: noop, setAttribute: noop, addEventListener: noop });
const ctx = { console, Math, Date, JSON, setTimeout: noop, setInterval: noop, localStorage: { getItem: () => null, setItem: noop },
  document: { getElementById: () => null, querySelector: () => null, querySelectorAll: () => [], createElement: el, addEventListener: noop, body: el(), head: el(), documentElement: el() },
  navigator: { userAgent: 'node' }, location: { hash: '', search: '' }, addEventListener: noop, matchMedia: () => ({ matches: false, addEventListener: noop }) };
ctx.window = ctx; vm.createContext(ctx);
let src = '';
for (const f of files) { const p = path.join(ROOT, f); if (fs.existsSync(p)) src += fs.readFileSync(p, 'utf8') + '\n;\n'; }
src += ';globalThis.__ART = typeof ART !== "undefined" ? ART : null; globalThis.__STORIES = typeof STORIES !== "undefined" ? STORIES : [];';
try { vm.runInContext(src, ctx, { filename: 'siraj-web.js' }); } catch (e) { console.error('تحذير أثناء التحميل:', e.message); }
const ART = ctx.__ART, STORIES = ctx.__STORIES;
if (!ART || !STORIES.length) { console.error('✗ ما قدرت أقرأ القصص أو الرسومات'); process.exit(1); }
fs.mkdirSync(path.join(OUT, 'data'), { recursive: true });
fs.mkdirSync(path.join(OUT, 'scenes'), { recursive: true });
fs.mkdirSync(path.join(OUT, 'avatars'), { recursive: true });
const stories = STORIES.map((s) => Object.assign({}, s, { scene: s.scene || 'home',
  pages: (s.pages || []).map((p) => Object.assign({}, p, { s: p.s || s.scene || 'home' })) }));
fs.writeFileSync(path.join(OUT, 'data', 'stories.json'), JSON.stringify(stories));
const clean = (svg) => svg.replace(/ class="[^"]*"/g, '').replace(/<animate[^>]*\/>/g, '').replace(/<animate[\s\S]*?<\/animate>/g, '');
let n = 0;
for (const sc of ART.SCENES) { fs.writeFileSync(path.join(OUT, 'scenes', sc + '.svg'), clean(ART.page(sc, '', [])).replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ')); n++; }
const D = ART.DEFAULTS || {};
for (const g of ['m', 'f']) {
  const svg = ART.avatarSVG(D[g], g, 120);
  fs.writeFileSync(path.join(OUT, 'avatars', (g === 'm' ? 'boy' : 'girl') + '.svg'), clean(svg).replace(/^<svg (?!xmlns)/, '<svg xmlns="http://www.w3.org/2000/svg" '));
}
fs.mkdirSync(path.join(OUT, 'js'), { recursive: true });
fs.copyFileSync(path.join(ROOT, 'art.js'), path.join(OUT, 'js', 'art.js'));
console.log(`✓ ${stories.length} قصة، ${n} مشهد`);

/* ---- المرحلة ٣: محتوى أنا/اكتشف/العب وتعلّم ----
   نقرأ الثوابت من داخل وحدات الويب (english/space/night/trips-data) ونكتبها assets/data/learn.json */
(() => {
  const ctx2 = Object.assign({}, ctx, { App: { ctx: () => ({}) }, ART });
  ctx2.window = ctx2; vm.createContext(ctx2);
  const grab = (file, mod) => {
    let s = fs.readFileSync(path.join(ROOT, file), 'utf8');
    const i = s.lastIndexOf('\n  return {');
    if (i > 0 && mod) s = s.slice(0, i) + `\n  globalThis.__EV_${mod} = (x) => { try { return eval(x); } catch (e) { return null; } };` + s.slice(i);
    return s + '\n;\n';
  };
  let s2 = grab('trips-data.js') + fs.readFileSync(path.join(ROOT, 'english-2.js'), 'utf8') + ';globalThis.__ADV = EN_ADV;\n' + grab('english.js', 'EN') + grab('english-3.js', 'EN2') + grab('space.js', 'SP') + grab('night.js', 'NI');
  s2 += ';globalThis.__TRIPS = { COUNTRIES: typeof COUNTRIES !== "undefined" ? COUNTRIES : [], REGIONS: typeof REGIONS !== "undefined" ? REGIONS : [], INFO: typeof COUNTRY_INFO !== "undefined" ? COUNTRY_INFO : {} };';
  try { vm.runInContext(s2, ctx2, { filename: 'siraj-learn.js' }); } catch (e) { console.error('تحذير (التعلّم):', e.message); }
  const ev = (m, x) => (ctx2['__EV_' + m] ? ctx2['__EV_' + m](x) : null);
  const out = {
    letters: ev('EN', 'LETTERS') || [], words: ev('EN', 'WORDS') || {}, sentences: ev('EN', 'SENT') || [], sight: ev('EN2', 'SIGHT') || [],
    phases: ev('SP', 'PHASES') || [], mansions: ev('SP', 'MAN') || [], planets: ev('SP', 'PL') || [], stars: ev('SP', 'STARS') || [], spaceQuiz: ev('SP', 'QUIZ') || [],
    adhkar: ev('NI', 'ADHKAR') || [],
    adv: ctx2.__ADV || {}, snd: ev('EN2', 'SND') || {}, ex: ev('EN2', 'EX') || {}, fam: ev('EN2', 'FAM') || {},
    countries: ctx2.__TRIPS.COUNTRIES, regions: ctx2.__TRIPS.REGIONS, info: ctx2.__TRIPS.INFO
  };
  fs.writeFileSync(path.join(OUT, 'data', 'learn.json'), JSON.stringify(out));
  console.log(`✓ تعلّم: ${out.letters.length} حرف، ${Object.keys(out.words).length} فئة كلمات، ${out.planets.length} كوكب، ${out.countries.length} دولة، ${out.adhkar.length} ذكر، ${out.mansions.length} منزلة`);
  if (!out.letters.length || !out.countries.length || !out.planets.length) { console.error('✗ محتوى التعلّم ناقص'); process.exit(1); }
})();

/* ---- خيارات محرّر الشخصيات + سياسة الخصوصية (عشان ما يطلع أي رابط ويب داخل التطبيق) ---- */
(() => {
  const pick = ['HEADS', 'STYLES', 'OUTFITS', 'SKIN', 'HAIR', 'SHIRT', 'HEADC', 'PANTS', 'LEAGUES', 'SHOES', 'SHOEC', 'DEFAULTS', 'CLUBS', 'ACC'];
  const art = {}; pick.forEach((k) => (art[k] = ART[k]));
  fs.writeFileSync(path.join(OUT, 'data', 'art.json'), JSON.stringify(art));
  const html = fs.readFileSync(path.join(ROOT, 'privacy.html'), 'utf8');
  const m = html.match(/<main id="ar"[\s\S]*?<\/main>/);
  const strip = (s) => s.replace(/<[^>]+>/g, '').replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
  const out = [];
  if (m) {
    const re = /<h2[^>]*>([\s\S]*?)<\/h2>|<li[^>]*>([\s\S]*?)<\/li>|<p[^>]*>([\s\S]*?)<\/p>/g;
    let x, cur = null;
    while ((x = re.exec(m[0]))) {
      if (x[1] != null) { const e = (x[1].match(/<span>([\s\S]*?)<\/span>/) || [])[1] || ''; cur = { e: strip(e), h: strip(x[1].replace(/<span>[\s\S]*?<\/span>/, '')), b: [] }; out.push(cur); }
      else if (cur) cur.b.push((x[2] != null ? '• ' : '') + strip(x[2] != null ? x[2] : x[3]));
    }
  }
  const upd = (html.match(/آخر تحديث:\s*([^<]+)/) || [])[1] || '';
  fs.writeFileSync(path.join(OUT, 'data', 'privacy.json'), JSON.stringify({ updated: upd.trim(), sections: out }));
  console.log(`✓ محرّر الشخصيات: ${ART.CLUBS.length} نادي · الخصوصية: ${out.length} قسم`);
  if (out.length < 5) { console.error('✗ ما قدرت أقرأ سياسة الخصوصية'); process.exit(1); }
})();

// شعار WAMD ARC لشاشة حول التطبيق
for (const n of ['wamdarc-light.png', 'wamdarc-dark.png']) { try { fs.copyFileSync(path.join(ROOT, n), path.join(OUT, 'brand', n)); } catch (e) { console.error('تحذير: ما لقيت', n); } }

/* ---- غرفتي: قطع الغرفة ورسوماتها من room.js ---- */
(() => {
  let s = fs.readFileSync(path.join(ROOT, 'room.js'), 'utf8');
  const i = s.lastIndexOf('\n  return {');
  s = s.slice(0, i) + '\n  globalThis.__ROOM = { ITEMS, BOX };' + s.slice(i);
  const c3 = { console, Math, Date, JSON, App: { ctx: () => ({}) } }; vm.createContext(c3);
  vm.runInContext(s, c3);
  fs.writeFileSync(path.join(OUT, 'data', 'room.json'), JSON.stringify(c3.__ROOM));
  console.log(`✓ غرفتي: ${c3.__ROOM.ITEMS.length} قطعة`);
})();

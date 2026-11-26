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
console.log(`✓ ${stories.length} قصة، ${n} مشهد`);

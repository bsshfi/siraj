/* يبني مجلد www لتطبيق الأندرويد من ملفات الويب اللي في جذر المستودع.
   ملفات الويب نفسها ما تتعدّل أبدًا — كل التغييرات هنا على نسخة داخل native/www فقط.
   لو تغيّر نص في نسخة الويب وما لقى الاستبدال مكانه، البناء يوقف برسالة واضحة بدل ما يطلع تطبيق ناقص. */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const NATIVE = path.resolve(here, '..');
const ROOT = path.resolve(NATIVE, '..');
const OUT = path.join(NATIVE, 'www');
const NM = path.join(NATIVE, 'node_modules');

// ملفات الويب اللي ما تدخل التطبيق
const SKIP = new Set(['.git', '.github', 'native', 'worker', 'node_modules', 'CNAME', 'README.md', 'wrangler.toml',
  'sw.js', 'manifest.webmanifest', 'wamd-stats.js', '.gitignore']);

function fail(msg) { console.error('✗ ' + msg); process.exit(1); }
function replaceOnce(src, from, to, file) {
  if (!src.includes(from)) fail(`ما لقيت النص المطلوب في ${file}:\n  ${from.slice(0, 120)}`);
  return src.replace(from, to);
}

fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

// ١) نسخ ملفات الويب
for (const name of fs.readdirSync(ROOT)) {
  if (SKIP.has(name) || name.startsWith('.')) continue;
  fs.cpSync(path.join(ROOT, name), path.join(OUT, name), { recursive: true });
}

// ٢) الخطوط والمكتبات محليًا (يشتغل بدون إنترنت، ويطابق سياسة تطبيقات الأطفال)
const fontPkg = path.join(NM, '@fontsource', 'baloo-bhaijaan-2');
const fontOut = path.join(OUT, 'vendor', 'fonts');
fs.mkdirSync(path.join(fontOut, 'files'), { recursive: true });
let fontCss = '';
for (const w of [400, 600, 700, 800]) {
  const css = fs.readFileSync(path.join(fontPkg, `${w}.css`), 'utf8');
  fontCss += css + '\n';
  for (const m of css.matchAll(/url\(\.\/files\/([^)]+)\)/g))
    fs.copyFileSync(path.join(fontPkg, 'files', m[1]), path.join(fontOut, 'files', m[1]));
}
fs.writeFileSync(path.join(fontOut, 'fonts.css'), fontCss);
fs.copyFileSync(path.join(NM, 'qrcode-generator', 'qrcode.js'), path.join(OUT, 'vendor', 'qrcode.js'));
fs.copyFileSync(path.join(NATIVE, 'src', 'native-shim.js'), path.join(OUT, 'native-shim.js'));

// ٣) index.html
let html = fs.readFileSync(path.join(OUT, 'index.html'), 'utf8');
html = html.replace(/\s*<link[^>]+fonts\.(googleapis|gstatic)\.com[^>]*>/g, '');
if (/fonts\.googleapis\.com/.test(html)) fail('بقي رابط Google Fonts في index.html');
html = html.replace(/\s*<link[^>]+rel="manifest"[^>]*>/g, '');
html = html.replace(/\s*<script[^>]+wamd-stats\.js[^>]*><\/script>/g, '');
html = replaceOnce(html, '<script src="config.js',
  '<link rel="stylesheet" href="vendor/fonts/fonts.css">\n<script src="native-shim.js"></script>\n<script src="vendor/qrcode.js"></script>\n<script src="config.js', 'index.html');
fs.writeFileSync(path.join(OUT, 'index.html'), html);

// ٤) config.js: بدون إشعارات السيرفر (التذكير صار محلي من الجهاز)
let cfg = fs.readFileSync(path.join(OUT, 'config.js'), 'utf8');
cfg = cfg.replace(/VAPID:\s*'[^']*'/, "VAPID: ''");
if (!/VAPID: ''/.test(cfg)) fail('ما قدرت أعدّل VAPID في config.js');
fs.writeFileSync(path.join(OUT, 'config.js'), cfg);

// ٥) app.js: نصوص الإشعارات تناسب التذكير المحلي
let app = fs.readFileSync(path.join(OUT, 'app.js'), 'utf8');
app = replaceOnce(app, "'الإشعارات تحتاج إعداد السيرفر أولًا'", "'التذكير يطلع من جهاز الطفل نفسه 🔔'", 'app.js');
app = replaceOnce(app, "'التذكير يوصل لأجهزة الأطفال المربوطة، وأنت يوصلك إشعار لما يخلصون القصة.'",
  "'التذكير يطلع على أجهزة الأطفال اللي عليها تطبيق سِراج في وقت القصة.'", 'app.js');
fs.writeFileSync(path.join(OUT, 'app.js'), app);

// ٦) تأكد إن ما فيه أي سكربت أو ستايل يتحمّل من الإنترنت
const remote = [...html.matchAll(/<(?:script|link)[^>]+(?:src|href)="(https?:[^"]+)"/g)].map((m) => m[1]);
if (remote.length) fail('ملفات خارجية باقية في index.html: ' + remote.join(', '));

console.log('✓ www جاهز — الإصدار', (cfg.match(/VERSION:\s*'([^']+)'/) || [])[1]);

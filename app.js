/* سِراج | SIRAJ — منطق التطبيق */
const VERSION = '1.0';
const KEY = 'siraj';

const App = (() => {
  const $ = (id) => document.getElementById(id);
  let S = load();
  let sel = [];               // أبطال الليلة (أول واحد = البطل)
  let R = null;               // حالة القارئ
  let editing = null;         // الطفل اللي نعدّله
  let pinBuf = '', pinCb = null;
  let installEvt = null;

  /* ---------- التخزين ---------- */
  function load() {
    try { return JSON.parse(localStorage.getItem(KEY)) || fresh(); } catch (e) { return fresh(); }
  }
  function fresh() { return { v: 1, kids: [], pin: '', read: {}, fav: [], voice: false, sel: [] }; }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} }

  /* ---------- أدوات ---------- */
  const uid = () => Math.random().toString(36).slice(2, 8);
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  function toast(msg) { const t = $('toast'); t.textContent = msg; t.classList.add('on'); setTimeout(() => t.classList.remove('on'), 2200); }
  function dateKey(d = new Date()) { return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
  function dayOfYear(d = new Date()) { return Math.floor((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 0)) / 864e5); }
  function hash(str) { let h = 2166136261; for (const c of str) { h ^= c.codePointAt(0); h = Math.imul(h, 16777619); } return h >>> 0; }
  function rng(seed) { return () => { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }

  /* ---------- قصة اليوم: مربوطة بالتاريخ وأسماء الأطفال ---------- */
  function storyOfDay(d = new Date()) {
    const names = S.kids.map((k) => k.name.trim()).sort().join('|');
    const order = STORIES.map((_, i) => i);
    const r = rng(hash(names + '#' + d.getFullYear()));
    for (let i = order.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [order[i], order[j]] = [order[j], order[i]]; }
    return STORIES[order[(dayOfYear(d) - 1) % order.length]];
  }

  /* ---------- محرّك القوالب ---------- */
  function fill(str, heroes) {
    const [hero, ...rest] = heroes;
    const g = hero.g === 'f' ? 1 : 0;
    const cg = rest.length > 1 ? 2 : rest.length === 1 ? (rest[0].g === 'f' ? 1 : 0) : 0;
    const fr = rest.map((k) => k.name).join(' و');
    let s = str.replace(/\[\[([\s\S]*?)\]\]/g, (_, inner) => (rest.length ? inner : ''));
    s = s.replace(/\{\{([^{}]*)\}\}/g, (_, x) => { const o = x.split('|'); return o[cg] ?? o[o.length - 1]; });
    s = s.replace(/\{([^{}|]*)\|([^{}|]*)\}/g, (_, a, b) => (g ? b : a));
    return s.replace(/\{n\}/g, hero.name).replace(/\{fr\}/g, fr);
  }

  /* ---------- التنقل ---------- */
  function show(id) {
    document.querySelectorAll('.screen').forEach((s) => s.classList.remove('on'));
    $(id).classList.add('on');
    window.scrollTo(0, 0);
    if (id === 'home') renderHome();
    if (id === 'settings') renderSettings();
  }

  /* ---------- الترحيب والتثبيت ---------- */
  const standalone = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone;
  const isIOS = () => /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  function renderWelcome() {
    $('installSteps').innerHTML = isIOS()
      ? '<b>أضفه للشاشة الرئيسية ليعمل كتطبيق:</b><br>١. اضغط زر المشاركة <b>⬆️</b> أسفل الشاشة<br>٢. اختر <b>«إضافة إلى الشاشة الرئيسية»</b><br>٣. افتح سِراج من أيقونته 🌙'
      : '<b>أضفه للشاشة الرئيسية ليعمل كتطبيق:</b><br>١. اضغط قائمة المتصفح <b>⋮</b><br>٢. اختر <b>«تثبيت التطبيق»</b> أو «إضافة إلى الشاشة الرئيسية»<br>٣. افتح سِراج من أيقونته 🌙';
  }
  function skipWelcome() { try { sessionStorage.setItem('siraj-skip', '1'); } catch (e) {} start(); }

  /* ---------- الإعداد الأول ---------- */
  function renderKidList(el, withActions) {
    el.innerHTML = S.kids.length ? S.kids.map((k) => `
      <div class="li">${ART.avatarSVG(k.av, k.g, 44)}<span class="nm">${esc(k.name)}</span>
      ${withActions ? `<button class="small" onclick="App.editKid('${k.id}')">تعديل</button><button class="small del" onclick="App.delKid('${k.id}')">حذف</button>` : `<button class="small" onclick="App.editKid('${k.id}')">تعديل</button>`}
      </div>`).join('') : '<p class="muted" style="text-align:center">لا يوجد أطفال بعد</p>';
  }
  function finishSetup() {
    const pin = $('setupPin').value.replace(/\D/g, '');
    if (!S.kids.length) return toast('أضف طفلًا واحدًا على الأقل');
    if (pin.length !== 4) return toast('الرمز لازم يكون ٤ أرقام');
    S.pin = pin; save(); show('home');
  }

  /* ---------- تعديل طفل ---------- */
  function editKid(id) {
    const k = S.kids.find((x) => x.id === id);
    editing = k ? JSON.parse(JSON.stringify(k)) : { id: uid(), name: '', g: 'm', age: 2, av: { skin: 0, hair: 0, shirt: Math.floor(Math.random() * 7), hijab: 0 } };
    $('kidTitle').textContent = k ? 'تعديل ' + k.name : 'طفل جديد';
    $('kidName').value = editing.name;
    buildKidForm(); $('kidModal').classList.add('on');
  }
  function buildKidForm() {
    const e = editing;
    const seg = (id, val, set) => { $(id).querySelectorAll('button').forEach((b) => { b.classList.toggle('on', b.dataset.v == val); b.onclick = () => { set(b.dataset.v); buildKidForm(); }; }); };
    seg('kidG', e.g, (v) => { e.g = v; if (v === 'm') e.av.hijab = 0; });
    seg('kidAge', e.age, (v) => (e.age = +v));
    seg('kidHijab', e.av.hijab ? 1 : 0, (v) => (e.av.hijab = +v));
    const sw = (id, arr, key) => { $(id).innerHTML = arr.map((c, i) => `<button class="sw ${e.av[key] === i ? 'on' : ''}" style="background:${c}" data-i="${i}"></button>`).join(''); $(id).querySelectorAll('.sw').forEach((b) => (b.onclick = () => { e.av[key] = +b.dataset.i; buildKidForm(); })); };
    sw('kidSkin', ART.SKIN, 'skin'); sw('kidHair', ART.HAIR, 'hair'); sw('kidShirt', ART.SHIRT, 'shirt');
    $('hijabRow').style.display = e.g === 'f' ? '' : 'none';
    const hideHair = e.g === 'f' && e.av.hijab;
    $('kidHair').style.display = $('hairLbl').style.display = hideHair ? 'none' : '';
    $('kidPreview').innerHTML = ART.avatarSVG(e.av, e.g, 110);
  }
  function saveKid() {
    const name = $('kidName').value.trim();
    if (!name) return toast('اكتب اسم الطفل');
    editing.name = name;
    const i = S.kids.findIndex((x) => x.id === editing.id);
    if (i >= 0) S.kids[i] = editing; else S.kids.push(editing);
    save(); closeModal('kidModal');
    renderKidList($('setupKids'), false);
    if ($('settings').classList.contains('on')) renderSettings();
  }
  function delKid(id) {
    const k = S.kids.find((x) => x.id === id);
    if (!k || !confirm('حذف ' + k.name + '؟')) return;
    S.kids = S.kids.filter((x) => x.id !== id); S.sel = (S.sel || []).filter((x) => x !== id);
    save(); renderSettings();
  }
  function closeModal(id) { $(id).classList.remove('on'); }

  /* ---------- الرئيسية ---------- */
  function heroes() { return sel.map((id) => S.kids.find((k) => k.id === id)).filter(Boolean); }
  function renderHome() {
    sel = (S.sel || []).filter((id) => S.kids.some((k) => k.id === id));
    if (!sel.length && S.kids.length) sel = [S.kids[0].id];
    const h = new Date().getHours();
    $('hello').textContent = (h >= 18 || h < 4 ? 'مساء الخير' : 'أهلًا') + '، جاهزين لحكاية الليلة؟ 🌙';
    $('kids').innerHTML = S.kids.map((k) => {
      const i = sel.indexOf(k.id);
      return `<button class="kid ${i >= 0 ? 'sel' : ''} ${i === 0 ? 'hero' : ''}" onclick="App.pick('${k.id}')"><span class="badge">البطل ⭐</span>${ART.avatarSVG(k.av, k.g, 78)}<div class="nm">${esc(k.name)}</div></button>`;
    }).join('');
    const st = storyOfDay(), hs = heroes(), done = S.read[st.id] === dateKey();
    $('tonightCard').innerHTML = hs.length ? `${ART.page(st.scene, '✨', hs)}
      <div class="info"><p class="title">${esc(fill(st.title, hs))}</p><span class="tag">${esc(st.value)}</span>
      <button class="btn" style="margin-top:14px" onclick="App.openStory('${st.id}')">${done ? 'اقرأها مرة ثانية 🔁' : 'ابدأ قصة الليلة ✨'}</button></div>`
      : '<div class="info"><p class="muted">اختر بطلًا واحدًا على الأقل</p></div>';
    $('ver').textContent = 'v' + VERSION;
    renderLib();
  }
  function pick(id) {
    const i = sel.indexOf(id);
    if (i >= 0) sel.splice(i, 1); else sel.push(id);
    S.sel = sel.slice(); save(); renderHome();
  }
  function tab(t) {
    $('tabTonight').classList.toggle('on', t === 'tonight'); $('tabLib').classList.toggle('on', t === 'lib');
    $('paneTonight').style.display = t === 'tonight' ? '' : 'none'; $('paneLib').style.display = t === 'lib' ? '' : 'none';
  }
  function renderLib() {
    const hs = heroes().length ? heroes() : S.kids.slice(0, 1);
    const ids = Object.keys(S.read).sort((a, b) => (S.fav.includes(b) - S.fav.includes(a)) || S.read[b].localeCompare(S.read[a]));
    const items = ids.map((id) => STORIES.find((s) => s.id === id)).filter(Boolean);
    $('lib').innerHTML = items.length && hs.length ? items.map((s) => `<button class="item" onclick="App.openStory('${s.id}')">${ART.page(s.scene, S.fav.includes(s.id) ? '⭐' : '', hs)}<div>${esc(fill(s.title, hs))}</div></button>`).join('')
      : '<p class="empty" style="grid-column:1/-1">القصص اللي تقرونها تنحفظ هنا، وتقدرون ترجعون لها متى ما حبيتوا 📚</p>';
  }

  /* ---------- القارئ ---------- */
  function openStory(id) {
    const hs = heroes();
    if (!hs.length) return toast('اختر بطل القصة أولًا');
    const st = STORIES.find((s) => s.id === id);
    R = { st, hs, i: 0, total: st.pages.length + 2 };
    show('reader'); renderPage();
  }
  function renderPage() {
    const { st, hs, i, total } = R;
    $('favBtn').textContent = S.fav.includes(st.id) ? '⭐' : '☆';
    $('voiceBtn').textContent = S.voice ? '🔊' : '🔈';
    const dots = `<div class="dots">${Array.from({ length: total - 1 }, (_, k) => `<i class="${k === Math.min(i, total - 2) ? 'on' : ''}"></i>`).join('')}</div>`;
    let html = '', nav = '', say = '';
    if (i < st.pages.length) {
      const p = st.pages[i], txt = fill(p.t, hs);
      html = (i === 0 ? `<h2 style="text-align:center;color:var(--yellow);margin:0 0 10px">${esc(fill(st.title, hs))}</h2>` : '') + ART.page(p.s, p.p, hs) + dots + `<p class="ptext anim">${esc(txt)}</p>`;
      say = (i === 0 ? fill(st.title, hs) + '. ' : '') + txt;
      nav = `${i > 0 ? '<button class="btn alt" onclick="App.step(-1)">→ السابق</button>' : ''}<button class="btn" onclick="App.step(1)">التالي ←</button>`;
    } else if (i === st.pages.length) {
      const q = fill(st.q, hs);
      html = ART.page('night', '💭', hs) + dots + `<p class="ptext" style="text-align:center;color:var(--yellow);margin-bottom:8px">سؤال قبل النوم</p><div class="q anim">${esc(q)}</div>`;
      say = 'سؤال قبل النوم. ' + q;
      nav = '<button class="btn alt" onclick="App.step(-1)">→ السابق</button><button class="btn" onclick="App.step(1)">النهاية 🌙</button>';
      S.read[st.id] = dateKey(); save();
    } else {
      const names = hs.map((k) => k.name).join(' و');
      html = `<div class="goodnight"><div class="moon">🌙</div><h1>تصبحون على خير</h1><p class="ptext">نومًا هنيئًا يا ${esc(names)} ✨<br>وموعدنا مع حكايةٍ جديدة غدًا</p></div>`;
      say = 'تصبحون على خير يا ' + names;
      nav = '<button class="btn alt" onclick="App.closeReader()">إغلاق</button>';
    }
    $('stage').innerHTML = html; $('nav').innerHTML = nav;
    speak(say);
  }
  function step(d) { R.i = Math.max(0, Math.min(R.total - 1, R.i + d)); window.scrollTo(0, 0); renderPage(); }
  function closeReader() { stopSpeak(); R = null; show('home'); }
  function toggleFav() {
    const id = R.st.id, i = S.fav.indexOf(id);
    if (i >= 0) S.fav.splice(i, 1); else { S.fav.push(id); toast('أضيفت للمفضلة ⭐'); }
    if (!S.read[id]) S.read[id] = dateKey();
    save(); $('favBtn').textContent = S.fav.includes(id) ? '⭐' : '☆';
  }

  /* ---------- القراءة بالصوت ---------- */
  function arVoice() { const v = speechSynthesis.getVoices(); return v.find((x) => /^ar[-_]SA/i.test(x.lang)) || v.find((x) => /^ar/i.test(x.lang)); }
  function speak(text) {
    stopSpeak();
    if (!S.voice || !('speechSynthesis' in window)) return;
    const u = new SpeechSynthesisUtterance(text.replace(/[«»]/g, ''));
    const v = arVoice(); if (v) u.voice = v;
    u.lang = v ? v.lang : 'ar-SA'; u.rate = .85; u.pitch = 1.05;
    speechSynthesis.speak(u);
  }
  function stopSpeak() { if ('speechSynthesis' in window) speechSynthesis.cancel(); }
  function toggleVoice() {
    S.voice = !S.voice; save(); $('voiceBtn').textContent = S.voice ? '🔊' : '🔈';
    if (S.voice) { if (!arVoice() && 'speechSynthesis' in window) toast('قد لا يتوفر صوت عربي على هذا الجهاز'); renderPage(); } else stopSpeak();
  }

  /* ---------- رمز وليّ الأمر ---------- */
  function askPin(cb) {
    pinBuf = ''; pinCb = cb; drawPin();
    $('pinPad').innerHTML = [1, 2, 3, 4, 5, 6, 7, 8, 9, '⌫', 0, '✓'].map((x) => `<button data-k="${x}">${x}</button>`).join('');
    $('pinPad').querySelectorAll('button').forEach((b) => (b.onclick = () => {
      const k = b.dataset.k;
      if (k === '⌫') pinBuf = pinBuf.slice(0, -1); else if (k !== '✓' && pinBuf.length < 4) pinBuf += k;
      drawPin();
      if (pinBuf.length === 4) setTimeout(() => {
        if (pinBuf === S.pin) { closeModal('pinModal'); pinCb && pinCb(); } else { toast('الرمز غير صحيح'); pinBuf = ''; drawPin(); }
      }, 150);
    }));
    $('pinModal').classList.add('on');
  }
  function drawPin() { $('pinDots').innerHTML = [0, 1, 2, 3].map((i) => `<span>${i < pinBuf.length ? '●' : ''}</span>`).join(''); }
  function changePin() {
    const p = $('newPin').value.replace(/\D/g, '');
    if (p.length !== 4) return toast('الرمز لازم يكون ٤ أرقام');
    S.pin = p; save(); $('newPin').value = ''; toast('تم تغيير الرمز ✓');
  }

  /* ---------- الإعدادات ---------- */
  function openSettings() { show('settings'); }
  function renderSettings() {
    renderKidList($('setKids'), true);
    $('allStories').innerHTML = STORIES.map((s) => `<div class="li"><span class="nm">${esc(s.title.replace(/\{n\}/g, '…'))}<br><span class="tag">${esc(s.value)}</span></span><button class="small" onclick="App.preview('${s.id}')">معاينة</button></div>`).join('');
    $('backupCode').value = backupCode();
    $('ver2').textContent = VERSION;
  }
  function preview(id) { if (!heroes().length && S.kids.length) sel = [S.kids[0].id]; openStory(id); }

  /* ---------- النسخة الاحتياطية ---------- */
  function backupCode() {
    const data = { k: S.kids.map((k) => [k.name, k.g, k.age, k.av.skin, k.av.hair, k.av.shirt, k.av.hijab ? 1 : 0]), f: S.fav, r: S.read };
    const b64 = btoa(unescape(encodeURIComponent(JSON.stringify(data)))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    return 'SIRAJ1-' + b64;
  }
  async function copyBackup() {
    const code = backupCode();
    try {
      if (navigator.share) await navigator.share({ title: 'نسخة سِراج الاحتياطية', text: code });
      else { await navigator.clipboard.writeText(code); toast('تم نسخ الرمز ✓'); }
    } catch (e) { $('backupCode').select(); }
  }
  function openRestore() { $('restoreCode').value = ''; $('restoreModal').classList.add('on'); }
  function doRestore() {
    try {
      let c = $('restoreCode').value.trim();
      if (!c.startsWith('SIRAJ1-')) throw 0;
      c = c.slice(7).replace(/-/g, '+').replace(/_/g, '/');
      const d = JSON.parse(decodeURIComponent(escape(atob(c))));
      S.kids = d.k.map((a) => ({ id: uid(), name: a[0], g: a[1], age: a[2], av: { skin: a[3], hair: a[4], shirt: a[5], hijab: a[6] } }));
      S.fav = d.f || []; S.read = d.r || {}; S.sel = [];
      save(); closeModal('restoreModal'); toast('تم الاسترجاع ✓');
      if (S.pin) show('home'); else { show('setup'); renderKidList($('setupKids'), false); toast('اختر رمز وليّ الأمر'); }
    } catch (e) { toast('الرمز غير صحيح'); }
  }

  /* ---------- البداية ---------- */
  function start() {
    if (!S.kids.length || !S.pin) { show('setup'); renderKidList($('setupKids'), false); }
    else show('home');
  }
  function init() {
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault(); installEvt = e;
      $('installBtn').style.display = 'block';
      $('installBtn').onclick = async () => { installEvt.prompt(); await installEvt.userChoice; installEvt = null; };
    });
    if ('speechSynthesis' in window) speechSynthesis.onvoiceschanged = () => {};
    let skipped = false; try { skipped = sessionStorage.getItem('siraj-skip') === '1'; } catch (e) {}
    if (!standalone() && !skipped) { renderWelcome(); show('welcome'); } else start();
    if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
  }

  return { init, show, skipWelcome, finishSetup, editKid, saveKid, delKid, closeModal, pick, tab, openStory, step, closeReader, toggleFav, toggleVoice, askPin, openSettings, changePin, preview, copyBackup, openRestore, doRestore, fill, storyOfDay };
})();

App.init();

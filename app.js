/* سِراج | SIRAJ — منطق التطبيق */
const KEY = 'siraj';
const DAD = ['بابا', 'يبه', 'أبوي', 'بابي'];
const MOM = ['ماما', 'يمه', 'أمي', 'مامي'];

const App = (() => {
  const $ = (id) => document.getElementById(id);
  let S = load();
  let sel = [];               // أبطال الليلة (أول واحد = البطل)
  let R = null;               // حالة القارئ
  let editing = null;         // الطفل اللي نعدّله
  let pinBuf = '', pinCb = null;
  let installEvt = null, pendingReload = false, remote = [], sleepTimer = null;

  /* ---------- التخزين ---------- */
  function freshFam() { return { kids: [], pin: '', dad: 'بابا', mom: 'ماما', bedtime: '20:30', remind: true }; }
  function fresh() { return { v: 2, role: '', code: '', dev: uid(), rev: 0, dirty: false, progDirty: false, fam: freshFam(), log: [], fav: [], voice: false, sel: [], notif: false }; }
  function load() {
    let s; try { s = JSON.parse(localStorage.getItem(KEY)); } catch (e) {}
    if (!s) return fresh();
    if (!s.v || s.v === 1) {               // ترحيل من النسخة 1.0
      const n = fresh();
      n.fam.kids = s.kids || []; n.fam.pin = s.pin || ''; n.fav = s.fav || []; n.voice = !!s.voice; n.sel = s.sel || [];
      n.log = Object.entries(s.read || {}).map(([sid, d]) => ({ s: sid, d, k: [], t: Date.parse(d) || Date.now() }));
      n.role = n.fam.kids.length ? 'parent' : '';
      return n;
    }
    s.fam = Object.assign(freshFam(), s.fam || {});
    return s;
  }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} writeSWData(); }
  function famChanged() { S.dirty = true; save(); syncNow(); }

  /* بيانات صغيرة يقراها sw.js لكتابة نص الإشعار (الأسماء ما تطلع للسيرفر) */
  function writeSWData() {
    if (!('caches' in window)) return;
    const kids = {}; S.fam.kids.forEach((k) => (kids[k.id] = { n: k.name, g: k.g }));
    caches.open('siraj-data').then((c) => c.put(location.origin + '/__family', new Response(JSON.stringify({ kids, sel: S.sel })))).catch(() => {});
  }

  /* ---------- أدوات ---------- */
  function uid() { return Math.random().toString(36).slice(2, 10); }
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  function toast(msg) { const t = $('toast'); t.textContent = msg; t.classList.add('on'); clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.remove('on'), 2600); }
  function dateKey(d = new Date()) { return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
  function dayOfYear(d = new Date()) { return Math.floor((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 0)) / 864e5); }
  function hash(str) { let h = 2166136261; for (const c of str) { h ^= c.codePointAt(0); h = Math.imul(h, 16777619); } return h >>> 0; }
  function rng(seed) { return () => { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
  const kidById = (id) => S.fam.kids.find((k) => k.id === id);
  const names = (arr) => arr.map((k) => k.name).join(' و');
  const standalone = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone;
  const isIOS = () => /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const joinLink = () => CONFIG.SITE + '/#join=' + S.code;

  /* ---------- قصة اليوم: مربوطة بالتاريخ والعائلة، والمناسبات تتقدّم ---------- */
  function hijri(d) {
    try {
      const p = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura-nu-latn', { month: 'numeric', day: 'numeric' }).formatToParts(d);
      return { m: +p.find((x) => x.type === 'month').value, d: +p.find((x) => x.type === 'day').value };
    } catch (e) { return null; }
  }
  function occasion(d) {
    const h = hijri(d);
    return STORIES.find((s) => s.occ && ((s.occ.cal === 'g' && s.occ.m === d.getMonth() + 1 && s.occ.d.includes(d.getDate())) ||
      (s.occ.cal === 'h' && h && s.occ.m === h.m && s.occ.d.includes(h.d))));
  }
  function storyOfDay(d = new Date()) {
    const occ = occasion(d); if (occ) return occ;
    const pool = STORIES.filter((s) => !s.occ);
    const seed = S.code || S.fam.kids.map((k) => k.name.trim()).sort().join('|');
    const order = pool.map((_, i) => i);
    const r = rng(hash(seed + '#' + d.getFullYear()));
    for (let i = order.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [order[i], order[j]] = [order[j], order[i]]; }
    return pool[order[(dayOfYear(d) - 1) % order.length]];
  }

  /* ---------- محرّك القوالب ---------- */
  function fill(str, heroes) {
    const [hero, ...rest] = heroes;
    const g = hero.g === 'f' ? 1 : 0;
    const cg = rest.length > 1 ? 2 : rest.length === 1 ? (rest[0].g === 'f' ? 1 : 0) : 0;
    let s = str.replace(/\[\[([\s\S]*?)\]\]/g, (_, inner) => (rest.length ? inner : ''));
    s = s.replace(/\{\{([^{}]*)\}\}/g, (_, x) => { const o = x.split('|'); return o[cg] ?? o[o.length - 1]; });
    s = s.replace(/\{([^{}|]*)\|([^{}|]*)\}/g, (_, a, b) => (g ? b : a));
    return s.replace(/\{n\}/g, hero.name).replace(/\{fr\}/g, names(rest))
      .replace(/\{dad\}/g, S.fam.dad || 'بابا').replace(/\{mom\}/g, S.fam.mom || 'ماما');
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
  function renderWelcome() {
    $('installSteps').innerHTML = isIOS()
      ? '<b>أضفه للشاشة الرئيسية ليعمل كتطبيق:</b><br>١. اضغط زر المشاركة <b>⬆️</b><br>٢. اختر <b>«إضافة إلى الشاشة الرئيسية»</b><br>٣. افتح سِراج من أيقونته 🌙'
      : '<b>أضفه للشاشة الرئيسية ليعمل كتطبيق:</b><br>١. اضغط قائمة المتصفح <b>⋮</b><br>٢. اختر <b>«تثبيت التطبيق»</b> أو «إضافة إلى الشاشة الرئيسية»<br>٣. افتح سِراج من أيقونته 🌙';
  }
  function skipWelcome() { try { sessionStorage.setItem('siraj-skip', '1'); } catch (e) {} start(); }

  /* ---------- البداية: وليّ أمر أو جهاز طفل ---------- */
  function start() {
    let pj = ''; try { pj = localStorage.getItem('siraj-join') || ''; } catch (e) {}
    if (pj && !S.code) { openJoin('child', pj); return; }
    if (!S.role) return show('role');
    if (S.role === 'parent' && (!S.fam.kids.length || !S.fam.pin)) return openSetup();
    show('home');
  }
  function openSetup() {
    S.role = 'parent'; save();
    renderKidList($('setupKids'), false);
    buildCallChips('setupDad', 'dad', DAD); buildCallChips('setupMom', 'mom', MOM);
    $('setupPin').value = S.fam.pin || ''; $('setupBed').value = S.fam.bedtime || '20:30';
    show('setup');
  }
  function buildCallChips(id, key, opts) {
    const el = $(id), cur = S.fam[key];
    const custom = !opts.includes(cur);
    el.innerHTML = opts.map((o) => `<button class="chip ${o === cur ? 'on' : ''}" data-v="${o}">${o}</button>`).join('') +
      `<input class="chipin ${custom ? 'on' : ''}" maxlength="12" placeholder="غير ذلك" value="${custom ? esc(cur) : ''}">`;
    el.querySelectorAll('.chip').forEach((b) => (b.onclick = () => { S.fam[key] = b.dataset.v; save(); buildCallChips(id, key, opts); if (S.code) S.dirty = true; }));
    el.querySelector('.chipin').oninput = (e) => { const v = e.target.value.trim(); if (v) { S.fam[key] = v; save(); if (S.code) S.dirty = true; el.querySelectorAll('.chip').forEach((b) => b.classList.remove('on')); } };
  }
  async function finishSetup() {
    const pin = $('setupPin').value.replace(/\D/g, '');
    if (!S.fam.kids.length) return toast('أضف طفلًا واحدًا على الأقل');
    if (pin.length !== 4) return toast('الرمز لازم يكون ٤ أرقام');
    S.fam.pin = pin; S.fam.bedtime = $('setupBed').value || '20:30';
    if (!S.code) S.code = Sync.newCode();
    S.dirty = true; save();
    show('home');
    await syncNow();
    showFamilyCode(true);
    askNotif();
  }

  /* ---------- ربط جهاز (طفل، أو استرجاع جهاز وليّ الأمر) ---------- */
  function openJoin(role, code) {
    $('joinRole').value = role;
    $('joinTitle').textContent = role === 'child' ? 'ربط جهاز الطفل 🧒' : 'استرجاع العائلة 🔑';
    $('joinHint').textContent = role === 'child'
      ? 'أدخل رمز العائلة اللي يظهر في جوال وليّ الأمر (الإعدادات ← العائلة)، أو افتح رابط الربط اللي أرسله لك.'
      : 'أدخل رمز عائلتك، ويرجع كل شيء: الأطفال والإعدادات وتقدّم القراءة.';
    $('joinCode').value = code || '';
    show('join');
  }
  async function doJoin() {
    const code = Sync.norm($('joinCode').value);
    if (!code) return toast('الرمز ١٠ حروف وأرقام، مثل K7QPM-4XR2D');
    if (!Sync.online()) return toast('الربط يحتاج إنترنت');
    $('joinBtn').disabled = true; $('joinBtn').textContent = 'جاري الربط…';
    try {
      const r = await Sync.pullFamily(code);
      if (!r) { toast('ما لقينا عائلة بهذا الرمز'); return; }
      const role = $('joinRole').value;
      S.code = code; S.fam = Object.assign(freshFam(), r.fam); S.rev = r.rev; S.dirty = false; S.role = role; S.sel = [];
      try { localStorage.removeItem('siraj-join'); } catch (e) {}
      remote = await Sync.pullProgress(code).catch(() => []);
      if (role === 'parent') { const mine = remote.filter((x) => x.dev !== S.dev); mine.forEach((p) => (S.fav = [...new Set([...S.fav, ...(p.fav || [])])])); }
      save(); toast(role === 'child' ? 'تم ربط الجهاز بالعائلة ✓' : 'تم استرجاع العائلة ✓');
      show('home'); askNotif();
    } catch (e) { toast('تعذّر الربط، تأكد من الإنترنت'); }
    finally { $('joinBtn').disabled = false; $('joinBtn').textContent = 'ربط'; }
  }

  /* ---------- المزامنة ---------- */
  let syncing = false;
  async function syncNow() {
    if (!S.code || !Sync.online() || syncing) return;
    syncing = true;
    try {
      const r = await Sync.pullFamily(S.code);
      let changed = false;
      if (S.dirty) {
        const rev = Math.max(S.rev, r ? r.rev : 0) + 1;
        const res = await Sync.pushFamily(S.code, S.fam, rev);
        if (res.ok) { S.rev = rev; S.dirty = false; }
      } else if (r && r.rev > S.rev) {
        S.fam = Object.assign(freshFam(), r.fam); S.rev = r.rev; changed = true;
      }
      if (S.progDirty) {
        await Sync.pushProgress(S.code, S.dev, { role: S.role, log: S.log.slice(-500), fav: S.fav });
        S.progDirty = false;
      }
      save();
      registerSub();
      if (changed && $('home').classList.contains('on')) renderHome();
    } catch (e) {}
    syncing = false;
  }
  async function loadRemote() {
    if (!S.code || !Sync.online()) return remote;
    try { remote = await Sync.pullProgress(S.code); } catch (e) {}
    return remote;
  }
  function allLogs() {
    const seen = new Set(), out = [];
    const add = (e, dev, role) => { const key = e.t + e.s; if (seen.has(key)) return; seen.add(key); out.push({ ...e, dev, role }); };
    S.log.forEach((e) => add(e, S.dev, S.role));
    remote.filter((p) => p.dev !== S.dev).forEach((p) => (p.log || []).forEach((e) => add(e, p.dev, p.role)));
    return out.sort((a, b) => b.t - a.t);
  }

  /* ---------- الأطفال ---------- */
  function renderKidList(el, withDelete) {
    el.innerHTML = S.fam.kids.length ? S.fam.kids.map((k) => `
      <div class="li">${ART.avatarSVG(k.av, k.g, 44)}<span class="nm">${esc(k.name)}</span>
      <button class="small" onclick="App.editKid('${k.id}')">تعديل</button>${withDelete ? `<button class="small del" onclick="App.delKid('${k.id}')">حذف</button>` : ''}
      </div>`).join('') : '<p class="muted" style="text-align:center">لا يوجد أطفال بعد</p>';
  }
  function editKid(id) {
    const k = kidById(id);
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
    const sw = (id, arr, key) => { $(id).innerHTML = arr.map((c, i) => `<button class="sw ${e.av[key] === i ? 'on' : ''}" style="background:${c}" data-i="${i}" aria-label="لون"></button>`).join(''); $(id).querySelectorAll('.sw').forEach((b) => (b.onclick = () => { e.av[key] = +b.dataset.i; buildKidForm(); })); };
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
    const i = S.fam.kids.findIndex((x) => x.id === editing.id);
    if (i >= 0) S.fam.kids[i] = editing; else S.fam.kids.push(editing);
    closeModal('kidModal');
    if (S.code) famChanged(); else save();
    renderKidList($('setupKids'), false);
    if ($('settings').classList.contains('on')) renderSettings();
  }
  function delKid(id) {
    const k = kidById(id);
    if (!k || !confirm('حذف ' + k.name + '؟')) return;
    S.fam.kids = S.fam.kids.filter((x) => x.id !== id); S.sel = (S.sel || []).filter((x) => x !== id);
    famChanged(); renderSettings();
  }
  function closeModal(id) { $(id).classList.remove('on'); }

  /* ---------- الرئيسية ---------- */
  function heroes() { return sel.map(kidById).filter(Boolean); }
  function renderHome() {
    sel = (S.sel || []).filter((id) => kidById(id));
    if (!sel.length && S.fam.kids.length) sel = [S.fam.kids[0].id];
    const h = new Date().getHours();
    $('hello').textContent = (h >= 17 || h < 4 ? 'مساء الخير' : 'أهلًا') + '، جاهزين لحكاية الليلة؟ 🌙';
    $('kids').innerHTML = S.fam.kids.map((k) => {
      const i = sel.indexOf(k.id);
      return `<button class="kid ${i >= 0 ? 'sel' : ''} ${i === 0 ? 'hero' : ''}" onclick="App.pick('${k.id}')"><span class="badge">البطل ⭐</span>${ART.avatarSVG(k.av, k.g, 78)}<div class="nm">${esc(k.name)}</div></button>`;
    }).join('');
    const st = storyOfDay(), hs = heroes();
    const done = allLogs().some((e) => e.s === st.id && e.d === dateKey());
    $('tonightCard').innerHTML = hs.length ? `${ART.page(st.scene, st.occ ? '🎉' : '✨', hs)}
      <div class="info">${st.occ ? '<span class="tag" style="background:#E5FBEA;color:#1E8E4A">قصة المناسبة 🎉</span> ' : ''}<p class="title">${esc(fill(st.title, hs))}</p><span class="tag">${esc(st.value)}</span>
      <button class="btn" style="margin-top:14px" onclick="App.openStory('${st.id}')">${done ? 'اقرأها مرة ثانية 🔁' : 'ابدأ قصة الليلة ✨'}</button></div>`
      : '<div class="info"><p class="muted">اختر بطلًا واحدًا على الأقل</p></div>';
    $('ver').textContent = 'v' + CONFIG.VERSION;
    $('tabDash').style.display = S.role === 'parent' ? '' : 'none';
    renderLib();
  }
  function pick(id) {
    const i = sel.indexOf(id);
    if (i >= 0) sel.splice(i, 1); else sel.push(id);
    S.sel = sel.slice(); save(); renderHome();
  }
  function tab(t) {
    ['tonight', 'lib', 'dash'].forEach((x) => {
      $('tab' + x[0].toUpperCase() + x.slice(1)).classList.toggle('on', x === t);
      $('pane' + x[0].toUpperCase() + x.slice(1)).style.display = x === t ? '' : 'none';
    });
    if (t === 'dash') renderDash();
  }
  function renderLib() {
    const hs = heroes().length ? heroes() : S.fam.kids.slice(0, 1);
    const seen = new Set(), items = [];
    S.fav.forEach((id) => { if (!seen.has(id)) { seen.add(id); items.push(id); } });
    allLogs().forEach((e) => { if (!seen.has(e.s)) { seen.add(e.s); items.push(e.s); } });
    const list = items.map((id) => STORIES.find((s) => s.id === id)).filter(Boolean);
    $('lib').innerHTML = list.length && hs.length ? list.map((s) => `<button class="item" onclick="App.openStory('${s.id}')">${ART.page(s.scene, S.fav.includes(s.id) ? '⭐' : '', hs)}<div>${esc(fill(s.title, hs))}</div></button>`).join('')
      : '<p class="empty" style="grid-column:1/-1">القصص اللي تقرونها تنحفظ هنا، وتقدرون ترجعون لها متى ما حبيتوا 📚</p>';
  }

  /* ---------- لوحة المتابعة ---------- */
  function streak(days) {
    let n = 0, d = new Date();
    if (!days.has(dateKey(d))) d.setDate(d.getDate() - 1);
    while (days.has(dateKey(d))) { n++; d.setDate(d.getDate() - 1); }
    return n;
  }
  function ago(t) {
    const m = Math.round((Date.now() - t) / 60000);
    if (m < 2) return 'الآن'; if (m < 60) return 'قبل ' + m + ' دقيقة';
    const h = Math.round(m / 60); if (h < 24) return 'قبل ' + h + ' ساعة';
    const d = Math.round(h / 24); return d === 1 ? 'أمس' : 'قبل ' + d + ' أيام';
  }
  async function renderDash() {
    const el = $('dash');
    const draw = () => {
      const logs = allLogs();
      const week = [...Array(7)].map((_, i) => { const d = new Date(); d.setDate(d.getDate() - (6 - i)); return dateKey(d); });
      const dayNames = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
      const cards = S.fam.kids.map((k) => {
        const mine = logs.filter((e) => (e.k || []).includes(k.id));
        const days = new Set(mine.map((e) => e.d));
        const last = mine[0];
        const lastSt = last && STORIES.find((s) => s.id === last.s);
        return `<div class="card dk">
          <div class="row" style="align-items:center;gap:12px;flex:none">${ART.avatarSVG(k.av, k.g, 54)}<div style="flex:1"><h2 style="margin:0">${esc(k.name)}</h2>
          <span class="muted" style="margin:0">${last ? 'آخر قصة ' + ago(last.t) : 'ما قرأ{|ت} بعد'.replace('{|ت}', k.g === 'f' ? 'ت' : '')}</span></div></div>
          <div class="stats"><div><b>${new Set(mine.map((e) => e.s)).size}</b><span>قصة</span></div><div><b>${streak(days)} 🔥</b><span>أيام متتالية</span></div><div><b>${mine.length}</b><span>مرة قراءة</span></div></div>
          <div class="week">${week.map((d) => `<i class="${days.has(d) ? 'on' : ''}" title="${d}">${dayNames[new Date(d + 'T12:00').getDay()]}</i>`).join('')}</div>
          ${lastSt ? `<p class="muted" style="margin:8px 0 0">آخر قصة: «${esc(fill(lastSt.title, [k]))}»</p>` : ''}
        </div>`;
      }).join('');
      const recent = logs.slice(0, 12).map((e) => {
        const st = STORIES.find((s) => s.id === e.s); const ks = (e.k || []).map(kidById).filter(Boolean);
        if (!st) return '';
        const who = ks.length ? names(ks) : '—';
        const t = new Date(e.t);
        return `<div class="li"><span class="nm" style="font-size:16px">${esc(ks.length ? fill(st.title, ks) : st.title.replace(/\{n\}/g, '…'))}<br><span class="muted" style="font-size:13px">${esc(who)} · ${t.toLocaleDateString('ar-SA-u-nu-latn', { weekday: 'long', day: 'numeric', month: 'short' })} ${t.toLocaleTimeString('ar-SA-u-nu-latn', { hour: 'numeric', minute: '2-digit' })} · ${e.role === 'child' ? 'جهاز الطفل' : 'جوال وليّ الأمر'}</span></span></div>`;
      }).join('');
      el.innerHTML = (S.code ? '' : '<div class="card"><p class="muted">اربط جهاز الطفل بعائلتك عشان تشوف قراءته هنا.</p></div>') + cards +
        `<div class="card"><h2>آخر النشاط</h2><div class="list">${recent || '<p class="muted">ما فيه نشاط بعد</p>'}</div></div>`;
    };
    draw();
    await loadRemote(); draw();
  }

  /* ---------- القارئ ---------- */
  function openStory(id) {
    const hs = heroes();
    if (!hs.length) return toast('اختر بطل القصة أولًا');
    const st = STORIES.find((s) => s.id === id);
    R = { st, hs, i: 0, total: st.pages.length + 2, logged: false };
    show('reader'); renderPage();
  }
  function renderPage() {
    const { st, hs, i, total } = R;
    clearTimeout(sleepTimer); $('sleep').classList.remove('on');
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
      logStory();
    } else {
      const n = names(hs), one = hs.length === 1, f = one && hs[0].g === 'f';
      html = `<div class="goodnight"><div class="moon">🌙</div><h1>${one ? (f ? 'تصبحين على خير' : 'تصبح على خير') : 'تصبحون على خير'}</h1>
        <p class="ptext">نومًا هنيئًا يا ${esc(n)} ✨<br>وموعدنا مع حكايةٍ جديدة غدًا</p><p class="muted" style="color:#ffffff88">الشاشة بتخفت لحالها… 😴</p></div>`;
      say = (one ? (f ? 'تصبحين على خير يا ' : 'تصبح على خير يا ') : 'تصبحون على خير يا ') + n + '. نومًا هنيئًا.';
      nav = '<button class="btn alt" onclick="App.closeReader()">إغلاق</button>';
      sleepTimer = setTimeout(() => $('sleep').classList.add('on'), 6000);
    }
    $('stage').innerHTML = html; $('nav').innerHTML = nav;
    speak(say);
  }
  function logStory() {
    if (R.logged) return; R.logged = true;
    const e = { s: R.st.id, d: dateKey(), k: R.hs.map((k) => k.id), t: Date.now() };
    S.log.push(e); if (S.log.length > 1500) S.log = S.log.slice(-1500);
    S.progDirty = true; save();
    if (S.code && Sync.online()) { syncNow(); Sync.event(S.code, S.dev, e.k, e.s).catch(() => {}); }
  }
  function step(d) { R.i = Math.max(0, Math.min(R.total - 1, R.i + d)); window.scrollTo(0, 0); renderPage(); }
  function closeReader() {
    stopSpeak(); clearTimeout(sleepTimer); $('sleep').classList.remove('on'); R = null;
    if (pendingReload) { try { sessionStorage.setItem('siraj-updated', '1'); } catch (e) {} location.reload(); return; }
    show('home');
  }
  function wake() { $('sleep').classList.remove('on'); }
  function toggleFav() {
    const id = R.st.id, i = S.fav.indexOf(id);
    if (i >= 0) S.fav.splice(i, 1); else { S.fav.push(id); toast('أضيفت للمفضلة ⭐'); }
    S.progDirty = true; save(); $('favBtn').textContent = S.fav.includes(id) ? '⭐' : '☆';
  }

  /* ---------- القراءة بالصوت (أصوات الجهاز نفسه) ---------- */
  function arVoice() {
    if (!('speechSynthesis' in window)) return null;
    const v = speechSynthesis.getVoices();
    return v.find((x) => /^ar[-_]SA/i.test(x.lang)) || v.find((x) => /^ar/i.test(x.lang));
  }
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
    if (S.voice) { if (!arVoice() && 'speechSynthesis' in window) toast('ما فيه صوت عربي على هذا الجهاز، نزّله من إعدادات تحويل النص إلى كلام'); renderPage(); } else stopSpeak();
  }

  /* ---------- رمز وليّ الأمر ---------- */
  function askPin(cb) {
    pinBuf = ''; pinCb = cb; drawPin();
    $('pinPad').innerHTML = [1, 2, 3, 4, 5, 6, 7, 8, 9, '⌫', 0, ''].map((x) => `<button data-k="${x}" ${x === '' ? 'style="visibility:hidden"' : ''}>${x}</button>`).join('');
    $('pinPad').querySelectorAll('button').forEach((b) => (b.onclick = () => {
      const k = b.dataset.k;
      if (k === '⌫') pinBuf = pinBuf.slice(0, -1); else if (k !== '' && pinBuf.length < 4) pinBuf += k;
      drawPin();
      if (pinBuf.length === 4) setTimeout(() => {
        if (pinBuf === S.fam.pin) { closeModal('pinModal'); pinCb && pinCb(); } else { toast('الرمز غير صحيح'); pinBuf = ''; drawPin(); }
      }, 150);
    }));
    $('pinModal').classList.add('on');
  }
  function drawPin() { $('pinDots').innerHTML = [0, 1, 2, 3].map((i) => `<span>${i < pinBuf.length ? '●' : ''}</span>`).join(''); }
  function changePin() {
    const p = $('newPin').value.replace(/\D/g, '');
    if (p.length !== 4) return toast('الرمز لازم يكون ٤ أرقام');
    S.fam.pin = p; $('newPin').value = ''; famChanged(); toast('تم تغيير الرمز ✓');
  }

  /* ---------- الإعدادات ---------- */
  function openSettings() { show('settings'); }
  function renderSettings() {
    $('famCode').textContent = S.code || '—';
    $('devRole').textContent = S.role === 'child' ? 'جهاز طفل 🧒' : 'جوال وليّ الأمر 👨‍👩‍👧';
    $('famBox').style.display = S.code ? '' : 'none';
    renderQR();
    renderKidList($('setKids'), true);
    buildCallChips('setDad', 'dad', DAD); buildCallChips('setMom', 'mom', MOM);
    $('bedTime').value = S.fam.bedtime || '20:30';
    $('remindOn').checked = !!S.fam.remind;
    $('notifState').textContent = !CONFIG.VAPID ? 'الإشعارات تحتاج إعداد السيرفر أولًا'
      : S.notif && typeof Notification !== 'undefined' && Notification.permission === 'granted' ? 'مفعّلة على هذا الجهاز ✓' : 'غير مفعّلة على هذا الجهاز';
    $('notifBtn').style.display = !CONFIG.VAPID || (S.notif && typeof Notification !== 'undefined' && Notification.permission === 'granted') ? 'none' : '';
    $('remindNote').textContent = S.role === 'child' ? 'التذكير يوصل لهذا الجهاز في الوقت المحدد.' : 'التذكير يوصل لأجهزة الأطفال المربوطة، وأنت يوصلك إشعار لما يخلصون القصة.';
    $('storyCount').textContent = STORIES.length;
    filterStories();
    $('ver2').textContent = CONFIG.VERSION;
  }
  function filterStories() {
    const q = ($('storySearch').value || '').trim();
    const list = STORIES.filter((s) => !q || s.title.includes(q) || s.value.includes(q)).slice(0, 25);
    $('allStories').innerHTML = list.map((s) => `<div class="li"><span class="nm">${esc(s.title.replace(/\{n\}/g, '…'))}<br><span class="tag">${esc(s.value)}</span>${s.occ ? ' <span class="tag" style="background:#E5FBEA;color:#1E8E4A">مناسبة</span>' : ''}</span><button class="small" onclick="App.preview('${s.id}')">معاينة</button></div>`).join('')
      || '<p class="muted">ما لقينا قصة بهذا الاسم</p>';
  }
  function preview(id) { if (!heroes().length && S.fam.kids.length) sel = [S.fam.kids[0].id]; openStory(id); }
  function setBed() {
    S.fam.bedtime = $('bedTime').value || '20:30'; S.fam.remind = $('remindOn').checked;
    famChanged(); toast('تم الحفظ ✓');
  }
  function renderQR() {
    const box = $('qr'); if (!S.code) { box.innerHTML = ''; return; }
    const draw = () => { try { const q = qrcode(0, 'M'); q.addData(joinLink()); q.make(); box.innerHTML = q.createSvgTag({ cellSize: 5, margin: 2, scalable: true }); } catch (e) { box.innerHTML = ''; } };
    if (window.qrcode) return draw();
    const s = document.createElement('script');
    s.src = 'https://cdnjs.cloudflare.com/ajax/libs/qrcode-generator/1.4.4/qrcode.min.js'; s.onload = draw; s.onerror = () => (box.innerHTML = '');
    document.head.appendChild(s);
  }
  function showFamilyCode(first) {
    $('fcCode').textContent = S.code;
    $('fcFirst').style.display = first ? '' : 'none';
    $('codeModal').classList.add('on');
  }
  async function shareJoin() {
    const text = 'اربط جهاز الأطفال بعائلتنا في سِراج 🌙\nرمز العائلة: ' + S.code + '\n' + joinLink();
    try { if (navigator.share) await navigator.share({ title: 'ربط سِراج', text }); else { await navigator.clipboard.writeText(text); toast('تم النسخ ✓'); } } catch (e) {}
  }
  async function copyCode() { try { await navigator.clipboard.writeText(S.code); toast('تم نسخ الرمز ✓'); } catch (e) { toast(S.code); } }
  async function shareApp() {
    const text = 'سِراج 🌙 قصص ما قبل النوم، أبطالها أطفالك. قصص هادفة بأسمائهم وبالصور، وتشتغل بدون إنترنت.';
    try { if (navigator.share) await navigator.share({ title: 'سِراج | SIRAJ', text, url: CONFIG.SITE }); else { await navigator.clipboard.writeText(text + '\n' + CONFIG.SITE); toast('تم نسخ الرابط ✓'); } } catch (e) {}
  }
  function unlink() {
    if (!confirm('فك ربط هذا الجهاز ومسح بياناته منه؟ (بيانات العائلة تبقى محفوظة في الرمز)')) return;
    disableNotif(true);
    try { localStorage.removeItem(KEY); } catch (e) {}
    S = fresh(); save(); location.reload();
  }

  /* ---------- الإشعارات ---------- */
  function vapidKey() { const s = CONFIG.VAPID.replace(/-/g, '+').replace(/_/g, '/'); const r = atob(s + '==='.slice((s.length + 3) % 4)); return Uint8Array.from(r, (c) => c.charCodeAt(0)); }
  function askNotif() {
    if (!CONFIG.VAPID || S.notif || !('Notification' in window) || Notification.permission === 'denied') return;
    setTimeout(() => $('notifModal').classList.add('on'), 600);
  }
  async function enableNotif() {
    closeModal('notifModal');
    if (!CONFIG.VAPID) return toast('الإشعارات تحتاج إعداد السيرفر أولًا');
    if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window))
      return toast(isIOS() && !standalone() ? 'أضف سِراج للشاشة الرئيسية أولًا، ثم فعّل الإشعارات' : 'هذا الجهاز لا يدعم الإشعارات');
    try {
      const p = await Notification.requestPermission();
      if (p !== 'granted') return toast('لم يتم السماح بالإشعارات');
      const reg = await navigator.serviceWorker.ready;
      const sub = (await reg.pushManager.getSubscription()) || (await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: vapidKey() }));
      S.notif = true; save();
      await Sync.sub(S.code, S.dev, S.role, S.fam.remind ? S.fam.bedtime : '', sub);
      toast('تم تفعيل الإشعارات ✓');
      if ($('settings').classList.contains('on')) renderSettings();
    } catch (e) { toast('تعذّر تفعيل الإشعارات'); }
  }
  async function registerSub() {
    if (!S.notif || !CONFIG.VAPID || !('serviceWorker' in navigator)) return;
    try {
      const reg = await navigator.serviceWorker.ready; const sub = await reg.pushManager.getSubscription();
      if (sub) await Sync.sub(S.code, S.dev, S.role, S.fam.remind ? S.fam.bedtime : '', sub);
    } catch (e) {}
  }
  async function disableNotif(silent) {
    try { const reg = await navigator.serviceWorker.ready; const sub = await reg.pushManager.getSubscription(); if (sub) { await Sync.sub(S.code, S.dev, S.role, '', sub, true).catch(() => {}); await sub.unsubscribe(); } } catch (e) {}
    S.notif = false; save(); if (!silent) { toast('تم إيقاف الإشعارات'); renderSettings(); }
  }

  /* ---------- التحديث التلقائي ---------- */
  function setupSW() {
    if (!('serviceWorker' in navigator)) return;
    const had = !!navigator.serviceWorker.controller;
    navigator.serviceWorker.register('sw.js', { updateViaCache: 'none' }).then((reg) => {
      const check = () => { if (reg && reg.update && navigator.onLine !== false) reg.update().catch(() => {}); };
      setInterval(check, 30 * 60000);
      document.addEventListener('visibilitychange', () => { if (!document.hidden) { check(); syncNow(); } });
      addEventListener('online', () => { check(); syncNow(); });
    }).catch(() => {});
    let refreshing = false;
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (!had || refreshing) return;
      if (R) { pendingReload = true; return; }          // لا نقاطع قصة شغالة
      refreshing = true;
      try { sessionStorage.setItem('siraj-updated', '1'); } catch (e) {}
      location.reload();
    });
  }

  /* ---------- البدء ---------- */
  function init() {
    const m = location.hash.match(/join=([A-Za-z0-9-]{10,12})/);
    if (m) { const c = Sync.norm(m[1]); if (c && c !== S.code) { try { localStorage.setItem('siraj-join', c); } catch (e) {} } history.replaceState(null, '', location.pathname); }
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault(); installEvt = e;
      $('installBtn').style.display = 'block';
      $('installBtn').onclick = async () => { installEvt.prompt(); await installEvt.userChoice; installEvt = null; };
    });
    if ('speechSynthesis' in window) speechSynthesis.onvoiceschanged = () => {};
    let skipped = false, updated = false;
    try { skipped = sessionStorage.getItem('siraj-skip') === '1'; updated = sessionStorage.getItem('siraj-updated') === '1'; sessionStorage.removeItem('siraj-updated'); } catch (e) {}
    if (!standalone() && !skipped && !S.role) { renderWelcome(); show('welcome'); } else start();
    if (updated) setTimeout(() => toast('تم التحديث ✨ الإصدار ' + CONFIG.VERSION), 500);
    setupSW(); save(); syncNow();
  }

  return {
    init, show, skipWelcome, openSetup, finishSetup, openJoin, doJoin, editKid, saveKid, delKid, closeModal, pick, tab,
    openStory, step, closeReader, wake, toggleFav, toggleVoice, askPin, openSettings, changePin, preview, filterStories, setBed,
    showFamilyCode, shareJoin, copyCode, shareApp, unlink, enableNotif, disableNotif, fill, storyOfDay, _state: () => S
  };
})();

App.init();

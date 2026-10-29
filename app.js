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
  function freshFam() { return { kids: [], pin: '', dad: 'بابا', mom: 'ماما', bedtime: '20:30', remind: true, perNight: 1, lockOn: true, lock: '21:30', extra: null }; }
  function fresh() { return { v: 2, role: '', code: '', dev: uid(), rev: 0, dirty: false, progDirty: false, fam: freshFam(), log: [], fav: [], voice: true, voiceV: 1, sel: [], notif: false, devKids: [], beat: 0, act: [], unlockUntil: 0 }; }
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
    if (!s.voiceV) { s.voice = true; s.voiceV = 1; } // من 1.8: السماعة شغالة افتراضيًا
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
    $('setupPin').value = S.fam.pin || ''; setTime('setupBed', S.fam.bedtime || '20:30');
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
      S.devKids = []; S.progDirty = true;
      save(); toast(role === 'child' ? 'تم ربط الجهاز بالعائلة ✓' : 'تم استرجاع العائلة ✓');
      show('home');
      if (role === 'child' && S.fam.kids.length > 1) openWho(true);
      else { if (role === 'child') setDevKids(S.fam.kids.map((k) => k.id)); askNotif(); }
      syncNow();
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
      if (S.progDirty || Date.now() - (S.beat || 0) > 6 * 3600000) {
        const notifOn = !!S.notif && typeof Notification !== 'undefined' && Notification.permission === 'granted';
        await Sync.pushProgress(S.code, S.dev, { role: S.role, log: S.log.slice(-500), fav: S.fav, act: (S.act || []).slice(-300), kids: S.devKids || [], plat: platform(), ver: CONFIG.VERSION, notif: notifOn, seen: Date.now() });
        S.progDirty = false; S.beat = Date.now();
      }
      save();
      registerSub();
      loadRemote();
      if (changed && $('home').classList.contains('on')) renderHome();
      if (changed) checkLock();
    } catch (e) {}
    syncing = false;
  }
  let remoteAt = 0;
  async function loadRemote(force) {
    if (!S.code || !Sync.online()) return remote;
    if (!force && Date.now() - remoteAt < 20000) return remote;
    try {
      const before = JSON.stringify(remote.map((p) => [p.dev, p.updated]));
      remote = await Sync.pullProgress(S.code); remoteAt = Date.now();
      if (JSON.stringify(remote.map((p) => [p.dev, p.updated])) !== before) refreshPane();
    } catch (e) {}
    return remote;
  }
  // يعيد رسم الصفحة المفتوحة لما توصل بيانات جديدة من الأجهزة الثانية
  function refreshPane() {
    if (!$('home').classList.contains('on')) return;
    const on = (id) => $(id).style.display !== 'none';
    if (on('paneSky')) Play.renderSky();
    else if (on('panePlay')) Play.renderPlay();
    else if (on('paneLib')) renderLib();
    else if (on('paneTonight')) renderHome();
  }
  function allActs() {
    const seen = new Set(), out = [];
    const add = (a) => { const k = a.t + a.a; if (!seen.has(k)) { seen.add(k); out.push(a); } };
    (S.act || []).forEach(add); remote.filter((p) => p.dev !== S.dev).forEach((p) => (p.act || []).forEach(add));
    return out;
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
  function myKids() {
    const mine = S.role === 'child' ? (S.devKids || []).map(kidById).filter(Boolean) : [];
    return mine.length ? mine : S.fam.kids;
  }
  function renderHome() {
    const shown = myKids();
    sel = (S.sel || []).filter((id) => shown.some((k) => k.id === id));
    if (!sel.length && shown.length) sel = [shown[0].id];
    const h = new Date().getHours();
    const greet = h >= 17 || h < 4 ? 'مساء الخير' : 'أهلًا';
    const own = S.role === 'child' && (S.devKids || []).length && shown.length < S.fam.kids.length;
    $('hello').textContent = own ? `${greet} يا ${names(shown)}، جاهز${shown.length > 1 ? 'ين' : shown[0].g === 'f' ? 'ة' : ''} لحكاية الليلة؟ 🌙` : greet + '، جاهزين لحكاية الليلة؟ 🌙';
    $('kids').innerHTML = shown.map((k) => {
      const i = sel.indexOf(k.id);
      return `<button class="kid ${i >= 0 ? 'sel' : ''} ${i === 0 ? 'hero' : ''}" onclick="App.pick('${k.id}')"><span class="badge">البطل ⭐</span>${ART.avatarSVG(k.av, k.g, 78)}<div class="nm">${esc(k.name)}</div></button>`;
    }).join('');
    const hs = heroes(), n = readTonight(), allow = allowedTonight(), nxt = nextTonight();
    const st = nxt || tonightList()[0], done = !nxt;
    const lbl = ['قصة الليلة', 'القصة الثانية الليلة', 'القصة الثالثة الليلة', 'القصة الرابعة الليلة'][n] || 'قصة إضافية';
    $('tonightCard').innerHTML = hs.length ? `${ART.page(st.scene, done ? '🌙' : st.occ ? '🎉' : '✨', hs)}
      <div class="info">${done ? `<span class="tag" style="background:#EFEAFF;color:#5B4BDB">خلّصتوا قصص الليلة 🌙 (${n}/${allow})</span>` : (st.occ ? '<span class="tag" style="background:#E5FBEA;color:#1E8E4A">قصة المناسبة 🎉</span> ' : '') + (allow > 1 ? `<span class="tag" style="background:#EFEAFF;color:#5B4BDB">${lbl} · ${n + 1}/${allow}</span>` : '')}
      <p class="title">${esc(fill(st.title, hs))}</p><span class="tag">${esc(st.value)}</span>
      ${done ? `<p class="muted" style="margin:10px 0 0">موعدنا بكرة مع قصة جديدة ✨ تقدرون تعيدون قصة من «مكتبتي».</p><button class="btn alt" style="margin-top:12px" onclick="App.openStory('${st.id}')">اقرأها مرة ثانية 🔁</button>`
        : `<button class="btn" style="margin-top:14px" onclick="App.openStory('${st.id}')">ابدأ ${lbl} ✨</button>`}</div>`
      : '<div class="info"><p class="muted">اختر بطلًا واحدًا على الأقل</p></div>';
    $('tabPlay').classList.toggle('dim', isNight());
    $('ver').textContent = 'v' + CONFIG.VERSION;
    $('tabDash').style.display = S.role === 'parent' ? '' : 'none';
    const mb = $('modeBar'), kidsMode = S.parentMode === 'kids';
    mb.style.display = S.role === 'parent' ? '' : 'none';
    mb.innerHTML = `<button class="${kidsMode ? '' : 'on'}" onclick="App.setMode('view')">🔍 معاينة</button><button class="${kidsMode ? 'on' : ''}" onclick="App.setMode('kids')">📖 أقرأ مع العيال</button>`;
    $('modeHint').textContent = S.role !== 'parent' ? '' : kidsMode ? 'القصص والألعاب تنحسب للأبطال المختارين ⭐' : 'تتصفح بس، وما ينحسب شي على العيال';
    renderLib();
  }
  function pick(id) {
    const i = sel.indexOf(id);
    if (i >= 0) sel.splice(i, 1); else sel.push(id);
    S.sel = sel.slice(); save(); renderHome();
  }
  function tab(t) {
    ['tonight', 'sky', 'play', 'lib', 'dash'].forEach((x) => {
      $('tab' + x[0].toUpperCase() + x.slice(1)).classList.toggle('on', x === t);
      $('pane' + x[0].toUpperCase() + x.slice(1)).style.display = x === t ? '' : 'none';
    });
    if (t === 'dash') renderDash();
    if (t === 'sky') Play.renderSky();
    if (t === 'play') Play.renderPlay();
    if (t !== 'dash') loadRemote(true);
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

  /* ---------- جهاز مين؟ ---------- */
  let whoSel = [], whoFirst = false;
  function openWho(first) {
    whoFirst = !!first;
    whoSel = (S.devKids || []).filter(kidById);
    drawWho(); $('whoModal').classList.add('on');
  }
  function drawWho() {
    $('whoKids').innerHTML = S.fam.kids.map((k) => `<button class="kid ${whoSel.includes(k.id) ? 'sel' : ''}" onclick="App.whoPick('${k.id}')">${ART.avatarSVG(k.av, k.g, 70)}<div class="nm">${esc(k.name)}</div></button>`).join('');
    $('whoAll').classList.toggle('on', whoSel.length === S.fam.kids.length);
    $('whoOk').disabled = !whoSel.length;
    $('whoOk').textContent = whoSel.length ? 'هذا جهاز ' + names(whoSel.map(kidById)) + ' ✓' : 'اختر طفلًا واحدًا على الأقل';
  }
  function whoPick(id) { const i = whoSel.indexOf(id); if (i >= 0) whoSel.splice(i, 1); else whoSel.push(id); drawWho(); }
  function whoAll() { whoSel = whoSel.length === S.fam.kids.length ? [] : S.fam.kids.map((k) => k.id); drawWho(); }
  function whoDone() {
    if (!whoSel.length) return;
    setDevKids(whoSel.slice()); closeModal('whoModal');
    toast('أهلًا ' + names(whoSel.map(kidById)) + ' 🌙');
    if ($('settings').classList.contains('on')) renderSettings(); else renderHome();
    if (whoFirst) askNotif();
  }
  function setDevKids(ids) { S.devKids = ids; S.sel = ids.slice(0, 1); S.progDirty = true; save(); syncNow(); }
  function platform() {
    const u = navigator.userAgent;
    if (/iPad/.test(u) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'آيباد';
    if (/iPhone/.test(u)) return 'آيفون';
    if (/Android/.test(u)) return /Mobile/.test(u) ? 'جوال أندرويد' : 'تابلت أندرويد';
    return 'متصفح';
  }
  function devices() {
    const hidden = S.fam.hiddenDevs || [];
    return remote.filter((p) => p.dev !== S.dev && !hidden.includes(p.dev)).map((p) => ({ ...p, last: p.seen || p.updated || 0 })).sort((a, b) => b.last - a.last);
  }
  function hideDev(dev) {
    if (!confirm('إزالة هذا الجهاز من القائمة؟ (لو رجع ينفتح، يرجع يظهر)')) return;
    S.fam.hiddenDevs = [...new Set([...(S.fam.hiddenDevs || []), dev])]; famChanged(); renderDash();
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
          ${(() => {
            const sk = Play.skyInfo(k), A = allActs().filter((a) => (a.k || []).includes(k.id));
            const cnt = (t) => A.filter((a) => a.a === t).length;
            const best = A.filter((a) => a.a === 'quiz').reduce((m, a) => Math.max(m, a.sc || 0), 0);
            return `<p class="muted" style="margin:8px 0 0">⭐ ${sk.n} نجمة · ✨ ${sk.done} كوكبة${A.length ? ` · 🎨 ${cnt('color')} · 🧩 ${cnt('puzzle')} · ❓ ${cnt('quiz')}${best ? ' (أفضل ' + best + '/3)' : ''}` : ''}</p>`;
          })()}
          ${(() => {
            const d = devices().filter((x) => x.role === 'child' && (x.kids || []).includes(k.id));
            return d.length ? `<div class="devbadge on">📱 سِراج مثبّت على ${esc(d[0].plat || 'جهاز')}${d.length > 1 ? ' و' + (d.length - 1) + ' غيره' : ''} · آخر فتح ${ago(d[0].last)}</div>`
              : `<button class="devbadge" onclick="App.showFamilyCode(false)">⚪ ما فيه جهاز مربوط ل${k.g === 'f' ? 'ها' : 'ه'}، اربط جهاز${k.g === 'f' ? 'ها' : 'ه'} ←</button>`;
          })()}
        </div>`;
      }).join('');
      const devs = devices();
      const devCard = `<div class="card"><h2>الأجهزة المربوطة 📱</h2>${devs.length ? '<div class="list">' + devs.map((d) => {
          const ks = (d.kids || []).map(kidById).filter(Boolean);
          const who = d.role === 'parent' ? 'وليّ أمر' : ks.length ? names(ks) : 'جهاز طفل (ما اختار اسمه بعد)';
          const fresh = Date.now() - d.last < 3 * 864e5;
          return `<div class="li"><span class="dot ${fresh ? 'on' : ''}"></span><span class="nm" style="font-size:16px">${esc(who)}<br><span class="muted" style="font-size:13px">${esc(d.plat || 'جهاز')} · آخر فتح ${ago(d.last)}${d.ver ? ' · v' + esc(d.ver) : ''}${d.notif ? ' · 🔔' : ''}</span></span><button class="small del" onclick="App.hideDev('${d.dev}')">إزالة</button></div>`;
        }).join('') + '</div>' : '<p class="muted">ما فيه أجهزة مربوطة غير هذا الجوال.</p>'}
        <button class="btn alt" style="margin-top:10px" onclick="App.showFamilyCode(false)">+ ربط جهاز جديد</button></div>`;
      const recent = logs.slice(0, 12).map((e) => {
        const st = STORIES.find((s) => s.id === e.s); const ks = (e.k || []).map(kidById).filter(Boolean);
        if (!st) return '';
        const who = ks.length ? names(ks) : '—';
        const t = new Date(e.t);
        return `<div class="li"><span class="nm" style="font-size:16px">${esc(ks.length ? fill(st.title, ks) : st.title.replace(/\{n\}/g, '…'))}<br><span class="muted" style="font-size:13px">${esc(who)} · ${t.toLocaleDateString('ar-SA-u-nu-latn', { weekday: 'long', day: 'numeric', month: 'short' })} ${t.toLocaleTimeString('ar-SA-u-nu-latn', { hour: 'numeric', minute: '2-digit' })} · ${e.role === 'child' ? 'جهاز الطفل' : 'جوال وليّ الأمر'}</span></span></div>`;
      }).join('');
      el.innerHTML = (S.code ? '' : '<div class="card"><p class="muted">اربط جهاز الطفل بعائلتك عشان تشوف قراءته هنا.</p></div>') + cards + devCard +
        `<div class="card"><h2>آخر النشاط</h2><div class="list">${recent || '<p class="muted">ما فيه نشاط بعد</p>'}</div></div>` +
        ((S.log.length || (S.act || []).length) ? `<div class="card"><h2>قراءات هذا الجوال</h2><p class="muted">قصص وألعاب انحسبت من جوالك (${S.log.length} قصة · ${(S.act || []).length} لعبة). لو كنت تتصفح بس، امسحها عشان ما تنحسب على العيال.</p><button class="btn alt" onclick="App.clearMine()">مسح قراءات هذا الجوال</button></div>` : '');
    };
    draw();
    await loadRemote(); draw();
  }


  /* ---------- الليل: عدد قصص الليلة، ووقت الألعاب، وقفل وقت النوم ---------- */
  const mins = (hm) => { const [h, m] = String(hm || '0:0').split(':').map(Number); return h * 60 + m; };
  const nowMin = () => { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); };
  const MORNING = 5 * 60;
  function inWindow(fromHM) { const n = nowMin(), f = mins(fromHM); return f > MORNING ? (n >= f || n < MORNING) : (n >= f && n < MORNING); }
  function isNight() { return inWindow(S.fam.bedtime || '20:30'); }
  function isLocked() {
    if (S.role !== 'child' || !S.fam.lockOn || !S.code) return false;
    if ((S.unlockUntil || 0) > Date.now()) return false;
    return inWindow(S.fam.lock || '21:30');
  }
  function nightKey() { const d = new Date(); if (nowMin() < MORNING) d.setDate(d.getDate() - 1); return dateKey(d); }
  function allowedTonight() { const x = S.fam.extra; return (S.fam.perNight || 1) + (x && x.d === nightKey() ? x.n : 0); }
  function tonightList() {
    const first = storyOfDay(), pool = STORIES.filter((s) => !s.occ && s.id !== first.id);
    const today = new Set([dateKey(), nightKey()]);
    const read = new Set(allLogs().filter((e) => !today.has(e.d)).map((e) => e.s)); // اللي انقرت قبل الليلة بس، عشان ما تتغير القائمة أثناء الليل
    const r = rng(hash((S.code || 'x') + '#extra#' + nightKey()));
    const order = pool.map((s) => [r(), s]).sort((a, b) => a[0] - b[0]).map((x) => x[1]);
    const fresh = order.filter((s) => !read.has(s.id)), rest = order.filter((s) => read.has(s.id));
    return [first, ...fresh, ...rest].slice(0, 6);
  }
  function readTonight() {
    const day = new Set([dateKey(), nightKey()]);
    const ids = new Set(allLogs().filter((e) => day.has(e.d) && (e.k || []).some((k) => heroes().some((h) => h.id === k))).map((e) => e.s));
    return tonightList().filter((s) => ids.has(s.id)).length;
  }
  function nextTonight() { const n = readTonight(); return n < allowedTonight() ? tonightList()[n] : null; }
  const SLEEP_MSGS = ['النوم بدري يخليك تصحى نشيط مثل العصفور 🐦', 'جسمك يكبر ويقوى وأنت نايم 🌱', 'غمّض عيونك واقرأ أذكار النوم 🤲', 'أحلام سعيدة، وموعدنا بكرة مع قصة جديدة ✨', 'حتى القمر يسهر عشان يحرس نومك 🌙', 'اللي ينام بدري يلعب أكثر بكرة ⚽'];
  function checkLock() {
    const on = isLocked(), el = $('lock');
    if (!el) return;
    if (on) {
      const n = names(myKids());
      const msg = SLEEP_MSGS[Math.floor(Date.now() / 3e5) % SLEEP_MSGS.length];
      $('lockText').innerHTML = `${n ? 'يا ' + esc(n) + '، ' : ''}${esc(msg)}`;
      if (!el.classList.contains('on')) { stopSpeak(); Play.stopPlay(); }
      el.classList.add('on');
    } else el.classList.remove('on');
  }
  function unlockParent() { askPin(() => { S.unlockUntil = Date.now() + 30 * 6e4; save(); checkLock(); toast('مفتوح لمدة ٣٠ دقيقة'); }); }
  function giveExtra() {
    const k = nightKey(), x = S.fam.extra && S.fam.extra.d === k ? S.fam.extra.n : 0;
    S.fam.extra = { d: k, n: x + 1 }; famChanged();
    toast('صار لهم الليلة ' + allowedTonight() + ' قصص ✨'); if ($('settings').classList.contains('on')) renderSettings();
  }
  function setPerNight(n) { S.fam.perNight = n; famChanged(); renderSettings(); }
  function setLock() { S.fam.lockOn = $('lockOn').checked; S.fam.lock = $('lockTime').value || '21:30'; famChanged(); toast('تم الحفظ ✓'); checkLock(); }

  /* ---------- القارئ ---------- */
  function openStory(id, opt) {
    const hs = heroes();
    if (!hs.length) return toast('اختر بطل القصة أولًا');
    const st = STORIES.find((s) => s.id === id);
    R = { st, hs, i: 0, total: st.pages.length + 2, logged: false, rec: !!(opt && opt.rec) };
    show('reader'); renderPage();
  }
  function recKey() { return R.st.id + ':' + R.i; }
  function recChanged() { if (R) renderRecBar(); }
  async function renderRecBar() {
    const bar = $('recBar'); if (!bar || !R) return;
    const recBtn = $('recBtn'); if (recBtn) recBtn.classList.toggle('on', R.rec);
    if (!R.rec || R.i > R.st.pages.length) { bar.innerHTML = ''; bar.style.display = 'none'; return; }
    bar.style.display = '';
    const r = await Play.getRec(recKey()), live = Play.recording();
    const by = r && kidById(r.by);
    bar.innerHTML = live ? `<button class="btn rec live" onclick="App.recStop()">⏹ إيقاف التسجيل</button>`
      : `<button class="btn rec" onclick="App.recStart()">🎙️ ${r ? 'أعد التسجيل' : 'سجّل هذي الصفحة'}</button>${r ? `<button class="btn alt" onclick="App.recPlay()">▶ اسمع</button>` : ''}`;
    if (r && !live) bar.insertAdjacentHTML('beforeend', `<span class="recby">🎙️ ${by ? 'بصوت ' + esc(by.name) : 'مسجّل'}</span>`);
  }
  function recStart() { Play.stopPlay(); stopSpeak(); Play.startRec(recKey(), (R.hs[0] || {}).id); }
  function recStop() { Play.stopRec(); }
  function recPlay() { Play.playRec(recKey()); }
  function toggleRec() {
    if (!Play.canRec()) return toast('هذا الجهاز ما يدعم التسجيل');
    R.rec = !R.rec; if (!R.rec) Play.stopRec();
    toast(R.rec ? 'وضع التسجيل: اقرأ كل صفحة بصوتك 🎙️' : 'انتهى وضع التسجيل'); renderRecBar();
  }
  function renderPage() {
    const { st, hs, i, total } = R;
    clearTimeout(sleepTimer); $('sleep').classList.remove('on');
    $('favBtn').textContent = S.fav.includes(st.id) ? '⭐' : '☆';
    $('viewTag').style.display = counts() ? 'none' : '';
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
      if (!R.rec) logStory();
    } else {
      const n = names(hs), one = hs.length === 1, f = one && hs[0].g === 'f';
      const nxt = R.rec ? null : nextTonight(), cel = Play.celebrate(hs);
      if (nxt && nxt.id !== st.id) {
        html = `${cel}<div class="goodnight"><div class="moon">⭐</div><h1>أحسنتم!</h1><p class="ptext">${esc(n)}، الليلة لكم قصة ثانية ✨<br>«${esc(fill(nxt.title, hs))}»</p></div>`;
        say = 'أحسنتم! الليلة لكم قصة ثانية.';
        nav = `<button class="btn alt" onclick="App.closeReader()">خلاص، ننام 😴</button><button class="btn" onclick="App.openStory('${nxt.id}')">القصة التالية ✨</button>`;
      } else {
        html = `${cel}<div class="goodnight"><div class="moon">🌙</div><h1>${one ? (f ? 'تصبحين على خير' : 'تصبح على خير') : 'تصبحون على خير'}</h1>
        <p class="ptext">نومًا هنيئًا يا ${esc(n)} ✨<br>وموعدنا مع حكايةٍ جديدة غدًا</p><p class="muted" style="color:#ffffff88">الشاشة بتخفت لحالها… 😴</p></div>`;
        say = (one ? (f ? 'تصبحين على خير يا ' : 'تصبح على خير يا ') : 'تصبحون على خير يا ') + n + '. نومًا هنيئًا.';
        nav = '<button class="btn alt" onclick="App.closeReader()">إغلاق</button>';
        sleepTimer = setTimeout(() => $('sleep').classList.add('on'), 6000);
      }
    }
    $('stage').innerHTML = html; $('nav').innerHTML = nav;
    speak(say);
  }
  // في جوال وليّ الأمر: «معاينة» ما تنحسب، و«أقرأ مع العيال» تنحسب
  function counts() { return S.role !== 'parent' || S.parentMode === 'kids'; }
  function setMode(m) {
    S.parentMode = m; save(); renderHome();
    toast(m === 'kids' ? 'تنحسب القصص والألعاب للعيال 📖' : 'وضع المعاينة: ما ينحسب شي 🔍');
    if ($('paneSky').style.display !== 'none') Play.renderSky();
    if ($('panePlay').style.display !== 'none') Play.renderPlay();
  }
  function clearMine() {
    if (!confirm('مسح القصص والألعاب اللي انحسبت من هذا الجوال؟ (قراءات التابلت تبقى)')) return;
    S.log = []; S.act = []; S.progDirty = true; save(); syncNow(); toast('تم المسح ✓'); renderDash();
  }
  function logStory() {
    if (R.logged) return; R.logged = true;
    if (!counts()) return;
    const e = { s: R.st.id, d: dateKey(), k: R.hs.map((k) => k.id), t: Date.now() };
    S.log.push(e); if (S.log.length > 1500) S.log = S.log.slice(-1500);
    S.progDirty = true; save();
    if (S.code && Sync.online()) { syncNow(); Sync.event(S.code, S.dev, e.k, e.s).catch(() => {}); }
  }
  function step(d) { R.i = Math.max(0, Math.min(R.total - 1, R.i + d)); window.scrollTo(0, 0); renderPage(); }
  function closeReader() {
    stopSpeak(); Play.stopPlay(); Play.stopRec(); clearTimeout(sleepTimer); $('sleep').classList.remove('on'); R = null;
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


  /* ---------- اختيار وقت القصة ---------- */
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  function setTime(id, v) {
    let [h, m] = (v || '20:30').split(':').map(Number);
    $(id).value = String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0');
    const h12 = h % 12 || 12, part = h < 4 ? 'بعد منتصف الليل' : h < 12 ? 'صباحًا' : h < 15 ? 'ظهرًا' : h < 18 ? 'عصرًا' : 'مساءً';
    $(id + 'View').innerHTML = `<b>${AR(h12)}:${AR(String(m).padStart(2, '0'))}</b><span>${part} 🌙</span>`;
    $(id + 'Quick').innerHTML = ['19:30', '20:00', '20:30', '21:00'].map((t) => {
      const [a, b] = t.split(':').map(Number);
      return `<button type="button" class="${t === $(id).value ? 'on' : ''}" onclick="App.setTime('${id}','${t}')">${AR(a % 12 || 12)}:${AR(String(b).padStart(2, '0'))}</button>`;
    }).join('');
  }
  function bumpTime(id, d) {
    let [h, m] = $(id).value.split(':').map(Number);
    let t = (h * 60 + m + d + 1440) % 1440;
    setTime(id, Math.floor(t / 60) + ':' + (t % 60));
  }

  /* ---------- الإعدادات ---------- */
  function openSettings() { show('settings'); }
  function renderSettings() {
    $('famCode').textContent = S.code || '—';
    const dk = (S.devKids || []).map(kidById).filter(Boolean);
    $('devRole').textContent = S.role === 'child' ? 'جهاز ' + (dk.length ? names(dk) : 'طفل') + ' 🧒' : 'جوال وليّ الأمر 👨‍👩‍👧';
    $('whoRow').style.display = S.role === 'child' && S.fam.kids.length > 1 ? '' : 'none';
    $('famBox').style.display = S.code ? '' : 'none';
    renderQR();
    renderKidList($('setKids'), true);
    buildCallChips('setDad', 'dad', DAD); buildCallChips('setMom', 'mom', MOM);
    setTime('bedTime', S.fam.bedtime || '20:30');
    $('remindOn').checked = !!S.fam.remind;
    $('notifState').textContent = !CONFIG.VAPID ? 'الإشعارات تحتاج إعداد السيرفر أولًا'
      : S.notif && typeof Notification !== 'undefined' && Notification.permission === 'granted' ? 'مفعّلة على هذا الجهاز ✓' : 'غير مفعّلة على هذا الجهاز';
    $('notifBtn').style.display = !CONFIG.VAPID || (S.notif && typeof Notification !== 'undefined' && Notification.permission === 'granted') ? 'none' : '';
    $('remindNote').textContent = S.role === 'child' ? 'التذكير يوصل لهذا الجهاز في الوقت المحدد.' : 'التذكير يوصل لأجهزة الأطفال المربوطة، وأنت يوصلك إشعار لما يخلصون القصة.';
    $('perNight').innerHTML = [1, 2, 3].map((v) => `<button class="${(S.fam.perNight || 1) === v ? 'on' : ''}" onclick="App.setPerNight(${v})">${AR(v)}</button>`).join('');
    $('lockOn').checked = !!S.fam.lockOn; setTime('lockTime', S.fam.lock || '21:30');
    const ex = S.fam.extra && S.fam.extra.d === nightKey() ? S.fam.extra.n : 0;
    $('extraNote').textContent = ex ? 'الليلة: ' + AR(allowedTonight()) + ' قصص (منها ' + AR(ex) + ' إضافية)' : '';
    $('storyCount').textContent = STORIES.length;
    libShown = 8; filterStories();
    $('ver2').textContent = CONFIG.VERSION;
  }
  /* مكتبة القصص في الإعدادات: فلاتر + بحث + بطاقات بصور، ٨ في كل دفعة */
  const LIB_FILTERS = [['الكل', ''], ['الصدق والأمانة', 'الصدق|الأمانة'], ['الرحمة', 'الرحمة|الرفق'], ['المشاركة', 'المشاركة|العطاء|التعاون|الكرم|ضيف'],
    ['الشجاعة والثقة', 'الشجاعة|الثقة'], ['العادات الجميلة', 'النظافة|الترتيب|النوم|الأكل|الاستعداد|السلامة|الأمان'], ['العائلة', 'الوالدين|العائلة|الكبار|الحب'], ['المناسبات', '#occ']];
  let libFilter = '', libShown = 8;
  function setLibFilter(f) { libFilter = f; libShown = 8; filterStories(); }
  function moreStories() { libShown += 8; filterStories(); }
  function filterStories() {
    $('libChips').innerHTML = LIB_FILTERS.map(([t, f]) => `<button class="chip ${f === libFilter ? 'on' : ''}" onclick="App.setLibFilter('${f}')">${t}</button>`).join('');
    const q = ($('storySearch').value || '').trim();
    const re = libFilter && libFilter !== '#occ' ? new RegExp(libFilter) : null;
    const hero = S.fam.kids.length ? [S.fam.kids[0]] : [{ name: 'البطل', g: 'm', av: {} }];
    const all = STORIES.filter((s) => (!q || s.title.includes(q) || s.value.includes(q)) &&
      (libFilter === '#occ' ? !!s.occ : !re || re.test(s.value)));
    const read = new Set(allLogs().map((e) => e.s));
    $('allStories').innerHTML = all.slice(0, libShown).map((s) => `<button class="sitem" onclick="App.preview('${s.id}')">
        ${ART.page(s.scene, s.occ ? '🎉' : '', [])}
        <div class="st">${esc(fill(s.title, hero))}</div>
        <div class="sv"><span class="tag">${esc(s.value)}</span>${read.has(s.id) ? '<span class="rd">✓ قُرئت</span>' : ''}</div>
      </button>`).join('') || '<p class="muted" style="grid-column:1/-1;text-align:center">ما لقينا قصة بهذا الاسم</p>';
    $('moreStories').style.display = all.length > libShown ? '' : 'none';
    $('moreStories').textContent = 'عرض المزيد (' + (all.length - libShown) + ')';
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
    $('fcFirst').textContent = first ? 'تم إنشاء عائلتك!' : 'رمز عائلتك جاهز 🔑';
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
      const sub = await currentSub(true);
      S.notif = true; save();
      await Sync.sub(S.code, S.dev, S.role, S.fam.remind ? S.fam.bedtime : '', sub);
      toast('تم تفعيل الإشعارات ✓');
      if ($('settings').classList.contains('on')) renderSettings();
    } catch (e) { toast('تعذّر تفعيل الإشعارات'); }
  }
  /* اشتراك الإشعارات الحالي؛ لو تغيّر مفتاح الخادم (VAPID) نلغي القديم ونشترك من جديد تلقائيًا */
  async function currentSub(create) {
    const reg = await navigator.serviceWorker.ready;
    let sub = await reg.pushManager.getSubscription();
    if (sub) {
      const k = sub.options && sub.options.applicationServerKey;
      const want = vapidKey();
      const same = k && new Uint8Array(k).length === want.length && new Uint8Array(k).every((b, i) => b === want[i]);
      if (k && !same) { await sub.unsubscribe().catch(() => {}); sub = null; }
    }
    if (!sub && (create || (typeof Notification !== 'undefined' && Notification.permission === 'granted')))
      sub = await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: vapidKey() });
    return sub;
  }
  async function registerSub() {
    if (!S.notif || !CONFIG.VAPID || !('serviceWorker' in navigator)) return;
    try {
      const sub = await currentSub(false);
      if (sub) await Sync.sub(S.code, S.dev, S.role, S.fam.remind ? S.fam.bedtime : '', sub);
    } catch (e) {}
  }
  async function disableNotif(silent) {
    try { const reg = await navigator.serviceWorker.ready; const sub = await reg.pushManager.getSubscription(); if (sub) { await Sync.sub(S.code, S.dev, S.role, '', sub, true).catch(() => {}); await sub.unsubscribe(); } } catch (e) {}
    S.notif = false; save(); if (!silent) { toast('تم إيقاف الإشعارات'); renderSettings(); }
  }

  /* ---------- التحديث التلقائي ---------- */
  /* نقارن رقم الإصدار المنشور بالإصدار اللي شغال؛ لو فيه جديد نحدّث فورًا (أو بعد ما تخلص القصة) */
  let swReg = null, lastCheck = 0, updating = false;
  async function checkVersion() {
    if (updating || navigator.onLine === false) return;
    lastCheck = Date.now();
    try {
      if (swReg && swReg.update) swReg.update().catch(() => {});
      const txt = await (await fetch('config.js?v=' + Date.now(), { cache: 'no-store' })).text();
      const m = txt.match(/VERSION:\s*'([^']+)'/);
      if (m && m[1] !== CONFIG.VERSION) applyUpdate();
    } catch (e) {}
  }
  function applyUpdate() {
    if (R) { pendingReload = true; return; }             // لا نقاطع قصة شغالة
    updating = true;
    try { sessionStorage.setItem('siraj-updated', '1'); } catch (e) {}
    const go = () => location.reload();
    if (swReg && swReg.waiting) { swReg.waiting.postMessage('skip'); setTimeout(go, 1500); } else setTimeout(go, 300);
  }
  function setupSW() {
    if (!('serviceWorker' in navigator)) return;
    const had = !!navigator.serviceWorker.controller;
    navigator.serviceWorker.register('sw.js', { updateViaCache: 'none' }).then((reg) => {
      swReg = reg;
      const wake = () => { checkVersion(); syncNow(); };
      setInterval(wake, 10 * 60000);                       // كل ١٠ دقائق
      document.addEventListener('visibilitychange', () => { if (!document.hidden) wake(); });
      ['focus', 'pageshow', 'online'].forEach((ev) => addEventListener(ev, wake));
      document.addEventListener('pointerdown', () => { if (Date.now() - lastCheck > 15 * 60000) checkVersion(); }, { passive: true });
      checkVersion();
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
    // عائلة من النسخة 1.0 ما عندها رمز: ننشئ لها رمزًا ونرفعها، ونعرض الرمز مرة وحدة
    let newCode = false;
    if (S.role === 'parent' && S.fam.kids.length && S.fam.pin && !S.code) { S.code = Sync.newCode(); S.dirty = true; newCode = true; }
    if (updated) setTimeout(() => toast('تم التحديث ✨ الإصدار ' + CONFIG.VERSION), 500);
    setupSW(); save();
    try { indexedDB.deleteDatabase('siraj-rec'); } catch (e) {} // تسجيلات تجريبية من 1.7
    checkLock(); setInterval(checkLock, 30000);
    document.addEventListener('visibilitychange', () => { if (!document.hidden) checkLock(); });
    syncNow().then(() => {
      if (newCode && $('home').classList.contains('on')) { showFamilyCode(false); askNotif(); }
      if (S.role === 'child' && S.code && !(S.devKids || []).filter(kidById).length && $('home').classList.contains('on')) {
        if (S.fam.kids.length > 1) openWho(false); else if (S.fam.kids.length) setDevKids([S.fam.kids[0].id]);
      }
    });
  }

  function ctx() {
    return { counts, S: () => S, save, famChanged, syncNow, fill, kidById, heroes, myKids, toast, esc, allLogs, storyOfDay, isNight, openStory,
      renderHomeKids: () => { if ($('home').classList.contains('on')) renderHome(); } };
  }

  return {
    ctx, setMode, clearMine, recChanged, recStart, recStop, recPlay, toggleRec, unlockParent, giveExtra, setPerNight, setLock, isNight, isLocked,
    init, show, skipWelcome, openSetup, finishSetup, openJoin, doJoin, editKid, saveKid, delKid, closeModal, pick, tab,
    openStory, step, closeReader, wake, toggleFav, toggleVoice, askPin, openSettings, changePin, openWho, whoPick, whoAll, whoDone, hideDev, setTime, bumpTime, preview, filterStories, setLibFilter, moreStories, setBed,
    showFamilyCode, shareJoin, copyCode, shareApp, unlink, enableNotif, disableNotif, fill, storyOfDay, _state: () => S
  };
})();

App.init();

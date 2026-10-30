/* سِراج | SIRAJ — سماء سِراج، والألعاب (تلوين، أحجية، أسئلة)، والتسجيل بالصوت
   يستخدم App.ctx() وقت التشغيل */
const Play = (() => {
  const $ = (id) => document.getElementById(id);
  const C = () => App.ctx();

  /* ================= سماء سِراج ================= */
  const CONST = ['كوكبة الصدق', 'كوكبة الشجاعة', 'كوكبة الرحمة', 'كوكبة المشاركة', 'كوكبة الصبر', 'كوكبة العلم', 'كوكبة البرّ', 'كوكبة الأمانة',
    'كوكبة اللطف', 'كوكبة التعاون', 'كوكبة الشكر', 'كوكبة الأحلام'];
  // أشكال الكوكبات (٧ نجوم لكل وحدة) على لوحة 300×200
  const SHAPES = [
    [[40, 150], [80, 110], [130, 120], [160, 70], [200, 90], [240, 50], [270, 100]],
    [[60, 60], [100, 40], [150, 60], [150, 110], [110, 150], [70, 130], [190, 150]],
    [[150, 30], [110, 70], [190, 70], [80, 120], [220, 120], [120, 165], [180, 165]],
    [[40, 100], [90, 60], [140, 100], [190, 60], [240, 100], [140, 150], [140, 40]],
    [[150, 20], [150, 70], [100, 110], [200, 110], [70, 160], [150, 140], [230, 160]],
    [[60, 150], [60, 90], [110, 50], [170, 50], [220, 90], [220, 150], [140, 120]]
  ];
  const EDGES = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6]];

  function kidStories(kid) {
    const set = new Set();
    C().allLogs().forEach((e) => { if ((e.k || []).includes(kid.id)) set.add(e.s); });
    return set.size;
  }
  function skyInfo(kid) {
    const n = kidStories(kid), done = Math.floor(n / 7), cur = n % 7;
    return { n, done, cur, unlocked: ART.ACC.slice(0, Math.min(done, ART.ACC.length)) };
  }
  function skySVG(idx, lit) {
    const sh = SHAPES[idx % SHAPES.length];
    let bg = '';
    let s = idx * 97 + 13; const r = () => (s = (s * 9301 + 49297) % 233280) / 233280;
    for (let i = 0; i < 40; i++) bg += `<circle cx="${(r() * 300).toFixed(0)}" cy="${(r() * 200).toFixed(0)}" r="${(r() * 1.2 + .3).toFixed(1)}" fill="#fff" opacity="${(r() * .5 + .2).toFixed(2)}"/>`;
    const lines = EDGES.filter(([a, b]) => a < lit && b < lit).map(([a, b]) => `<line x1="${sh[a][0]}" y1="${sh[a][1]}" x2="${sh[b][0]}" y2="${sh[b][1]}" stroke="#FFE27A" stroke-width="1.6" opacity=".6"/>`).join('');
    const dots = sh.map(([x, y], i) => i < lit
      ? `<circle cx="${x}" cy="${y}" r="11" fill="#FFD93D" opacity=".25"/><path d="M${x} ${y - 9} l2.6 6 6.4 .6 -4.8 4.3 1.4 6.3 -5.6 -3.3 -5.6 3.3 1.4 -6.3 -4.8 -4.3 6.4 -.6z" fill="#FFD93D"/>`
      : `<circle cx="${x}" cy="${y}" r="4" fill="#ffffff40"/>`).join('');
    return `<svg viewBox="0 0 300 200" class="skyart"><defs><radialGradient id="sky${idx}" cx=".5" cy=".3" r=".9"><stop offset="0" stop-color="#3B2A7A"/><stop offset="1" stop-color="#120F33"/></radialGradient></defs><rect width="300" height="200" rx="18" fill="url(#sky${idx})"/>${bg}${lines}${dots}</svg>`;
  }
  /* ---- ملصقات: كل قصة أو لعبة تعطي ملصق (عادي، نادر، أسطوري) ---- */
  const STICK = {
    c: ['🐱', '🐶', '🐰', '🐻', '🐼', '🐨', '🐸', '🐥', '🐢', '🐠', '🦋', '🐞', '🌻', '🌈', '🍉', '🍓', '🍩', '🎈', '⚽', '🪁', '🧸', '🚗', '🎨', '📚'],
    r: ['🦊', '🦒', '🐬', '🦜', '🐙', '🚀', '🏰', '🎡', '🌋'],
    l: ['🦄', '🐉', '👑']
  };
  const ALL_ST = [...STICK.c.map((e) => [e, 'c']), ...STICK.r.map((e) => [e, 'r']), ...STICK.l.map((e) => [e, 'l'])];
  function stickerFor(ev, kidId) {
    const h = (str) => { let x = 2166136261; for (const ch of str) { x ^= ch.codePointAt(0); x = Math.imul(x, 16777619); } return x >>> 0; };
    const v = h(ev.t + ':' + ev.s + ':' + kidId), r = (v % 1000) / 1000, pick = (arr) => arr[(v >>> 10) % arr.length];
    return r < 0.04 ? [pick(STICK.l), 'l'] : r < 0.24 ? [pick(STICK.r), 'r'] : [pick(STICK.c), 'c'];
  }
  function kidEvents(kid) {
    const c = C(), ev = [];
    c.allLogs().forEach((e) => { if ((e.k || []).includes(kid.id)) ev.push({ t: e.t, s: e.s, d: e.d, type: 'story' }); });
    (c.allActs ? c.allActs() : []).forEach((a) => { if ((a.k || []).includes(kid.id)) { const d = new Date(a.t); ev.push({ t: a.t, s: a.s + a.a, d: d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'), type: a.a }); } });
    return ev.sort((a, b) => a.t - b.t).map((e) => ({ ...e, st: stickerFor(e, kid.id) }));
  }
  const MONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  function monthGrid(kid, ev) {
    const now = new Date(), y = now.getFullYear(), m = now.getMonth();
    const days = new Date(y, m + 1, 0).getDate(), first = new Date(y, m, 1).getDay(); // الأحد = 0
    const pre = (first + 1) % 7; // الأسبوع يبدأ السبت
    const key = (d) => y + '-' + String(m + 1).padStart(2, '0') + '-' + String(d).padStart(2, '0');
    const byDay = {}; ev.forEach((e) => { (byDay[e.d] = byDay[e.d] || []).push(e); });
    let cells = '';
    for (let i = 0; i < pre; i++) cells += '<i class="md empty"></i>';
    for (let d = 1; d <= days; d++) {
      const E = byDay[key(d)] || [], story = E.some((e) => e.type === 'story'), today = d === now.getDate();
      const st = E.slice(-2).map((e) => e.st[0]).join('');
      cells += `<i class="md ${story ? 'lit' : ''} ${today ? 'today' : ''} ${d > now.getDate() ? 'future' : ''}" ${E.length ? `role="button" onclick="Play.dayInfo('${kid.id}','${key(d)}')"` : d <= now.getDate() ? `role="button" onclick="Play.emptyDay('${kid.id}',${d === now.getDate() ? 1 : 0})"` : ''}><b>${d}</b><span>${story ? '⭐' : ''}${st}</span></i>`;
    }
    const inMonth = ev.filter((e) => e.d.startsWith(y + '-' + String(m + 1).padStart(2, '0')));
    const nStories = new Set(inMonth.filter((e) => e.type === 'story').map((e) => e.d)).size;
    return `<div class="month"><div class="mhead"><b>${MONTHS[m]} ${y}</b><span>⭐ ${nStories} ليلة · 🎁 ${inMonth.length} ملصق</span></div>
      <div class="mdays">${['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'].map((x) => `<i class="mw">${x}</i>`).join('')}${cells}</div></div>`;
  }
  function album(ev) {
    const have = {}; ev.forEach((e) => { have[e.st[0]] = (have[e.st[0]] || 0) + 1; });
    const got = ALL_ST.filter(([e]) => have[e]).length;
    return `<h3 class="sub">ألبوم الملصقات (${got}/${ALL_ST.length}) 📒</h3><div class="album">${ALL_ST.map(([e, t], i) => have[e]
      ? `<button class="stk ${t}" onclick="Play.stkInfo('${ev.kid}',${i})">${e}${have[e] > 1 ? `<small>×${have[e]}</small>` : ''}</button>` : `<button class="stk none ${t}" onclick="Play.stkInfo('${ev.kid}',${i})">?</button>`).join('')}</div>
      <p class="muted" style="font-size:13px;margin:6px 0 0">🟣 نادر · 🌟 أسطوري: حظك مع كل قصة ولعبة!</p>`;
  }
  function renderSky() {
    const c = C(), kids = c.myKids();
    $('sky').innerHTML = kids.map((k) => {
      const info = skyInfo(k), name = CONST[info.done % CONST.length], ev = kidEvents(k); ev.kid = k.id;
      const f = k.g === 'f', left = 7 - info.cur;
      const chips = Array.from({ length: info.done }, (_, i) => `<span class="cchip">✨ ${CONST[i % CONST.length]}</span>`).join('');
      const accs = ART.ACC.map((a, i) => {
        const open = i < info.done, on = (k.av.acc || '') === a.id;
        return `<button class="accb ${open ? '' : 'lock'} ${on ? 'on' : ''}" onclick="Play.accInfo('${k.id}',${i})"><span>${open ? a.icon : '🔒'}</span><small>${open ? a.name : (i + 1) * 7 + ' نجمة'}</small></button>`;
      }).join('');
      return `<div class="card skycard">
        <div class="row" style="align-items:center;gap:12px;flex:none">${ART.avatarSVG(k.av, k.g, 62)}<div style="flex:1"><h2 style="margin:0">سماء ${c.esc(k.name)}</h2>
        <span class="muted" style="margin:0">⭐ ${info.n} نجمة · ✨ ${info.done} كوكبة · 🎁 ${ev.length} ملصق</span></div>
        <button class="small" onclick="App.editKid('${k.id}', true)">✏️ غيّر شكلي</button></div>
        ${monthGrid(k, ev)}
        <div class="skywrap">${skySVG(info.done, info.cur)}<div class="skylbl">${name} · ${info.cur}/7</div></div>
        <p class="muted" style="text-align:center;margin:8px 0">${info.cur === 0 && info.n ? 'بدأت كوكبة جديدة! 🌟' : 'باقي ' + left + ' ' + (left === 1 ? 'قصة' : 'قصص') + ' وتكتمل الكوكبة، و' + (f ? 'تفتحين' : 'تفتح') + ' هدية جديدة 🎁'}</p>
        ${chips ? `<div class="cchips">${chips}</div>` : ''}
        <h3 class="sub">هدايا ${c.esc(k.name)} 🎁</h3><div class="accs">${accs}</div>
        ${album(ev)}
      </div>`;
    }).join('') || '<p class="empty">أضف الأطفال أولًا</p>';
  }

  /* ================= شرح النجوم والملصقات والهدايا (لما يضغطون) ================= */
  const ST_NAMES = { '🐱': 'قطة', '🐶': 'كلب', '🐰': 'أرنب', '🐻': 'دبدوب', '🐼': 'باندا', '🐨': 'كوالا', '🐸': 'ضفدع', '🐥': 'صوص', '🐢': 'سلحفاة', '🐠': 'سمكة', '🦋': 'فراشة', '🐞': 'دعسوقة', '🌻': 'زهرة شمس', '🌈': 'قوس قزح', '🍉': 'بطيخ', '🍓': 'فراولة', '🍩': 'دونات', '🎈': 'بالون', '⚽': 'كورة', '🪁': 'طيارة ورق', '🧸': 'دبدوب قطني', '🚗': 'سيارة', '🎨': 'ألوان', '📚': 'كتب',
    '🦊': 'ثعلب', '🦒': 'زرافة', '🐬': 'دلفين', '🦜': 'ببغاء', '🐙': 'أخطبوط', '🚀': 'صاروخ', '🏰': 'قلعة', '🎡': 'دولاب الهوا', '🌋': 'بركان', '🦄': 'حصان وحيد القرن', '🐉': 'تنين', '👑': 'تاج ذهبي' };
  const RARITY = { c: ['ملصق', ''], r: ['ملصق نادر', '🟣'], l: ['ملصق أسطوري', '🌟'] };
  const ACT_NAME = { color: 'لوّنت المشهد 🎨', puzzle: 'رتّبت الأحجية 🧩', quiz: 'جاوبت أسئلة القصة ❓', en: 'لعبت English 🔤' };
  const WEEKDAY = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  const gx = (k, m, f) => (k.g === 'f' ? f : m);
  const pickMsg = (arr) => arr[Math.floor(Math.random() * arr.length)];
  function cheer(k, value) {
    const n = C().esc(k.name), f = k.g === 'f';
    return pickMsg([
      value ? `يا ${n}، ${f ? 'أنتِ بطلة' : 'أنت بطل'} ${value} اليوم! 🏅` : `يا ${n}، ${f ? 'أنتِ نجمة' : 'أنت نجم'} العيلة! 🌟`,
      `كل قصة ${f ? 'تقرينها' : 'تقراها'} تخلي سماك تلمع أكثر ✨`,
      `${f ? 'كمّلي' : 'كمّل'} يا ${n}، الكوكبة الجاية قريبة! 🚀`,
      `ما شاء الله يا ${n}، ${f ? 'شاطرة' : 'شاطر'} ومجتهد${f ? 'ة' : ''} 💪`
    ]);
  }
  function card(html) { $('gameBody').innerHTML = `<div class="infocard">${html}</div><button class="btn" style="margin-top:14px" onclick="Play.closeGame()">حلو! 👍</button>`; $('gameModal').classList.add('on'); }
  function dayInfo(kidId, day) {
    const c = C(), k = c.kidById(kidId); if (!k) return;
    const E = kidEvents(k).filter((e) => e.d === day), d = new Date(day + 'T12:00');
    let lastValue = '';
    const rows = E.map((e) => {
      const [em, r] = e.st, rn = RARITY[r];
      if (e.type === 'story') {
        const st = STORIES.find((x) => x.id === e.s); const title = st ? c.fill(st.title, [k]) : 'قصة';
        if (st) lastValue = st.value;
        return `<li><span class="ii">⭐</span><div><b>نجمة</b> لأن${gx(k, 'ك', 'كِ')} ${gx(k, 'قريت', 'قريتي')} «${c.esc(title)}»${st ? ` و${gx(k, 'تعلّمت', 'تعلّمتِ')} <b>${c.esc(st.value)}</b>` : ''}</div></li>
          <li><span class="ii">${em}</span><div><b>${rn[0]} ${rn[1]}</b>: ${ST_NAMES[em] || ''}، ${gx(k, 'كسبته', 'كسبتيه')} من القصة</div></li>`;
      }
      return `<li><span class="ii">${em}</span><div><b>${rn[0]} ${rn[1]}</b>: ${ST_NAMES[em] || ''}، لأن${gx(k, 'ك', 'كِ')} ${(ACT_NAME[e.type] || 'لعبت').replace('لعبت', gx(k, 'لعبت', 'لعبتِ')).replace('لوّنت', gx(k, 'لوّنت', 'لوّنتِ')).replace('رتّبت', gx(k, 'رتّبت', 'رتّبتِ')).replace('جاوبت', gx(k, 'جاوبت', 'جاوبتِ'))}</div></li>`;
    }).join('');
    card(`<h2>${WEEKDAY[d.getDay()]} ${d.getDate()} ${MONTHS[d.getMonth()]} 🌟</h2><ul class="ilist">${rows}</ul><p class="cheer">${cheer(k, lastValue)}</p>`);
  }
  function emptyDay(kidId, today) {
    const k = C().kidById(kidId); if (!k) return;
    card(`<div class="bigi">${today ? '🌙' : '💤'}</div><h2>${today ? 'اليوم لسا ما فيه نجمة' : 'هاليوم ما فيه نجمة'}</h2><p class="cheer">${today ? `${gx(k, 'اقرأ', 'اقرئي')} قصة الليلة و${gx(k, 'خذ', 'خذي')} نجمة ⭐ وملصق جديد!` : `ولا يهم! كل يوم فرصة جديدة، ${gx(k, 'كمّل', 'كمّلي')} يا ${C().esc(k.name)} 💪`}</p>`);
  }
  function stkInfo(kidId, i) {
    const c = C(), k = c.kidById(kidId); if (!k) return;
    const [em, r] = ALL_ST[i], rn = RARITY[r];
    const mine = kidEvents(k).filter((e) => e.st[0] === em);
    if (!mine.length) {
      const hint = r === 'l' ? 'ملصق أسطوري 🌟 وصعب يطلع! بس مع كل قصة ولعبة فيه فرصة.' : r === 'r' ? 'ملصق نادر 🟣، يطلع أحيانًا مع القصص والألعاب.' : 'ملصق عادي، أكيد يطلع لك قريب!';
      return card(`<div class="bigi lockq">?</div><h2>ملصق مقفّل 🔒</h2><p>${hint}</p><p class="cheer">${gx(k, 'اقرأ', 'اقرئي')} و${gx(k, 'العب', 'العبي')}، يمكن يطلع ${gx(k, 'لك', 'لكِ')} المرة الجاية! 🍀</p>`);
    }
    const first = mine[0], fd = new Date(first.t);
    const from = first.type === 'story' ? (() => { const st = STORIES.find((x) => x.id === first.s); return st ? 'قصة «' + c.esc(c.fill(st.title, [k])) + '»' : 'قصة'; })() : (ACT_NAME[first.type] || 'لعبة');
    card(`<div class="bigi stk ${r}">${em}</div><h2>${ST_NAMES[em] || ''} ${rn[1]}</h2><p><b>${rn[0]}</b> · ${gx(k, 'كسبته', 'كسبتيه')} ${mine.length === 1 ? 'مرة وحدة' : mine.length + ' مرات'}</p>
      <p class="muted">أول مرة: ${fd.getDate()} ${MONTHS[fd.getMonth()]}، من ${from}</p><p class="cheer">${r === 'l' ? 'واو! هذا من أندر الملصقات 🤩' : r === 'r' ? 'محظوظ' + gx(k, '', 'ة') + '! ملصق نادر 🟣' : cheer(k, '')}</p>`);
  }
  function accInfo(kidId, i) {
    const k = C().kidById(kidId); if (!k) return;
    const a = ART.ACC[i], info = skyInfo(k), open = i < info.done, cname = CONST[i % CONST.length];
    if (!open) {
      const left = (i + 1) * 7 - info.n;
      return card(`<div class="bigi">${a.icon}</div><h2>${a.name} 🔒</h2><div class="pbar"><i style="width:${Math.min(100, info.n / ((i + 1) * 7) * 100)}%"></i></div>
        <p>باقي <b>${left}</b> ${left === 1 ? 'قصة' : 'قصص'} و${gx(k, 'تفتح', 'تفتحين')} ${a.name} مع <b>${cname}</b> ✨</p><p class="cheer">${gx(k, 'اقرأ', 'اقرئي')} كل ليلة، وتوصل${gx(k, '', 'ين')}! 🚀</p>`);
    }
    const on = (k.av.acc || '') === a.id;
    $('gameBody').innerHTML = `<div class="infocard"><div class="bigi">${a.icon}</div><h2>${a.name} 🎁</h2><p>${gx(k, 'فتحته', 'فتحتيه')} لما ${gx(k, 'أكملت', 'أكملتِ')} <b>${cname}</b> ✨</p><p class="cheer">${cheer(k, '')}</p></div>
      <div class="row" style="margin-top:14px"><button class="btn" onclick="Play.wear('${k.id}','${on ? '' : a.id}');Play.closeGame()">${on ? 'اخلعه' : 'البسه'} ${a.icon}</button><button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div>`;
    $('gameModal').classList.add('on');
  }

  function lastSticker(kids) {
    const k = kids[0]; if (!k) return '';
    const ev = kidEvents(k), e = ev[ev.length - 1];
    if (!e || Date.now() - e.t > 120000) return '';
    const label = { c: 'ملصق جديد', r: 'ملصق نادر! 🟣', l: 'ملصق أسطوري!! 🌟' }[e.st[1]];
    return `<div class="newstk ${e.st[1]}"><span>${e.st[0]}</span><b>${label}</b><small>انحفظ في ألبوم ${C().esc(k.name)}</small></div>`;
  }
  function wear(kidId, accId) {
    const c = C(), k = c.kidById(kidId); if (!k) return;
    k.av.acc = accId || ''; c.famChanged(); renderSky(); c.renderHomeKids();
    if (accId) c.toast('لابس' + (k.g === 'f' ? 'ة' : '') + ' ' + ART.ACC.find((a) => a.id === accId).name + ' ✨');
  }
  function celebrate(kids) {
    // يُستدعى بعد تسجيل قصة: لو اكتملت كوكبة نعرض احتفال
    for (const k of kids) {
      const info = skyInfo(k);
      if (info.cur === 0 && info.n > 0) {
        const a = ART.ACC[(info.done - 1) % ART.ACC.length];
        return `<div class="celebrate">🎉 ${C().esc(k.name)} ${k.g === 'f' ? 'أكملت' : 'أكمل'} ${CONST[(info.done - 1) % CONST.length]}!<br>${k.g === 'f' ? 'فتحت' : 'فتح'} هدية: ${a.icon} ${a.name}</div>` + lastSticker(kids);
      }
    }
    return lastSticker(kids);
  }

  /* ================= الألعاب ================= */
  const SCENE_AR = { desert: 'البر', sea: 'البحر', space: 'الفضاء', garden: 'الحديقة', home: 'البيت', school: 'المدرسة', night: 'الليل',
    mosque: 'المسجد', park: 'حديقة الألعاب', market: 'السوق', road: 'الحيّ', mountain: 'الجبال', farm: 'المزرعة', kitchen: 'المطبخ', rain: 'تحت المطر' };
  let G = null, forced = null; // حالة اللعبة الحالية، والقصة المختارة للألعاب

  function playStory() {
    if (forced) { const f = STORIES.find((s) => s.id === forced); if (f) return f; }
    const c = C(), logs = c.allLogs();
    const mine = c.myKids().map((k) => k.id);
    const e = logs.find((x) => (x.k || []).some((id) => mine.includes(id))) || logs[0];
    const st = e ? STORIES.find((s) => s.id === e.s) : null;
    return st || c.storyOfDay();
  }
  function acts() { return C().S().act || []; }
  function logAct(a, st, score) {
    const c = C(), S = c.S();
    if (!c.counts()) return; // معاينة وليّ الأمر ما تنحسب
    const who = c.heroes().length ? c.heroes() : c.myKids().slice(0, 1);
    S.act = S.act || []; S.act.push({ a, s: st.id, k: who.map((k) => k.id), t: Date.now(), sc: score || 0 });
    if (S.act.length > 600) S.act = S.act.slice(-600);
    S.progDirty = true; c.save(); c.syncNow();
    setTimeout(() => { const box = $('gameBody'); if (box && $('gameModal').classList.contains('on')) box.insertAdjacentHTML('beforeend', lastSticker(who)); }, 50);
  }
  function renderPlay() {
    const c = C();
    if (c.isNight()) {
      $('play').innerHTML = `<div class="card nightcard"><div style="font-size:64px">😴</div><h2>الألعاب نامت</h2><p class="muted">الحين وقت قصة الليلة بس. الألعاب ترجع الصبح ☀️</p>
        <button class="btn" onclick="App.tab('tonight')">قصة الليلة 🌙</button></div>`;
      return;
    }
    const st = playStory(), hs = c.heroes().length ? c.heroes() : c.myKids().slice(0, 1);
    const title = hs.length ? c.fill(st.title, hs) : st.title;
    const items = [
      ['color', '🎨', 'لوّن المشهد', 'لوّن رسمة القصة بألوانك'],
      ['puzzle', '🧩', 'أحجية الصورة', 'رتّب قطع الصورة'],
      ['quiz', '❓', 'سؤال وجواب', '٣ أسئلة عن القصة']
    ];
    const gal = gallery();
    $('play').innerHTML = `<div class="card playhead">${ART.page(st.scene, '', hs)}<div class="info"><span class="tag">ألعاب قصة</span><p class="title">«${c.esc(title)}»</p>
      <button class="small" onclick="Play.pickStory()">اختر قصة ثانية</button></div></div>
      <div class="games">${items.map(([id, ic, t, d]) => `<button class="game" onclick="Play.open('${id}','${st.id}')"><span>${ic}</span><b>${t}</b><small>${d}</small></button>`).join('')}</div>
      ${gal.length ? `<div class="card"><h2>معرض رسوماتي 🖼️</h2><div class="gallery">${gal.map((g, i) => `<div class="gi">${g.svg}<button class="small del" onclick="Play.delArt(${i})">حذف</button></div>`).join('')}</div></div>` : ''}`;
  }
  function pickStory() {
    const c = C(), seen = new Set(), list = [];
    c.allLogs().forEach((e) => { if (!seen.has(e.s)) { seen.add(e.s); const st = STORIES.find((s) => s.id === e.s); if (st) list.push(st); } });
    if (!list.length) return c.toast('اقرأ قصة أولًا، وبعدها تلعب ألعابها 🌙');
    const hs = c.heroes().length ? c.heroes() : c.myKids().slice(0, 1);
    $('gameBody').innerHTML = `<h2>اختر القصة</h2><div class="slist">${list.slice(0, 30).map((s) => `<button class="sitem" onclick="Play.setStory('${s.id}')">${ART.page(s.scene, '', [])}<div class="st">${c.esc(c.fill(s.title, hs))}</div></button>`).join('')}</div>`;
    $('gameModal').classList.add('on');
  }
  function setStory(id) { forced = id; closeGame(); renderPlay(); }
  function closeGame() { $('gameModal').classList.remove('on'); stopRec(); }
  function open(kind, id) {
    const c = C(), st = (id && STORIES.find((s) => s.id === id)) || playStory();
    const hs = c.heroes().length ? c.heroes() : c.myKids().slice(0, 1);
    if (!hs.length) return c.toast('اختر بطلًا أولًا');
    G = { kind, st, hs };
    if (kind === 'color') colorGame();
    else if (kind === 'puzzle') puzzleGame();
    else if (kind === 'quiz') quizGame();
    else if (kind === 'rec') { c.openStory(st.id, { rec: true }); return; }
    $('gameModal').classList.add('on');
  }

  /* ---- تلوين ---- */
  const PAL = ['#FF6B6B', '#FF9F1C', '#FFD93D', '#4CD97B', '#2FA4E7', '#9B6BF2', '#FF7AB6', '#8B5A2B', '#F1C08F', '#2B2350', '#9BE1FF', '#ffffff'];
  let paint = PAL[0];
  function lineArt(svg) {
    const d = new DOMParser().parseFromString(svg.replace('class="art"', 'class="art color"'), 'image/svg+xml');
    const root = d.documentElement;
    root.querySelectorAll('defs,text').forEach((n) => n.remove());
    root.querySelectorAll('rect,circle,ellipse,path,polygon').forEach((n) => {
      const f = n.getAttribute('fill');
      if (f === 'none') { n.setAttribute('stroke', '#3B3B5C'); return; }
      n.setAttribute('fill', '#ffffff'); n.removeAttribute('opacity');
      n.setAttribute('stroke', '#3B3B5C'); n.setAttribute('stroke-width', '1.2'); n.setAttribute('class', 'paintable');
    });
    return new XMLSerializer().serializeToString(root);
  }
  function colorGame() {
    const { st, hs } = G, c = C();
    const page = st.pages[Math.min(1, st.pages.length - 1)];
    $('gameBody').innerHTML = `<h2>🎨 لوّن المشهد</h2><div class="canvas" id="paintBox">${lineArt(ART.page(page.s, '', hs))}</div>
      <div class="pal">${PAL.map((p) => `<button class="sw ${p === paint ? 'on' : ''}" style="background:${p}" onclick="Play.setPaint('${p}')" aria-label="لون"></button>`).join('')}</div>
      <div class="row" style="margin-top:12px"><button class="btn" onclick="Play.saveArt()">حفظ في معرضي 🖼️</button><button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div>`;
    $('paintBox').onclick = (e) => {
      const t = e.target.closest('.paintable'); if (!t) return;
      t.setAttribute('fill', paint);
    };
  }
  function setPaint(p) { paint = p; document.querySelectorAll('#gameBody .pal .sw').forEach((b) => b.classList.toggle('on', b.style.background && b.getAttribute('onclick').includes(p))); }
  function gallery() { try { return JSON.parse(localStorage.getItem('siraj-gallery') || '[]'); } catch (e) { return []; } }
  function saveArt() {
    const box = $('paintBox'); if (!box) return;
    const g = gallery(); g.unshift({ svg: box.innerHTML, t: Date.now(), s: G.st.id });
    try { localStorage.setItem('siraj-gallery', JSON.stringify(g.slice(0, 12))); } catch (e) {}
    logAct('color', G.st); C().toast('انحفظت في معرضك 🖼️'); closeGame(); renderPlay();
  }
  function delArt(i) { const g = gallery(); g.splice(i, 1); try { localStorage.setItem('siraj-gallery', JSON.stringify(g)); } catch (e) {} renderPlay(); }

  /* ---- أحجية ---- */
  function puzzleGame() {
    const { st, hs } = G, age = Math.max(...hs.map((k) => k.age || 2));
    const n = age <= 1 ? 2 : age === 2 ? 3 : 4;
    const page = st.pages[Math.min(2, st.pages.length - 1)];
    const svg = ART.page(page.s, page.p, hs).replace('preserveAspectRatio="xMidYMid slice"', 'preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg"');
    const url = "url('data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg).replace(/'/g, '%27') + "')";
    let order = [...Array(n * n).keys()];
    do { for (let i = order.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [order[i], order[j]] = [order[j], order[i]]; } } while (order.every((v, i) => v === i));
    G.p = { n, order, sel: -1, url, moves: 0 };
    drawPuzzle();
  }
  function drawPuzzle() {
    const { n, order, sel, url } = G.p, done = order.every((v, i) => v === i);
    $('gameBody').innerHTML = `<h2>🧩 أحجية الصورة</h2><p class="muted">${done ? '' : 'اضغط قطعتين عشان تبدّلهم'}</p>
      <div class="puzzle" style="grid-template-columns:repeat(${n},1fr)">${order.map((v, i) => `<button class="tile ${i === sel ? 'sel' : ''} ${done ? 'done' : ''}" onclick="Play.tile(${i})" style="background-image:${url};background-size:${n * 100}% ${n * 100}%;background-position:${(v % n) / (n - 1) * 100}% ${Math.floor(v / n) / (n - 1) * 100}%"></button>`).join('')}</div>
      ${done ? `<div class="celebrate">🎉 أحسنت! رتّبت الصورة في ${G.p.moves} حركة</div>` : ''}
      <div class="row" style="margin-top:12px">${done ? '<button class="btn" onclick="Play.open(\'puzzle\')">أحجية ثانية 🔁</button>' : ''}<button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div>`;
  }
  function tile(i) {
    const P = G.p; if (P.order.every((v, k) => v === k)) return;
    if (P.sel < 0) P.sel = i;
    else { [P.order[P.sel], P.order[i]] = [P.order[i], P.order[P.sel]]; P.sel = -1; P.moves++; if (P.order.every((v, k) => v === k)) logAct('puzzle', G.st, P.moves); }
    drawPuzzle();
  }

  /* ---- أسئلة ---- */
  const EMOJI_POOL = ['🚀', '🐢', '☕', '🌻', '⚽', '🐱', '🧸', '🍉', '🔦', '🏆', '📚', '🐦', '🎁', '🍦', '🚗', '🐑', '🎨', '🐝', '🔑', '🏰', '🌧️', '🦅', '🐟', '⛄'];
  function shuffle(a) { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }
  function quizGame() {
    const { st, hs } = G, c = C();
    const values = [...new Set(STORIES.map((s) => s.value))].filter((v) => v !== st.value);
    const scenes = Object.keys(SCENE_AR).filter((k) => k !== st.scene);
    const emo = [...new Set(st.pages.map((p) => p.p))].filter((e) => /\p{Extended_Pictographic}/u.test(e));
    const right = emo[Math.floor(Math.random() * emo.length)] || '🌙';
    const wrong = shuffle(EMOJI_POOL.filter((e) => !emo.includes(e))).slice(0, 2);
    G.q = { i: 0, score: 0, picked: null, list: shuffle([
      { q: `وش الشي الجميل اللي تعلّمناه في «${c.fill(st.title, hs)}»؟`, a: st.value, o: shuffle([st.value, ...shuffle(values).slice(0, 2)]) },
      { q: 'وين صارت أغلب أحداث القصة؟', a: SCENE_AR[st.scene], o: shuffle([SCENE_AR[st.scene], ...shuffle(scenes).slice(0, 2).map((k) => SCENE_AR[k])]) },
      { q: 'أي صورة من هذي ظهرت في القصة؟', a: right, o: shuffle([right, ...wrong]), big: true }
    ]) };
    drawQuiz();
  }
  function drawQuiz() {
    const Q = G.q, c = C();
    if (Q.i >= Q.list.length) {
      const stars = '⭐'.repeat(Q.score) + '☆'.repeat(Q.list.length - Q.score);
      $('gameBody').innerHTML = `<h2>❓ النتيجة</h2><div class="celebrate" style="font-size:34px">${stars}</div>
        <p class="ptext" style="color:var(--ink);text-align:center">${Q.score === 3 ? 'ممتاز! انتبهت للقصة كلها 🏆' : Q.score === 2 ? 'رائع! قربت توصل للكامل 👏' : 'حلو! اقرأ القصة مرة ثانية وجرّب 💪'}</p>
        <div class="row"><button class="btn" onclick="Play.open('quiz')">العب مرة ثانية 🔁</button><button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div>`;
      logAct('quiz', G.st, Q.score);
      return;
    }
    const it = Q.list[Q.i], ans = Q.picked != null;
    $('gameBody').innerHTML = `<h2>❓ سؤال ${Q.i + 1} من ${Q.list.length}</h2><p class="ptext" style="color:var(--ink)">${c.esc(it.q)}</p>
      <div class="opts ${it.big ? 'big' : ''}">${it.o.map((o, k) => `<button class="opt ${ans ? (o === it.a ? 'ok' : k === Q.picked ? 'no' : '') : ''}" ${ans ? 'disabled' : `onclick="Play.answer(${k})"`}>${c.esc(o)}</button>`).join('')}</div>
      ${ans ? `<p class="fb">${it.o[Q.picked] === it.a ? '✅ صح!' : '💡 الجواب الصح: ' + c.esc(it.a)}</p><button class="btn" onclick="Play.nextQ()">التالي ←</button>` : ''}`;
  }
  function answer(k) { const Q = G.q; Q.picked = k; if (Q.list[Q.i].o[k] === Q.list[Q.i].a) Q.score++; drawQuiz(); }
  function nextQ() { G.q.i++; G.q.picked = null; drawQuiz(); }

  /* ================= التسجيل بالصوت (يبقى على هذا الجهاز) ================= */
  let dbp = null;
  function db() {
    if (dbp) return dbp;
    dbp = new Promise((res, rej) => {
      const r = indexedDB.open('siraj-rec', 1);
      r.onupgradeneeded = () => r.result.createObjectStore('rec');
      r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error);
    });
    return dbp;
  }
  async function getRec(key) { try { const d = await db(); return await new Promise((res) => { const q = d.transaction('rec').objectStore('rec').get(key); q.onsuccess = () => res(q.result || null); q.onerror = () => res(null); }); } catch (e) { return null; } }
  async function putRec(key, val) { const d = await db(); return new Promise((res, rej) => { const t = d.transaction('rec', 'readwrite'); t.objectStore('rec').put(val, key); t.oncomplete = res; t.onerror = () => rej(t.error); }); }
  async function delRec(key) { const d = await db(); return new Promise((res) => { const t = d.transaction('rec', 'readwrite'); t.objectStore('rec').delete(key); t.oncomplete = res; }); }
  async function hasStoryRec(st) { const r = await getRec(st.id + ':0'); return r; }

  let mr = null, chunks = [], audio = null;
  const canRec = () => !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia && window.MediaRecorder);
  async function startRec(key, by) {
    if (!canRec()) return C().toast('هذا الجهاز ما يدعم التسجيل');
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      chunks = []; mr = new MediaRecorder(stream);
      mr.ondataavailable = (e) => e.data.size && chunks.push(e.data);
      mr.onstop = async () => {
        stream.getTracks().forEach((t) => t.stop());
        const blob = new Blob(chunks, { type: mr.mimeType || 'audio/webm' });
        await putRec(key, { blob, by, t: Date.now() });
        mr = null; App.recChanged();
      };
      mr.start(); App.recChanged();
    } catch (e) { C().toast('اسمح للمايك عشان تسجّل 🎙️'); }
  }
  function stopRec() { if (mr && mr.state !== 'inactive') mr.stop(); }
  const recording = () => !!(mr && mr.state === 'recording');
  function stopPlay() { if (audio) { audio.pause(); audio = null; } }
  async function playRec(key, onEnd) {
    stopPlay();
    const r = await getRec(key); if (!r) return false;
    audio = new Audio(URL.createObjectURL(r.blob));
    audio.onended = () => { audio = null; onEnd && onEnd(); };
    audio.play().catch(() => {});
    return r;
  }

  return { dayInfo, emptyDay, stkInfo, accInfo, renderSky, wear, celebrate, skyInfo, logAct, lastSticker, kidEvents, renderPlay, pickStory, setStory, open, closeGame, setPaint, saveArt, delArt, tile, answer, nextQ,
    getRec, delRec, startRec, stopRec, recording, playRec, stopPlay, canRec, hasStoryRec, acts };
})();

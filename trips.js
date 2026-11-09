/* سِراج | SIRAJ — رحلات حول العالم ✈️ (كل الرحلات من مطار الملك خالد الدولي بالرياض وترجع له) */
const Trips = (() => {
  const $ = (id) => document.getElementById(id);
  const C = () => App.ctx();
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  const DAYS = ['', 'يوم واحد', 'يومين', '٣ أيام', '٤ أيام', '٥ أيام', '٦ أيام', 'أسبوع كامل'];
  const DAYN = ['', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع'];
  const byCode = (c) => COUNTRIES.find((x) => x.c === c);
  let T = null, region = 'all', q = '';

  /* ---------- البيانات ---------- */
  function allTrips() {
    const c = C(), S = c.S(), seen = new Set(), out = [];
    const add = (t) => { if (!t || seen.has(t.id)) return; seen.add(t.id); out.push(t); };
    (S.trips || []).forEach(add); c.remote().filter((p) => p.dev !== S.dev).forEach((p) => (p.trips || []).forEach(add));
    let list = out.sort((a, b) => b.at - a.at);
    if (S.role === 'child') { const mine = c.myKids().map((k) => k.id); list = list.filter((t) => !t.k || !t.k.length || t.k.some((id) => mine.includes(id))); }
    return list;
  }
  function people() {
    const c = C(), S = c.S();
    return [...App.family().map((m) => ({ id: m.id, n: m.name, g: m.g, av: m.av, parent: m.parent })), ...(S.tripPeople || [])];
  }
  const PRESET = {
    boy: () => ({ ...ART.DEFAULTS.m }), girl: () => ({ ...ART.DEFAULTS.f }),
    man: () => ({ ...ART.DEFAULTS.m, outfit: 'thobe', head: 'shmagh' }), woman: () => ({ ...ART.DEFAULTS.f, head: 'hijab', outfit: 'dress', shirt: 5 })
  };
  function options(cn) {
    const inf = COUNTRY_INFO[cn.c];
    const gen = [['جولة في العاصمة ' + cn.cap, cn.sc === 'sea' ? 'sea' : 'road', '🏙️'], ['نتمشى في الطبيعة', cn.sc === 'desert' ? 'desert' : cn.sc === 'sea' ? 'sea' : 'garden', cn.sc === 'sea' ? '🏖️' : '🌳'],
      ['نزور المتحف الوطني', 'road', '🏛️'], ['نتسوّق من السوق الشعبي', 'souq', '🛍️'], ['نجرّب أكل البلد', 'market', '🍽️']];
    if (!inf) return gen;
    return [...inf.sights, ['نجرّب ' + inf.food, 'market', '🍽️'], gen[3]];
  }

  /* ---------- الصفحة الرئيسية للرحلات ---------- */
  function render() {
    const el = $('trips'); if (!el) return;
    const c = C(), S = c.S(), list = allTrips(), visited = [...new Set(list.map((t) => t.c))];
    const parent = S.role === 'parent';
    el.innerHTML = `<div class="card trhero"><div class="trplane">✈️</div><h2>رحلات حول العالم</h2>
      <p>${parent ? 'هنا كل الرحلات اللي سافرها العيال مع العائلة 🌍' : 'اختر مين يسافر معك، وين تروحون، وكم يوم… ويلا! 🌍'}</p>
      <small>🛫 كل الرحلات تطلع من مطار الملك خالد الدولي بالرياض</small>
      <button class="btn" onclick="Trips.start()">✈️ رحلة جديدة</button></div>
      <div class="trstats"><button class="card" onclick="Trips.passport()"><span>📕</span><b>${AR(visited.length)}</b><small>جوازي · ختم</small></button>
        <button class="card" onclick="Trips.game('flag')"><span>🚩</span><b>الأعلام</b><small>لعبة</small></button>
        <button class="card" onclick="Trips.game('cap')"><span>🏛️</span><b>العواصم</b><small>لعبة</small></button></div>
      <div class="card"><h3>🧳 ${parent ? 'سجل رحلات العيال' : 'رحلاتي'} <small>${AR(list.length)} رحلة</small></h3>
      ${list.length ? `<div class="trlog">${list.slice(0, 40).map((t) => tripRow(t)).join('')}</div>` : '<p class="muted" style="text-align:center">ما فيه رحلات للحين… أول رحلة وين بتكون؟ 🤔</p>'}</div>`;
  }
  function tripRow(t) {
    const cn = byCode(t.c) || { n: t.c, cap: '' }, c = C();
    const who = (t.k || []).map((id) => { const k = c.kidById(id); return k ? k.name : ''; }).filter(Boolean);
    return `<button class="trrow" onclick="Trips.album('${t.id}')"><span class="trflag">${flagOf(t.c)}</span><div><b>${cn.n}</b>
      <small>${DAYS[t.days] || AR(t.days) + ' أيام'} · ${new Date(t.at).toLocaleDateString('ar-SA-u-ca-gregory', { day: 'numeric', month: 'long' })}${who.length && c.S().role === 'parent' ? ' · رحلة ' + c.esc(who.join(' و')) : ''}</small>
      <i>${(t.people || []).slice(0, 5).map((p) => ART.avatarSVG(p.av, p.g, 30)).join('')}</i></div><em>←</em></button>`;
  }

  /* ---------- معالج الرحلة ---------- */
  const open = (html) => { $('gameBody').innerHTML = `<div class="trw">${html}</div>`; $('gameModal').classList.add('on'); $('gameBody').parentElement.scrollTop = 0; };
  function start() {
    const c = C(), mine = c.S().role === 'child' ? c.myKids().map((k) => k.id) : [];
    T = { step: 0, sel: new Set(mine), c: null, days: 3, d: 0, picks: [] };
    region = 'all'; q = ''; step();
  }
  function step() {
    if (!T) return;
    const fn = [stepPeople, stepPlace, stepDays, stepAirport, stepArrive, stepDay, stepHome][T.step];
    fn();
  }
  const dots = () => `<div class="trdots">${['👨‍👩‍👧‍👦', '🌍', '🗓️', '🛫'].map((e, i) => `<span class="${i <= Math.min(T.step, 3) ? 'on' : ''}">${e}</span>`).join('')}</div>`;

  function stepPeople() {
    const c = C(), ps = people();
    open(`${dots()}<h2>مين بيسافر؟ 🧳</h2><p class="muted">اختر المسافرين (تقدر تضيف شخصيات)</p>
      <div class="trppl">${ps.map((p) => `<button class="${T.sel.has(p.id) ? 'on' : ''}" onclick="Trips.toggle('${p.id}')">${ART.avatarSVG(p.av, p.g, 58)}<b>${c.esc(p.n)}</b>${String(p.id).startsWith('x') ? `<i onclick="event.stopPropagation();Trips.delPerson('${p.id}')">✕</i>` : ''}</button>`).join('')}
        <button class="add" onclick="Trips.addPerson()"><span>➕</span><b>شخصية</b></button></div>
      <button class="btn" ${T.sel.size ? '' : 'disabled style="opacity:.5"'} onclick="Trips.go(1)">التالي: وين نروح؟ 🌍</button>`);
  }
  function toggle(id) { T.sel.has(id) ? T.sel.delete(id) : T.sel.add(id); stepPeople(); }
  let newG = 'boy';
  function addPerson() {
    open(`<h2>➕ شخصية جديدة</h2><p class="muted">جدّو، تيتة، خالو، صديق…</p>
      <input class="inp" id="trName" maxlength="16" placeholder="الاسم" style="margin:10px 0">
      <div class="trtypes">${[['boy', 'ولد'], ['girl', 'بنت'], ['man', 'رجل'], ['woman', 'امرأة']].map(([k, n]) => `<button class="${newG === k ? 'on' : ''}" onclick="Trips.setType('${k}')">${ART.avatarSVG(PRESET[k](), /girl|woman/.test(k) ? 'f' : 'm', 54)}<b>${n}</b></button>`).join('')}</div>
      <div class="row" style="margin-top:14px"><button class="btn" onclick="Trips.savePerson()">أضفها ✓</button><button class="btn alt" onclick="Trips.go(0)">رجوع</button></div>`);
  }
  function setType(k) { const v = $('trName') ? $('trName').value : ''; newG = k; addPerson(); $('trName').value = v; }
  function savePerson() {
    const c = C(), S = c.S(), n = ($('trName').value || '').trim();
    if (!n) return c.toast('اكتب الاسم');
    const p = { id: 'x' + Date.now().toString(36), n, g: /girl|woman/.test(newG) ? 'f' : 'm', av: PRESET[newG]() };
    S.tripPeople = [...(S.tripPeople || []), p].slice(-12); c.save(); T.sel.add(p.id); go(0);
  }
  function delPerson(id) { const S = C().S(); S.tripPeople = (S.tripPeople || []).filter((p) => p.id !== id); T.sel.delete(id); C().save(); stepPeople(); }

  function stepPlace() {
    open(`${dots()}<h2>وين نروح؟ 🌍</h2>
      <input class="inp" id="trQ" placeholder="🔍 دوّر على دولة…" value="${C().esc(q)}" oninput="Trips.search(this.value)" style="margin:8px 0">
      <div class="trreg">${REGIONS.map(([k, n]) => `<button class="chip ${region === k ? 'on' : ''}" onclick="Trips.setRegion('${k}')">${n}</button>`).join('')}</div>
      <div class="trgrid" id="trGrid">${grid()}</div>
      <button class="btn alt" style="margin-top:12px" onclick="Trips.go(0)">→ رجوع</button>`);
  }
  function grid() {
    const qq = q.trim();
    const list = COUNTRIES.filter((x) => (region === 'all' || x.r === region) && (!qq || x.n.includes(qq) || x.cap.includes(qq)))
      .sort((a, b) => (COUNTRY_INFO[b.c] ? 1 : 0) - (COUNTRY_INFO[a.c] ? 1 : 0));
    return list.length ? list.map((x) => `<button onclick="Trips.pick('${x.c}')"><span>${flagOf(x.c)}</span><b>${x.n}</b>${COUNTRY_INFO[x.c] ? '<i>⭐</i>' : ''}</button>`).join('') : '<p class="muted">ما لقيت شي 🤔</p>';
  }
  function search(v) { q = v; $('trGrid').innerHTML = grid(); }
  function setRegion(k) { region = k; stepPlace(); }
  function pick(code) { T.c = code; go(2); }

  function travelers() { const ps = people(); return ps.filter((p) => T.sel.has(p.id)); }
  const heroesOf = (list) => list.map((p) => ({ av: p.av, g: p.g }));
  function stepDays() {
    const cn = byCode(T.c), inf = COUNTRY_INFO[T.c] || {}, tr = travelers(), c = C();
    open(`${dots()}<h2>كم يوم؟ 🗓️</h2>
      <div class="trdays">${[1, 2, 3, 4, 5, 6, 7].map((n) => `<button class="${T.days === n ? 'on' : ''}" onclick="Trips.setDays(${n})">${AR(n)}</button>`).join('')}</div>
      <div class="bpass"><div class="bph"><span>✈️ سِراج للطيران</span><span>بطاقة صعود</span></div>
        <div class="bpr"><div><small>من</small><b>RUH</b><em>الرياض 🇸🇦</em></div><div class="bpline">✈️</div><div><small>إلى</small><b>${flagOf(T.c)}</b><em>${cn.cap}، ${cn.n}</em></div></div>
        <div class="bpf"><span>🗓️ ${DAYS[T.days]}</span>${inf.h ? `<span>⏱️ ${AR(inf.h).replace('.', '٫')} ساعة طيران تقريبًا</span>` : ''}<span>👥 ${AR(tr.length)} ${tr.length === 1 ? 'مسافر' : 'مسافرين'}</span></div>
        <div class="bpp">${tr.map((p) => `<span>${ART.avatarSVG(p.av, p.g, 34)}<small>${c.esc(p.n)}</small></span>`).join('')}</div></div>
      <div class="row"><button class="btn" onclick="Trips.go(3)">للمطار 🛫</button><button class="btn alt" onclick="Trips.go(1)">غيّر الدولة</button></div>`);
  }
  function setDays(n) { T.days = n; stepDays(); }

  function stepAirport() {
    const cn = byCode(T.c), tr = travelers();
    open(`<h2>🛫 مطار الملك خالد الدولي</h2><p class="muted">الرياض · رحلة رقم SJ${AR(100 + (T.c.charCodeAt(0) * 7 + T.c.charCodeAt(1)) % 900)} إلى ${cn.n}</p>
      <div class="trart">${ART.page('road', '🛫', heroesOf(tr))}</div>
      <div class="flight" id="trFlight"><span class="f1">🇸🇦<small>الرياض</small></span><i></i><span class="pl">✈️</span><span class="f2">${flagOf(T.c)}<small>${cn.cap}</small></span></div>
      <p class="trsay" id="trSay">اربطوا الأحزمة… ونقول دعاء السفر 🤲</p>
      <button class="btn" id="trGo" onclick="Trips.fly()">انطلق ✈️</button>`);
  }
  function fly() {
    $('trFlight').classList.add('go'); $('trGo').disabled = true; $('trGo').style.opacity = '.5';
    const says = ['الطيارة طارت فوق الرياض 🌆', 'فوق الغيوم ☁️☁️', 'شوي ونوصل… 👀'];
    says.forEach((s, i) => setTimeout(() => { if ($('trSay')) $('trSay').textContent = s; }, 700 + i * 900));
    setTimeout(() => { if (T && T.step === 3) go(4); }, 3400);
  }
  function stepArrive() {
    const cn = byCode(T.c), inf = COUNTRY_INFO[T.c];
    open(`<div class="arrive"><div class="bigflag">${flagOf(T.c)}</div><h2>وصلنا ${cn.n}! 🎉</h2>
      ${inf ? `<p class="hi">يقولون هنا: <b>${inf.hi}</b></p>` : ''}
      <div class="facts"><div><span>🏛️</span><small>العاصمة</small><b>${cn.cap}</b></div>${inf ? `<div><span>🗣️</span><small>اللغة</small><b>${inf.lang}</b></div><div><span>💰</span><small>العملة</small><b>${inf.cur}</b></div><div><span>🍽️</span><small>أكلة مشهورة</small><b>${inf.food}</b></div>` : `<div><span>🌍</span><small>القارة</small><b>${(REGIONS.find((r) => r[0] === cn.r) || ['', ''])[1]}</b></div>`}</div>
      ${inf ? `<p class="fact">💡 هل تعرف؟ ${inf.fact}</p>` : ''}</div>
      <button class="btn" onclick="Trips.go(5)">نبدأ اليوم ${DAYN[1]} ☀️</button>`);
    T.d = 1;
  }
  function stepDay() {
    const cn = byCode(T.c), used = T.picks.map((p) => p[0]);
    let ops = options(cn).filter((o) => !used.includes(o[0])); if (!ops.length) ops = options(cn);
    open(`<h2>☀️ اليوم ${DAYN[T.d]} في ${cn.n}</h2><p class="muted">وش نسوي اليوم؟</p>
      <div class="trops">${ops.map((o) => `<button onclick="Trips.doAct('${options(cn).indexOf(o)}')"><span>${o[2]}</span><b>${o[0]}</b></button>`).join('')}</div>`);
  }
  function doAct(i) {
    const cn = byCode(T.c), o = options(cn)[+i], tr = travelers(), c = C(), last = T.d >= T.days;
    T.picks.push(o);
    open(`<div class="postcard"><div class="pcart">${ART.page(o[1], o[2], heroesOf(tr), 'idle')}<span class="pcstamp">${flagOf(T.c)}</span></div>
      <p><b>اليوم ${DAYN[T.d]}:</b> ${o[0]} ${o[2]}</p><small>${tr.map((p) => c.esc(p.n)).join(' و')} · ${cn.n}</small></div>
      <button class="btn" onclick="${last ? 'Trips.go(6)' : 'Trips.nextDay()'}">${last ? 'نرجع الرياض 🛬🇸🇦' : 'اليوم ' + DAYN[T.d + 1] + ' ☀️'}</button>`);
  }
  function nextDay() { T.d++; go(5); }
  function stepHome() {
    const c = C(), S = c.S(), cn = byCode(T.c), tr = travelers();
    const kidsIn = tr.filter((p) => !p.parent && !String(p.id).startsWith('x')).map((p) => p.id);
    const k = S.role === 'child' ? c.myKids().map((x) => x.id) : kidsIn;
    const trip = { id: 't' + Date.now().toString(36), c: T.c, days: T.days, at: Date.now(), k, people: tr.map((p) => ({ n: p.n, g: p.g, av: p.av })), picks: T.picks.map((p) => [p[0], p[1], p[2]]) };
    const first = !allTrips().some((t) => t.c === T.c);
    S.trips = [...(S.trips || []), trip].slice(-80); S.progDirty = true; c.save(); c.syncNow();
    try { Play.logAct('trip', { id: 'trip-' + T.c }); } catch (e) {}
    T = null;
    open(`<div class="arrive"><div class="trart">${ART.page('road', '🛬', heroesOf(tr))}</div><h2>الحمد لله على السلامة 🇸🇦</h2>
      <p>رجعنا الرياض من ${cn.n} ${flagOf(trip.c)}</p>
      <div class="stampnew"><span>${flagOf(trip.c)}</span><b>${cn.n}</b><small>${new Date().toLocaleDateString('ar-SA-u-ca-gregory', { day: 'numeric', month: 'short', year: 'numeric' })}</small></div>
      <p class="muted">${first ? 'ختم جديد في جوازك! 📕' : 'ختم ثاني لنفس الدولة 📕'} وانحفظت الرحلة في سجل الرحلات 🧳</p></div>
      <div class="row"><button class="btn" onclick="Trips.album('${trip.id}')">📸 ألبوم الرحلة</button><button class="btn alt" onclick="Play.closeGame();Trips.render()">تمام</button></div>`);
    render();
  }
  function go(n) { if (!T) return; T.step = n; step(); }

  /* ---------- الألبوم والجواز ---------- */
  function album(id) {
    const t = allTrips().find((x) => x.id === id); if (!t) return;
    const cn = byCode(t.c) || { n: t.c, cap: '' }, c = C(), h = heroesOf(t.people || []);
    open(`<h2>${flagOf(t.c)} رحلة ${cn.n}</h2><p class="muted">${DAYS[t.days] || ''} · ${new Date(t.at).toLocaleDateString('ar-SA-u-ca-gregory', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}</p>
      <div class="bpp" style="justify-content:center">${(t.people || []).map((p) => `<span>${ART.avatarSVG(p.av, p.g, 38)}<small>${c.esc(p.n)}</small></span>`).join('')}</div>
      <div class="albm">${(t.picks || []).map((p, i) => `<div class="postcard"><div class="pcart">${ART.page(p[1], p[2], h)}</div><p><b>اليوم ${DAYN[i + 1] || AR(i + 1)}:</b> ${p[0]} ${p[2]}</p></div>`).join('')}</div>
      <button class="btn alt" onclick="Play.closeGame()">إغلاق</button>`);
  }
  function passport() {
    const list = allTrips(), map = {};
    list.forEach((t) => { map[t.c] = map[t.c] || { n: 0, at: t.at }; map[t.c].n++; map[t.c].at = Math.min(map[t.c].at, t.at); });
    const codes = Object.keys(map).sort((a, b) => map[a].at - map[b].at);
    open(`<div class="passport"><div class="pph">🇸🇦<b>جواز سفر سِراج</b><small>زرت ${AR(codes.length)} من ${AR(COUNTRIES.length)} دولة</small></div>
      <i class="ppbar"><b style="width:${Math.max(2, Math.round(codes.length / COUNTRIES.length * 100))}%"></b></i>
      <div class="stamps">${codes.length ? codes.map((cd, i) => `<div class="stamp" style="--r:${(i * 37) % 24 - 12}deg"><span>${flagOf(cd)}</span><b>${(byCode(cd) || { n: cd }).n}</b><small>${map[cd].n > 1 ? '×' + AR(map[cd].n) : new Date(map[cd].at).toLocaleDateString('ar-SA-u-ca-gregory', { day: 'numeric', month: 'short' })}</small></div>`).join('') : '<p class="muted">الجواز فاضي… سافر وخذ أول ختم ✈️</p>'}</div></div>
      <button class="btn alt" onclick="Play.closeGame()">إغلاق</button>`);
  }

  /* ---------- لعبة الأعلام والعواصم ---------- */
  let G = null;
  const shuffle = (a) => { a = [...a]; for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  function game(kind) {
    // نبدأ بالدول المشهورة والدول اللي زارها، وبعدين الباقي
    const visited = new Set(allTrips().map((t) => t.c));
    const easy = COUNTRIES.filter((x) => COUNTRY_INFO[x.c] || visited.has(x.c) || x.r === 'gcc' || x.r === 'arab');
    const pool = shuffle(easy).slice(0, 7).concat(shuffle(COUNTRIES.filter((x) => !easy.includes(x))).slice(0, 3));
    G = { kind, qs: pool, i: 0, ok: 0 }; gq();
  }
  function gq() {
    if (G.i >= G.qs.length) return gEnd();
    const a = G.qs[G.i], wrong = shuffle(COUNTRIES.filter((x) => x.c !== a.c && (x.r === a.r || Math.random() < .3))).slice(0, 3);
    const ops = shuffle([a, ...wrong]);
    open(`<div class="tgame"><p class="muted">${G.kind === 'flag' ? '🚩 لعبة الأعلام' : '🏛️ لعبة العواصم'} · سؤال ${AR(G.i + 1)} من ${AR(G.qs.length)} · ⭐ ${AR(G.ok)}</p>
      ${G.kind === 'flag' ? `<div class="bigflag">${flagOf(a.c)}</div><h2>علم أي دولة؟</h2>` : `<div class="bigflag">${flagOf(a.c)}</div><h2>وش عاصمة ${a.n}؟</h2>`}
      <div class="tops">${ops.map((o) => `<button onclick="Trips.ans(this,'${o.c}')" data-c="${o.c}">${G.kind === 'flag' ? o.n : o.cap}</button>`).join('')}</div></div>`);
  }
  function ans(btn, code) {
    const a = G.qs[G.i], box = btn.parentElement; if (box.dataset.done) return; box.dataset.done = 1;
    const ok = code === a.c; if (ok) G.ok++;
    box.querySelectorAll('button').forEach((b) => b.classList.add(b.dataset.c === a.c ? 'ok' : b === btn ? 'no' : 'dim'));
    box.insertAdjacentHTML('afterend', `<p class="trsay">${ok ? 'صح! 🎉' : 'الجواب: ' + (G.kind === 'flag' ? a.n : a.cap)}${G.kind === 'flag' ? ' · عاصمتها ' + a.cap : ''}</p>`);
    const g = G; setTimeout(() => { if (G !== g || !$('gameModal').classList.contains('on')) return; G.i++; gq(); }, ok ? 1100 : 2000);
  }
  function gEnd() {
    const n = G.ok, tot = G.qs.length;
    try { Play.logAct('flags', { id: 'flags-' + G.kind }, n); } catch (e) {}
    open(`<div class="tgame"><div class="bigflag">${n >= 8 ? '🏆' : n >= 5 ? '🌟' : '💪'}</div><h2>${AR(n)} من ${AR(tot)}</h2><p>${n >= 8 ? 'يا سلام! أنت مستكشف عالمي 🌍' : n >= 5 ? 'حلو مرة! كمّل وتصير خبير ✨' : 'كل مرة تلعب تتعلم أكثر 💪'}</p></div>
      <div class="row"><button class="btn" onclick="Trips.game('${G.kind}')">مرة ثانية 🔁</button><button class="btn alt" onclick="Trips.game('${G.kind === 'flag' ? 'cap' : 'flag'}')">${G.kind === 'flag' ? '🏛️ العواصم' : '🚩 الأعلام'}</button></div>`);
  }

  return { render, start, toggle, go, addPerson, setType, savePerson, delPerson, search, setRegion, pick, setDays, fly, doAct, nextDay, album, passport, game, ans, allTrips };
})();

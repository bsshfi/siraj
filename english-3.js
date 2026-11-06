/* سِراج | SIRAJ — الدفعة ٣ (إنجليزي): أصوات الحروف، تتبّع الحرف بالإصبع، عائلات الكلمات، كلمات سريعة، النطق بالمايك، وقصة الأسبوع */
const EN2 = (() => {
  const $ = (id) => document.getElementById(id);
  const C = () => App.ctx();
  const L = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  const SND = { A: 'ah', B: 'buh', C: 'kuh', D: 'duh', E: 'eh', F: 'fff', G: 'guh', H: 'hah', I: 'ih', J: 'juh', K: 'kuh', L: 'lll', M: 'mmm', N: 'nnn', O: 'aw', P: 'puh', Q: 'kwuh', R: 'rrr', S: 'sss', T: 'tuh', U: 'uh', V: 'vvv', W: 'wuh', X: 'ks', Y: 'yuh', Z: 'zzz' };
  const EX = { A: ['apple', '🍎'], B: ['ball', '⚽'], C: ['cat', '🐱'], D: ['dog', '🐶'], E: ['egg', '🥚'], F: ['fish', '🐟'], G: ['goat', '🐐'], H: ['hat', '🎩'], I: ['igloo', '🛖'], J: ['juice', '🧃'], K: ['kite', '🪁'], L: ['lion', '🦁'], M: ['moon', '🌙'], N: ['nest', '🪺'], O: ['octopus', '🐙'], P: ['pen', '🖊️'], Q: ['queen', '👑'], R: ['rabbit', '🐰'], S: ['sun', '☀️'], T: ['tree', '🌳'], U: ['umbrella', '☂️'], V: ['van', '🚐'], W: ['water', '💧'], X: ['box', '📦'], Y: ['yo-yo', '🪀'], Z: ['zebra', '🦓'] };
  const FAM = {
    '-at': [['cat', '🐱'], ['hat', '🎩'], ['bat', '🦇'], ['mat', '🧘'], ['rat', '🐀']],
    '-an': [['can', '🥫'], ['fan', '🪭'], ['man', '👨'], ['pan', '🍳'], ['van', '🚐']],
    '-ig': [['big', '🐘'], ['pig', '🐷'], ['wig', '💇'], ['dig', '⛏️'], ['fig', '🫐']],
    '-op': [['top', '🔝'], ['mop', '🧹'], ['hop', '🐸'], ['pop', '🎈'], ['shop', '🏪']],
    '-ug': [['bug', '🐛'], ['hug', '🤗'], ['mug', '☕'], ['rug', '🟫'], ['jug', '🏺']],
    '-en': [['ten', '🔟'], ['hen', '🐔'], ['pen', '🖊️'], ['men', '👨‍👨‍👦'], ['den', '🏠']]
  };
  const SIGHT = ['the', 'and', 'is', 'you', 'I', 'we', 'it', 'he', 'she', 'they', 'look', 'come', 'go', 'see', 'can', 'my', 'like', 'play', 'said', 'here', 'what', 'where', 'this', 'that', 'yes', 'no', 'big', 'little', 'up', 'down'];
  const say = (t, r) => EN.say(t, r);
  function show(html) { $('gameBody').innerHTML = `<div class="encard">${html}</div>`; $('gameModal').classList.add('on'); }
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);

  /* ---- أصوات الحروف ---- */
  function phonics() {
    show(`<h2>🗣️ أصوات الحروف</h2><p class="muted">كل حرف له صوت! اضغط واسمع</p>
      <div class="letters">${L.map((l) => `<button class="lt" onclick="EN2.ph('${l}')"><b>${l}<small>${l.toLowerCase()}</small></b><span>${EX[l][1]}</span></button>`).join('')}</div>`);
  }
  function ph(l) { const e = EX[l]; say(`${SND[l]}. ${SND[l]}. ${e[0]}`); const el = document.querySelector('#gameBody .phbig'); const h = `<div class="phbig"><b>${l}${l.toLowerCase()}</b><span>${e[1]}</span><p dir="ltr"><em>${l.toLowerCase()}</em> says “${SND[l]}” as in <b>${e[0]}</b></p></div>`; if (el) el.outerHTML = h; else $('gameBody').querySelector('.encard').insertAdjacentHTML('afterbegin', h); }

  /* ---- تتبّع الحرف بالإصبع ---- */
  let T = null;
  function trace(i) {
    i = i == null ? 0 : i; const l = L[i % 26], low = T && T.low;
    T = { i: i % 26, low: !!low, mask: null, paint: null, done: false };
    show(`<h2>✍️ تتبّع الحرف</h2><p class="muted">مرّر إصبعك فوق الحرف الباهت</p>
      <div class="trbox"><canvas id="trc" width="300" height="300"></canvas></div><p class="fb" id="trfb"></p>
      <div class="row"><button class="btn alt" onclick="EN2.trace(${(i + 25) % 26})">→</button><button class="btn alt" onclick="EN2.trCase()">${T.low ? 'ABC' : 'abc'}</button><button class="btn alt" onclick="EN2.trace(${i})">🧽 امسح</button><button class="btn alt" onclick="EN2.trace(${(i + 1) % 26})">←</button></div>`);
    const cv = $('trc'), g = cv.getContext('2d'), ch = T.low ? l.toLowerCase() : l;
    const m = document.createElement('canvas'); m.width = m.height = 300; const mg = m.getContext('2d');
    mg.font = '800 250px Arial, sans-serif'; mg.textAlign = 'center'; mg.textBaseline = 'middle'; mg.fillText(ch, 150, 160);
    T.mask = mg.getImageData(0, 0, 300, 300).data;
    g.font = '800 250px Arial, sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillStyle = '#E6E0F5'; g.fillText(ch, 150, 160);
    g.setLineDash([8, 10]); g.lineWidth = 3; g.strokeStyle = '#B7AEDB'; g.strokeText(ch, 150, 160); g.setLineDash([]);
    g.lineCap = g.lineJoin = 'round'; g.lineWidth = 26; g.strokeStyle = '#F2851E';
    const pc = document.createElement('canvas'); pc.width = pc.height = 300; const pg = pc.getContext('2d'); pg.lineCap = pg.lineJoin = 'round'; pg.lineWidth = 26; pg.strokeStyle = '#000'; T.paint = pg;
    let last = null;
    const pos = (e) => { const r = cv.getBoundingClientRect(), t = e.touches ? e.touches[0] : e; return [(t.clientX - r.left) * 300 / r.width, (t.clientY - r.top) * 300 / r.height]; };
    const down = (e) => { e.preventDefault(); last = pos(e); };
    const move = (e) => { if (!last) return; e.preventDefault(); const p = pos(e); [g, pg].forEach((x) => { x.beginPath(); x.moveTo(...last); x.lineTo(...p); x.stroke(); }); last = p; };
    const up = () => { if (last) check(); last = null; };
    cv.addEventListener('pointerdown', down); cv.addEventListener('pointermove', move); cv.addEventListener('pointerup', up); cv.addEventListener('pointerleave', up);
    cv.style.touchAction = 'none';
    say(T.low ? l.toLowerCase() : l);
  }
  function trCase() { const i = T ? T.i : 0; T = { low: !(T && T.low) }; trace(i); }
  function check() {
    if (!T || T.done) return;
    const p = T.paint.getImageData(0, 0, 300, 300).data, m = T.mask; let mk = 0, hit = 0, pt = 0, out = 0;
    for (let i = 3; i < m.length; i += 16) { const a = m[i] > 100, b = p[i] > 100; if (a) mk++; if (b) pt++; if (a && b) hit++; if (b && !a) out++; }
    const cov = mk ? hit / mk : 0, fb = $('trfb');
    if (cov > 0.62 && out / Math.max(1, pt) < 0.55) { T.done = true; fb.innerHTML = '🌟 أحسنت! كتبت الحرف صح'; say('Great job!'); Play.logAct('en', { id: 'en-trace' }, 5); }
    else if (fb) fb.textContent = cov > 0.3 ? 'كمّل… باقي شوي ✍️' : '';
  }

  /* ---- عائلات الكلمات + الكلمات السريعة ---- */
  function families() {
    show(`<h2>👪 عائلات الكلمات</h2><p class="muted">كلمات تنتهي بنفس الصوت. اضغط واسمع</p>
      ${Object.entries(FAM).map(([k, ws]) => `<div class="famrow"><b dir="ltr">${k}</b><div>${ws.map(([w, e]) => `<button onclick="EN.say('${w}')"><span>${e}</span><i dir="ltr">${w.replace(k.slice(1), `<u>${k.slice(1)}</u>`)}</i></button>`).join('')}</div></div>`).join('')}
      <button class="btn" onclick="EN2.famGame()">🎧 لعبة: اسمع واختار</button>`);
  }
  let G = null;
  const shuf = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  function famGame() { const all = Object.values(FAM).flat(); G = { qs: shuf(all).slice(0, 6).map((w) => { const fam = Object.values(FAM).find((f) => f.includes(w)); return { a: w[0], o: shuf([w, ...shuf(fam.filter((x) => x !== w)).slice(0, 2)]) }; }), i: 0, sc: 0, pk: null, kind: 'fam' }; drawG(); }
  function sightGame() { G = { qs: shuf(SIGHT).slice(0, 8).map((w) => ({ a: w, o: shuf([w, ...shuf(SIGHT.filter((x) => x !== w)).slice(0, 3)]).map((x) => [x, '']) })), i: 0, sc: 0, pk: null, kind: 'sight' }; drawG(); }
  function drawG() {
    const it = G.qs[G.i];
    if (!it) { show(`<h2>${G.sc >= G.qs.length - 1 ? '🌟 ممتاز!' : '👏 أحسنت!'}</h2><div class="celebrate" style="font-size:26px">${'⭐'.repeat(Math.round(G.sc * 5 / G.qs.length))}</div><button class="btn" onclick="EN2.${G.kind === 'fam' ? 'famGame' : 'sightGame'}()">مرة ثانية 🔁</button>`); Play.logAct('en', { id: 'en-' + G.kind }, Math.round(G.sc * 5 / G.qs.length)); return; }
    const ans = G.pk != null;
    show(`<h2>${G.kind === 'fam' ? '👪 اسمع واختار' : '👀 كلمات سريعة'} <small class="muted">${AR(G.i + 1)}/${AR(G.qs.length)}</small></h2><p class="ptext" style="color:var(--ink)">وين كلمة اللي سمعتها؟</p>
      <button class="btn alt" onclick="EN.say('${it.a}')">🔊 اسمع</button>
      <div class="opts en big">${it.o.map(([w, e], k) => `<button class="opt ${ans ? (w === it.a ? 'ok' : k === G.pk ? 'no' : '') : ''}" ${ans ? 'disabled' : `onclick="EN2.ans(${k})"`}>${e ? e + ' ' : ''}${w}</button>`).join('')}</div>
      ${ans ? `<button class="btn" onclick="EN2.nx()">التالي ←</button>` : ''}`);
    if (!ans) setTimeout(() => say(it.a), 250);
  }
  function ans(k) { const it = G.qs[G.i]; G.pk = k; if (it.o[k][0] === it.a) G.sc++; drawG(); }
  function nx() { G.i++; G.pk = null; drawG(); }
  function sight() {
    show(`<h2>👀 كلمات سريعة</h2><p class="muted">كلمات نشوفها كثير في القراءة. احفظها بالشكل!</p>
      <div class="sight">${SIGHT.map((w) => `<button onclick="EN.say('${w}')" dir="ltr">${w}</button>`).join('')}</div>
      <button class="btn" onclick="EN2.sightGame()">🎯 لعبة: اسمع واختار</button>`);
  }

  /* ---- النطق بالمايك ---- */
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  function speakList() {
    const v = Object.values(EN_ADV.VOCAB).flat().map((w) => w[3]).filter((x) => x.split(' ').length <= 8);
    const sents = shuf(v).slice(0, 8);
    return `<p class="muted">اضغط 🎤 واقرأ الجملة بصوت واضح، والتطبيق يقول لك كم نطقك صح ✨</p>
      ${SR ? '' : '<p class="fb">⚠️ هذا الجهاز أو المتصفح ما يدعم التعرّف على الصوت. جرّب Chrome أو Safari.</p>'}
      <div class="vlist">${sents.map((x, i) => `<button class="vrow" onclick="EN2.spk(${i})" data-s="${x.replace(/"/g, '&quot;')}"><span>🎤</span><div><b>${x}</b></div></button>`).join('')}</div>`;
  }
  let rec = null;
  function spk(i) {
    const s = document.querySelectorAll('.vrow[data-s]')[i].dataset.s;
    show(`<h2>🎤 انطق الجملة</h2><p class="gq">${s}</p><button class="btn alt" onclick="EN.say('${s.replace(/'/g, "\\'")}')">🔊 اسمعها أول</button>
      <button class="mic" id="micBtn" onclick="EN2.listen('${s.replace(/'/g, "\\'")}')">🎤</button><p class="muted" id="micMsg">اضغط المايك وتكلّم</p><div id="micRes"></div>`);
  }
  const norm = (t) => t.toLowerCase().replace(/[^a-z' ]/g, ' ').split(/\s+/).filter(Boolean);
  function listen(target) {
    if (!SR) { $('micMsg').textContent = 'الجهاز ما يدعم التعرّف على الصوت 😔'; return; }
    try { if (rec) rec.abort(); } catch (e) {}
    rec = new SR(); rec.lang = 'en-US'; rec.interimResults = false; rec.maxAlternatives = 3;
    $('micBtn').classList.add('on'); $('micMsg').textContent = 'أسمعك… 👂';
    rec.onresult = (e) => {
      const alts = Array.from(e.results[0]).map((r) => r.transcript), tw = norm(target);
      let best = 0, heard = alts[0] || '';
      alts.forEach((a) => { const hw = norm(a); const sc = tw.filter((w) => hw.includes(w)).length / tw.length; if (sc > best) { best = sc; heard = a; } });
      const pct = Math.round(best * 100), hw = norm(heard);
      $('micRes').innerHTML = `<p class="mres">${tw.map((w) => `<span class="${hw.includes(w) ? 'ok' : 'no'}">${w}</span>`).join(' ')}</p>
        <p class="fb">${pct >= 80 ? '🌟 نطق ممتاز!' : pct >= 50 ? '👍 قريب! جرّب مرة ثانية' : '💪 خلنا نحاول مرة ثانية'} (${AR(pct)}٪)</p><p class="muted" dir="ltr">I heard: “${heard}”</p>`;
      if (pct >= 80) Play.logAct('en', { id: 'en-speak' }, 5);
    };
    rec.onerror = (e) => { $('micMsg').textContent = e.error === 'not-allowed' ? 'اسمح للتطبيق يستخدم المايك من الإعدادات 🎤' : 'ما سمعت زين، جرّب مرة ثانية'; };
    rec.onend = () => { const b = $('micBtn'); if (b) b.classList.remove('on'); const m = $('micMsg'); if (m && m.textContent.startsWith('أسمعك')) m.textContent = 'اضغط المايك وتكلّم'; };
    rec.start();
  }

  /* ---- قصة الأسبوع بالإنجليزي ---- */
  function weekly() {
    const R = EN_ADV.READ, wk = Math.floor((Date.now() / 864e5 + 4) / 7), i = wk % R.length, r = R[i];
    return `<button class="card weekly" onclick="EN.reading(${i})"><span>${r.e}</span><div><small>🌙 قصة الأسبوع بالإنجليزي</small><b dir="ltr">${r.t}</b><em>اقرأها مع ${C().S().fam.dad || 'بابا'} قبل النوم، ومعها الترجمة</em></div></button>`;
  }

  return { phonics, ph, trace, trCase, families, famGame, sightGame, sight, ans, nx, speakList, spk, listen, weekly };
})();

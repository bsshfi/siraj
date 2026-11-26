/* سِراج | SIRAJ — تعلّم الإنجليزي: حروف (٣-٥)، كلمات وجمل (٦-٨)، متقدّم (٩-١٢: قراءة، مفردات، قواعد، محادثات، إملاء) */
const EN = (() => {
  const $ = (id) => document.getElementById(id);
  const C = () => App.ctx();

  const LETTERS = [
    ['A', 'Apple', 'تفاحة', '🍎'], ['B', 'Ball', 'كرة', '⚽'], ['C', 'Cat', 'قطة', '🐱'], ['D', 'Dog', 'كلب', '🐶'], ['E', 'Egg', 'بيضة', '🥚'],
    ['F', 'Fish', 'سمكة', '🐟'], ['G', 'Grapes', 'عنب', '🍇'], ['H', 'Hat', 'قبعة', '🎩'], ['I', 'Ice cream', 'آيس كريم', '🍦'], ['J', 'Juice', 'عصير', '🧃'],
    ['K', 'Kite', 'طائرة ورقية', '🪁'], ['L', 'Lion', 'أسد', '🦁'], ['M', 'Moon', 'قمر', '🌙'], ['N', 'Nose', 'أنف', '👃'], ['O', 'Orange', 'برتقال', '🍊'],
    ['P', 'Pen', 'قلم', '🖊️'], ['Q', 'Queen', 'ملكة', '👸'], ['R', 'Rabbit', 'أرنب', '🐰'], ['S', 'Sun', 'شمس', '☀️'], ['T', 'Tree', 'شجرة', '🌳'],
    ['U', 'Umbrella', 'مظلة', '☂️'], ['V', 'Van', 'سيارة فان', '🚐'], ['W', 'Water', 'ماء', '💧'], ['X', 'Box', 'صندوق', '📦'], ['Y', 'Yo-yo', 'يويو', '🪀'], ['Z', 'Zebra', 'حمار وحشي', '🦓']
  ];
  const WORDS = {
    'الألوان 🎨': [['red', 'أحمر', '🔴'], ['blue', 'أزرق', '🔵'], ['green', 'أخضر', '🟢'], ['yellow', 'أصفر', '🟡'], ['orange', 'برتقالي', '🟠'], ['purple', 'بنفسجي', '🟣'], ['black', 'أسود', '⚫'], ['white', 'أبيض', '⚪']],
    'الأرقام 🔢': [['one', 'واحد', '1️⃣'], ['two', 'اثنان', '2️⃣'], ['three', 'ثلاثة', '3️⃣'], ['four', 'أربعة', '4️⃣'], ['five', 'خمسة', '5️⃣'], ['six', 'ستة', '6️⃣'], ['seven', 'سبعة', '7️⃣'], ['eight', 'ثمانية', '8️⃣'], ['nine', 'تسعة', '9️⃣'], ['ten', 'عشرة', '🔟']],
    'الحيوانات 🐾': [['cat', 'قطة', '🐱'], ['dog', 'كلب', '🐶'], ['bird', 'طائر', '🐦'], ['horse', 'حصان', '🐴'], ['cow', 'بقرة', '🐄'], ['sheep', 'خروف', '🐑'], ['camel', 'جمل', '🐪'], ['elephant', 'فيل', '🐘'], ['lion', 'أسد', '🦁'], ['fish', 'سمكة', '🐟']],
    'العائلة 👨‍👩‍👧': [['mom', 'أم', '👩'], ['dad', 'أب', '👨'], ['brother', 'أخ', '👦'], ['sister', 'أخت', '👧'], ['baby', 'رضيع', '👶'], ['grandma', 'جدة', '👵'], ['grandpa', 'جد', '👴']],
    'الأكل 🍽️': [['bread', 'خبز', '🍞'], ['milk', 'حليب', '🥛'], ['apple', 'تفاحة', '🍎'], ['banana', 'موز', '🍌'], ['rice', 'رز', '🍚'], ['water', 'ماء', '💧'], ['egg', 'بيضة', '🥚'], ['cake', 'كعكة', '🍰']],
    'الجسم 🖐️': [['eye', 'عين', '👁️'], ['ear', 'أذن', '👂'], ['nose', 'أنف', '👃'], ['mouth', 'فم', '👄'], ['hand', 'يد', '✋'], ['foot', 'قدم', '🦶'], ['tooth', 'سن', '🦷']],
    'البيت والمدرسة 🏠': [['book', 'كتاب', '📖'], ['bag', 'حقيبة', '🎒'], ['door', 'باب', '🚪'], ['bed', 'سرير', '🛏️'], ['chair', 'كرسي', '🪑'], ['pencil', 'قلم رصاص', '✏️'], ['house', 'بيت', '🏠'], ['car', 'سيارة', '🚗']]
  };
  const SENT = [
    ['Good morning!', 'صباح الخير!', '☀️'], ['Good night!', 'تصبح على خير!', '🌙'], ['My name is {n}.', 'اسمي {n}.', '🙋'], ['How are you?', 'كيف حالك؟', '🙂'],
    ['I am fine, thank you.', 'أنا بخير، شكرًا.', '😊'], ['Thank you!', 'شكرًا!', '🙏'], ['I love my family.', 'أحب عائلتي.', '❤️'], ['This is my cat.', 'هذه قطتي.', '🐱'],
    ['The sun is hot.', 'الشمس حارة.', '☀️'], ['I can read.', 'أستطيع القراءة.', '📖'], ['I like apples.', 'أحب التفاح.', '🍎'], ['Where is my bag?', 'أين حقيبتي؟', '🎒'],
    ['The ball is red.', 'الكرة حمراء.', '⚽'], ['Let us play!', 'هيا نلعب!', '🎈'], ['I drink milk.', 'أشرب الحليب.', '🥛'], ['The bird can fly.', 'الطائر يستطيع الطيران.', '🐦'],
    ['Open the door, please.', 'افتح الباب من فضلك.', '🚪'], ['I go to school.', 'أذهب إلى المدرسة.', '🏫'], ['It is raining.', 'إنها تمطر.', '🌧️'], ['I see the moon.', 'أرى القمر.', '🌙'],
    ['My mom is kind.', 'أمي طيبة.', '👩'], ['We are a family.', 'نحن عائلة.', '👨‍👩‍👧'], ['I brush my teeth.', 'أفرّش أسناني.', '🪥'], ['Wash your hands.', 'اغسل يديك.', '🧼'],
    ['The camel is big.', 'الجمل كبير.', '🐪'], ['I am sleepy.', 'أنا نعسان.', '😴'], ['I have a red pen.', 'عندي قلم أحمر.', '🖊️'], ['The cake is sweet.', 'الكعكة حلوة.', '🍰']
  ];

  const A = typeof EN_ADV !== 'undefined' ? EN_ADV : { READ: [], VOCAB: {}, GRAM: [], DLG: [] };
  let level = null, cat = Object.keys(WORDS)[0], G = null, sub = 'read', vcat = Object.keys(A.VOCAB)[0];
  const name = () => { const k = C().heroes()[0] || C().myKids()[0]; return k ? k.name : 'Sara'; };
  const nm = (s) => s.replace(/\{n\}/g, name());
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };

  /* نطق إنجليزي بصوت الجهاز */
  function enVoice() { const v = 'speechSynthesis' in window ? speechSynthesis.getVoices() : []; return v.find((x) => /^en[-_]US/i.test(x.lang)) || v.find((x) => /^en/i.test(x.lang)); }
  function say(text) {
    if (!('speechSynthesis' in window)) return;
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text), v = enVoice();
    if (v) u.voice = v; u.lang = v ? v.lang : 'en-US'; u.rate = 0.8; u.pitch = 1.1;
    speechSynthesis.speak(u);
  }

  function defLevel() { const k = C().heroes()[0] || C().myKids()[0]; return !k ? 'letters' : k.age >= 3 ? 'adv' : k.age === 2 ? 'words' : 'letters'; }
  function render() {
    const c = C();
    if (c.isNight()) {
      $('eng').innerHTML = `<div class="card nightcard"><div style="font-size:64px">😴</div><h2>Good night!</h2><p class="muted">الإنجليزي نام، ويرجع الصبح ☀️</p><button class="btn" onclick="App.tab('tonight')">قصة الليلة 🌙</button></div>`;
      return;
    }
    level = level || defLevel();
    const lv = [['letters', '🔤 حروف', '٣-٥'], ['words', '🧩 كلمات', '٦-٨'], ['sent', '💬 جمل', '٦-٩'], ['adv', '🚀 متقدّم', '٩-١٢']];
    let body = '';
    if (level === 'letters') {
      body = `<div class="card"><h2>حروف الإنجليزي 🔤</h2><p class="muted">اضغط الحرف واسمعه</p>
        <div class="letters">${LETTERS.map((l, i) => `<button class="lt" onclick="EN.letter(${i})"><b>${l[0]}<small>${l[0].toLowerCase()}</small></b><span>${l[3]}</span></button>`).join('')}</div>
        <button class="btn" style="margin-top:12px" onclick="EN.game('letters')">🎯 لعبة: وين الحرف؟</button></div>`;
    } else if (level === 'words') {
      body = `<div class="card"><h2>كلمات إنجليزي 🧩</h2>
        <div class="chips libchips">${Object.keys(WORDS).map((k) => `<button class="chip ${k === cat ? 'on' : ''}" onclick="EN.setCat('${k}')">${k}</button>`).join('')}</div>
        <div class="words">${WORDS[cat].map((w, i) => `<button class="wd" onclick="EN.word(${i})"><span>${w[2]}</span><b>${w[0]}</b><small>${w[1]}</small></button>`).join('')}</div>
        <button class="btn" style="margin-top:12px" onclick="EN.game('words')">🎧 لعبة: اسمع واختار</button></div>`;
    } else if (level === 'adv') {
      body = advBody(c);
    } else {
      body = `<div class="card"><h2>جمل إنجليزي 💬</h2><p class="muted">اضغط الجملة واسمعها</p>
        <div class="sents">${SENT.map((x, i) => `<button class="sn" onclick="EN.sent(${i})"><span>${x[2]}</span><div><b dir="ltr">${c.esc(nm(x[0]))}</b><small>${c.esc(nm(x[1]))}</small></div></button>`).join('')}</div>
        <div class="row" style="margin-top:12px"><button class="btn" onclick="EN.game('mean')">❓ وش معناها؟</button><button class="btn alt" onclick="EN.game('build')">🧱 رتّب الجملة</button></div></div>`;
    }
    $('eng').innerHTML = `<div class="seg enlv">${lv.map(([v, t, a]) => `<button class="${v === level ? 'on' : ''}" onclick="EN.setLevel('${v}')">${t}<small>${a}</small></button>`).join('')}</div>${body}`;
  }
  /* ---- المستوى المتقدّم ---- */
  const SUBS = [['read', '📖 قراءة'], ['vocab', '🧠 مفردات'], ['gram', '📐 قواعد'], ['dlg', '💬 محادثات'], ['spell', '🎧 إملاء']];
  const LV = ['', '⭐', '⭐⭐', '⭐⭐⭐'];
  const q1 = (t) => t.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '&quot;');
  function advBody(c) {
    const tabs = `<div class="ensub">${SUBS.map(([v, t]) => `<button class="chip ${v === sub ? 'on' : ''}" onclick="EN.setSub('${v}')">${t}</button>`).join('')}</div>`;
    let x = '';
    if (sub === 'read') x = `<p class="muted">اقرأ القصة، اضغط أي جملة واسمعها، وبعدين جاوب الأسئلة</p>
      <div class="rlist">${A.READ.map((r, i) => `<button class="rcard" onclick="EN.reading(${i})"><span>${r.e}</span><b>${c.esc(r.t)}</b><small>${LV[r.lv]} · ${r.en.split(' ').length} كلمة</small></button>`).join('')}</div>`;
    if (sub === 'vocab') x = `<div class="chips libchips">${Object.keys(A.VOCAB).map((k) => `<button class="chip ${k === vcat ? 'on' : ''}" onclick="EN.setVcat('${k}')">${k}</button>`).join('')}</div>
      <div class="vlist">${A.VOCAB[vcat].map((w, i) => `<button class="vrow" onclick="EN.vword(${i})"><span>${w[2]}</span><div><b>${c.esc(w[0])}</b><em>${c.esc(w[1])}</em><small>${c.esc(w[3])}</small></div></button>`).join('')}</div>
      <div class="row" style="margin-top:12px"><button class="btn" onclick="EN.game('vocab')">❓ وش معناها؟</button><button class="btn alt" onclick="EN.game('abuild')">🧱 رتّب الجملة</button></div>`;
    if (sub === 'gram') x = A.GRAM.map((g, i) => `<div class="gl"><h3>${c.esc(g.a)} <small class="muted" dir="ltr">${c.esc(g.t)}</small></h3><p>${c.esc(g.r)}</p>
      ${g.ex.map((e) => `<div class="ex" onclick="EN.say('${q1(e[0])}')">🔊 ${c.esc(e[0])}<small>${c.esc(e[1])}</small></div>`).join('')}
      <button class="btn alt" style="margin-top:6px" onclick="EN.game('gram', ${i})">✏️ تمرين (٥ أسئلة)</button></div>`).join('') +
      `<button class="btn" onclick="EN.game('gram', -1)">🏆 اختبار شامل في القواعد</button>`;
    if (sub === 'dlg') x = `<p class="muted">محادثات يومية، وأنت{|ِ} أحد الشخصيات! اضغط أي جملة واسمعها</p>
      <div class="rlist">${A.DLG.map((d, i) => `<button class="rcard" onclick="EN.dialog(${i})"><span>${d.e}</span><b>${c.esc(d.t)}</b><small>${d.l.length} جمل</small></button>`).join('')}</div>`;
    if (sub === 'spell') x = `<p class="muted">تسمع الكلمة وتكتبها بالإنجليزي. فيه تلميح لو احتجت 💡</p>
      <div class="row"><button class="btn" onclick="EN.game('spell')">🎧 ابدأ الإملاء</button></div>`;
    const k = c.heroes()[0] || c.myKids()[0], f = k && k.g === 'f';
    return `<div class="card"><h2>إنجليزي متقدّم 🚀</h2>${tabs}${x.replace(/\{\|ِ\}/g, f ? 'ِ' : '')}</div>`;
  }
  function setSub(v) { sub = v; render(); }
  function setVcat(k) { vcat = k; render(); }
  function vword(i) { const w = A.VOCAB[vcat][i]; say(w[0] + '. ' + w[3]); show(`<div class="bige">${w[2]}</div><p class="ent">${C().esc(w[0])}</p><p class="muted">${C().esc(w[1])}</p><p class="gq">${C().esc(w[3])}</p><button class="btn alt" onclick="EN.vword(${i})">🔊 اسمع مرة ثانية</button>`); }
  function reading(i) {
    const r = A.READ[i], c = C(), sents = r.en.match(/[^.!?]+[.!?]+["”]?/g) || [r.en];
    show(`<div class="bige" style="font-size:54px">${r.e}</div><p class="ent" style="font-size:22px">${c.esc(r.t)}</p>
      <div class="passage">${sents.map((x, k) => `<span class="sx" onclick="EN.sx(this,${i},${k})">${c.esc(x.trim())}</span> `).join('')}</div>
      <div id="artr" class="artr" style="display:none">${c.esc(r.ar)}</div>
      <div class="row"><button class="btn alt" onclick="EN.say('${q1(r.en)}')">🔊 اسمع القصة</button><button class="btn alt" onclick="EN.tr()">🇸🇦 الترجمة</button></div>
      <button class="btn" style="margin-top:10px" onclick="EN.game('read', ${i})">❓ جاوب الأسئلة</button>`);
    $('gameBody').querySelector('.encard').style.textAlign = 'center';
  }
  function sx(el, i, k) {
    const r = A.READ[i], sents = r.en.match(/[^.!?]+[.!?]+["”]?/g) || [r.en];
    document.querySelectorAll('.passage .sx').forEach((e) => e.classList.remove('on')); el.classList.add('on'); say(sents[k].trim());
  }
  function tr() { const e = $('artr'); if (e) e.style.display = e.style.display === 'none' ? '' : 'none'; }
  function dialog(i) {
    const d = A.DLG[i], c = C(), me = name();
    show(`<div class="bige" style="font-size:54px">${d.e}</div><p class="ent" style="font-size:22px">${c.esc(d.t)}</p>
      <div class="dlg">${d.l.map((l, k) => `<div class="dl ${l[0]}" onclick="EN.say('${q1(nm(l[1]))}')"><b>${c.esc(l[0] === 'a' ? me : d.b)}</b>${c.esc(nm(l[1]))}<small>${c.esc(nm(l[2]))}</small></div>`).join('')}</div>
      <button class="btn alt" onclick="EN.playDlg(${i})">▶ شغّل المحادثة كاملة</button>`);
  }
  function playDlg(i) {
    if (!('speechSynthesis' in window)) return;
    speechSynthesis.cancel(); const v = enVoice();
    A.DLG[i].l.forEach((l) => { const u = new SpeechSynthesisUtterance(nm(l[1])); if (v) u.voice = v; u.lang = v ? v.lang : 'en-US'; u.rate = 0.85; u.pitch = l[0] === 'a' ? 1.25 : 0.9; speechSynthesis.speak(u); });
  }

  function setLevel(v) { level = v; render(); }
  function setCat(k) { cat = k; render(); }
  function letter(i) { const l = LETTERS[i]; say(l[0] + '. ' + l[1]); show(`<div class="big">${l[0]} <small>${l[0].toLowerCase()}</small></div><div class="bige">${l[3]}</div><p class="ent">${l[1]}</p><p class="muted">${l[2]}</p><button class="btn alt" onclick="EN.say('${l[0]}. ${l[1]}')">🔊 اسمع مرة ثانية</button>`); }
  function word(i) { const w = WORDS[cat][i]; say(w[0]); show(`<div class="bige">${w[2]}</div><p class="ent">${w[0]}</p><p class="muted">${w[1]}</p><button class="btn alt" onclick="EN.say('${w[0]}')">🔊 اسمع مرة ثانية</button>`); }
  function sent(i) { const x = SENT[i]; say(nm(x[0])); show(`<div class="bige">${x[2]}</div><p class="ent" dir="ltr">${C().esc(nm(x[0]))}</p><p class="muted">${C().esc(nm(x[1]))}</p><button class="btn alt" onclick="EN.sent(${i})">🔊 اسمع مرة ثانية</button>`); }
  function show(html) { $('gameBody').innerHTML = `<div class="encard">${html}</div>`; $('gameModal').classList.add('on'); }

  /* ---- الألعاب: ٥ جولات، وفي الآخر ملصق ---- */
  function game(kind, arg) {
    let qs = [];
    if (kind === 'letters') qs = shuffle(LETTERS).slice(0, 5).map((l) => ({ say: l[0], a: l[0], o: shuffle([l[0], ...shuffle(LETTERS.filter((x) => x !== l).map((x) => x[0])).slice(0, 2)]), big: true, q: 'اسمع الحرف، ووين هو؟' }));
    if (kind === 'words') { const all = Object.values(WORDS).flat(); qs = shuffle(WORDS[cat]).slice(0, 5).map((w) => ({ say: w[0], a: w[2], o: shuffle([w[2], ...shuffle(all.filter((x) => x[2] !== w[2])).slice(0, 2).map((x) => x[2])]), big: true, q: 'اسمع الكلمة، ووين صورتها؟' })); }
    if (kind === 'mean') qs = shuffle(SENT).slice(0, 5).map((x) => ({ say: nm(x[0]), show: nm(x[0]), a: nm(x[1]), o: shuffle([nm(x[1]), ...shuffle(SENT.filter((y) => y !== x)).slice(0, 2).map((y) => nm(y[1]))]), q: 'وش معنى الجملة؟' }));
    if (kind === 'build') qs = shuffle(SENT.filter((x) => x[0].split(' ').length <= 5)).slice(0, 5).map((x) => ({ build: true, words: nm(x[0]).split(' '), ar: nm(x[1]), say: nm(x[0]) }));
    const mcq = (row, extra) => Object.assign({ a: row[1], o: shuffle(row.slice(1)), en: true }, extra);
    if (kind === 'read') { const r = A.READ[arg]; qs = r.q.map((x) => mcq(x, { show: x[0], say: x[0], q: r.e + ' ' + r.t })); }
    if (kind === 'gram') {
      const src = arg >= 0 ? A.GRAM[arg].quiz : shuffle(A.GRAM.flatMap((g) => g.quiz)).slice(0, 8);
      qs = src.map((x) => mcq(x, { gq: x[0], say: x[0].replace('___', x[1]), mute: true, q: 'اختر الكلمة الصحيحة' }));
    }
    if (kind === 'vocab') { const all = Object.values(A.VOCAB).flat(); qs = shuffle(A.VOCAB[vcat]).slice(0, 6).map((w) => ({ say: w[0], show: w[0], a: w[1], o: shuffle([w[1], ...shuffle(all.filter((x) => x[1] !== w[1])).slice(0, 3).map((x) => x[1])]), q: 'وش معنى الكلمة؟' })); }
    if (kind === 'abuild') qs = shuffle(A.VOCAB[vcat].filter((w) => w[3].split(' ').length <= 8)).slice(0, 5).map((w) => ({ build: true, words: w[3].split(' '), ar: w[2] + ' ' + w[1], say: w[3] }));
    if (kind === 'spell') { const all = Object.values(A.VOCAB).flat().filter((w) => /^[a-z]{4,10}$/.test(w[0])); qs = shuffle(all).slice(0, 6).map((w) => ({ spell: true, a: w[0], say: w[0], hint: w[2] + ' ' + w[1] })); }
    G = { kind, arg, qs, i: 0, score: 0, picked: null, built: [], typed: null, hint: 0 };
    draw();
    $('gameModal').classList.add('on');
  }
  function draw() {
    const c = C(), it = G.qs[G.i];
    if (!it) {
      const stars = '⭐'.repeat(G.score) + '☆'.repeat(G.qs.length - G.score);
      $('gameBody').innerHTML = `<h2>🎉 Great job!</h2><div class="celebrate" style="font-size:28px">${stars}</div><p class="ptext" style="color:var(--ink);text-align:center">${G.score >= 4 ? 'Excellent! ممتاز 🏆' : G.score >= 2 ? 'Good! زين، كمّل 👏' : 'Try again! جرّب مرة ثانية 💪'}</p>
        <div class="row"><button class="btn" onclick="EN.game('${G.kind}'${G.arg != null ? ', ' + G.arg : ''})">العب مرة ثانية 🔁</button><button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div>`;
      Play.logAct('en', { id: 'en-' + G.kind + (G.arg != null && G.arg >= 0 ? '-' + G.arg : '') }, Math.round(G.score * 5 / G.qs.length));
      return;
    }
    const head = `<h2>${{ letters: '🎯 وين الحرف؟', words: '🎧 اسمع واختار', mean: '❓ وش معناها؟', build: '🧱 رتّب الجملة', abuild: '🧱 رتّب الجملة', read: '📖 فهم المقروء', gram: '📐 تمرين قواعد', vocab: '🧠 وش معناها؟', spell: '🎧 إملاء' }[G.kind]} <small class="muted">${G.i + 1}/${G.qs.length}</small></h2>`;
    if (it.spell) {
      const done = G.typed != null, ok = done && G.typed === it.a;
      $('gameBody').innerHTML = `${head}<p class="ptext" style="color:var(--ink)">اسمع الكلمة واكتبها</p>
        <button class="btn alt" onclick="EN.say('${it.say}')">🔊 اسمع</button>
        ${G.hint ? `<p class="muted" style="font-size:18px">💡 ${c.esc(it.hint)} · تبدأ بـ <b dir="ltr">${it.a[0]}</b> · ${it.a.length} حروف</p>` : ''}
        <input id="spellIn" class="spell" autocomplete="off" autocapitalize="off" autocorrect="off" spellcheck="false" ${done ? 'disabled' : ''} value="${done ? c.esc(G.typed) : ''}" onkeydown="if(event.key==='Enter')EN.check()">
        ${done ? `<p class="fb">${ok ? '✅ Perfect! صح' : '💡 الصحيح: <b dir="ltr">' + it.a + '</b>'}</p><button class="btn" onclick="EN.next(0)">التالي ←</button>`
          : `<div class="row"><button class="btn" onclick="EN.check()">تحقّق ✓</button>${G.hint ? '' : '<button class="btn alt" onclick="EN.hint()">💡 تلميح</button>'}</div>`}`;
      if (!done) { setTimeout(() => say(it.say), 250); const el = $('spellIn'); if (el) el.focus(); }
      return;
    }
    if (it.build) {
      const left = it.pool || (it.pool = shuffle(it.words.map((w, k) => ({ w, k }))));
      const done = G.built.length === it.words.length, ok = done && G.built.map((x) => x.w).join(' ') === it.words.join(' ');
      $('gameBody').innerHTML = `${head}<p class="muted">${c.esc(it.ar)}</p>
        <div class="buildline" dir="ltr">${G.built.map((x, k) => `<button class="bw on" ${done ? 'disabled' : `onclick="EN.unpick(${k})"`}>${c.esc(x.w)}</button>`).join('') || '<span class="muted">اضغط الكلمات بالترتيب…</span>'}</div>
        <div class="buildpool" dir="ltr">${left.map((x, k) => G.built.includes(x) ? '' : `<button class="bw" onclick="EN.pick(${k})">${c.esc(x.w)}</button>`).join('')}</div>
        ${done ? `<p class="fb">${ok ? '✅ صح! ' : '💡 الصحيح: '}<span dir="ltr">${c.esc(it.words.join(' '))}</span></p><button class="btn" onclick="EN.next(${ok ? 1 : 0})">التالي ←</button>` : `<button class="btn alt" onclick="EN.say('${it.say.replace(/'/g, "\\'")}')">🔊 اسمع الجملة</button>`}`;
      return;
    }
    const ans = G.picked != null;
    $('gameBody').innerHTML = `${head}<p class="ptext" style="color:var(--ink)">${c.esc(it.q)}</p>${it.gq ? `<p class="gq">${c.esc(ans ? it.say : it.gq)}</p>` : it.show ? `<p class="ent" dir="ltr" ${it.en ? 'style="font-size:20px"' : ''}>${c.esc(it.show)}</p>` : ''}
      ${it.mute && !ans ? '' : `<button class="btn alt" onclick="EN.say('${it.say.replace(/'/g, "\\'")}')">🔊 اسمع</button>`}
      <div class="opts ${it.big ? 'big' : ''} ${it.en ? 'en' : ''}">${it.o.map((o, k) => `<button class="opt ${ans ? (o === it.a ? 'ok' : k === G.picked ? 'no' : '') : ''}" ${ans ? 'disabled' : `onclick="EN.answer(${k})"`}>${c.esc(o)}</button>`).join('')}</div>
      ${ans ? `<p class="fb">${it.o[G.picked] === it.a ? '✅ Yes! صح' : '💡 الجواب: ' + c.esc(it.a)}</p><button class="btn" onclick="EN.next(0)">التالي ←</button>` : ''}`;
    if (!ans && !it.mute) setTimeout(() => say(it.say), 250);
  }
  function answer(k) { const it = G.qs[G.i]; G.picked = k; if (it.o[k] === it.a) G.score++; draw(); if (it.mute) say(it.say); }
  function check() { const it = G.qs[G.i], v = (($('spellIn') || {}).value || '').trim().toLowerCase(); if (!v) return; G.typed = v; if (v === it.a) G.score++; draw(); }
  function hint() { G.hint = 1; draw(); }
  function pick(k) { const it = G.qs[G.i]; G.built.push(it.pool[k]); if (G.built.length === it.words.length) say(it.say); draw(); }
  function unpick(k) { G.built.splice(k, 1); draw(); }
  function next(add) { G.score += add || 0; G.i++; G.picked = null; G.built = []; G.typed = null; G.hint = 0; draw(); }

  return { render, setLevel, setCat, letter, word, sent, say, game, answer, pick, unpick, next, setSub, setVcat, vword, reading, sx, tr, dialog, playDlg, check, hint };
})();

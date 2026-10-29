/* سِراج | SIRAJ — تعلّم الإنجليزي: حروف (٣-٥)، كلمات (٦-٨)، جمل (٩-١٢) */
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

  let level = null, cat = Object.keys(WORDS)[0], G = null;
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

  function defLevel() { const k = C().heroes()[0] || C().myKids()[0]; return !k ? 'letters' : k.age >= 3 ? 'sent' : k.age === 2 ? 'words' : 'letters'; }
  function render() {
    const c = C();
    if (c.isNight()) {
      $('eng').innerHTML = `<div class="card nightcard"><div style="font-size:64px">😴</div><h2>Good night!</h2><p class="muted">الإنجليزي نام، ويرجع الصبح ☀️</p><button class="btn" onclick="App.tab('tonight')">قصة الليلة 🌙</button></div>`;
      return;
    }
    level = level || defLevel();
    const lv = [['letters', '🔤 حروف', '٣-٥'], ['words', '🧩 كلمات', '٦-٨'], ['sent', '💬 جمل', '٩-١٢']];
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
    } else {
      body = `<div class="card"><h2>جمل إنجليزي 💬</h2><p class="muted">اضغط الجملة واسمعها</p>
        <div class="sents">${SENT.map((x, i) => `<button class="sn" onclick="EN.sent(${i})"><span>${x[2]}</span><div><b dir="ltr">${c.esc(nm(x[0]))}</b><small>${c.esc(nm(x[1]))}</small></div></button>`).join('')}</div>
        <div class="row" style="margin-top:12px"><button class="btn" onclick="EN.game('mean')">❓ وش معناها؟</button><button class="btn alt" onclick="EN.game('build')">🧱 رتّب الجملة</button></div></div>`;
    }
    $('eng').innerHTML = `<div class="seg enlv">${lv.map(([v, t, a]) => `<button class="${v === level ? 'on' : ''}" onclick="EN.setLevel('${v}')">${t}<small>${a}</small></button>`).join('')}</div>${body}`;
  }
  function setLevel(v) { level = v; render(); }
  function setCat(k) { cat = k; render(); }
  function letter(i) { const l = LETTERS[i]; say(l[0] + '. ' + l[1]); show(`<div class="big">${l[0]} <small>${l[0].toLowerCase()}</small></div><div class="bige">${l[3]}</div><p class="ent">${l[1]}</p><p class="muted">${l[2]}</p><button class="btn alt" onclick="EN.say('${l[0]}. ${l[1]}')">🔊 اسمع مرة ثانية</button>`); }
  function word(i) { const w = WORDS[cat][i]; say(w[0]); show(`<div class="bige">${w[2]}</div><p class="ent">${w[0]}</p><p class="muted">${w[1]}</p><button class="btn alt" onclick="EN.say('${w[0]}')">🔊 اسمع مرة ثانية</button>`); }
  function sent(i) { const x = SENT[i]; say(nm(x[0])); show(`<div class="bige">${x[2]}</div><p class="ent" dir="ltr">${C().esc(nm(x[0]))}</p><p class="muted">${C().esc(nm(x[1]))}</p><button class="btn alt" onclick="EN.sent(${i})">🔊 اسمع مرة ثانية</button>`); }
  function show(html) { $('gameBody').innerHTML = `<div class="encard">${html}</div>`; $('gameModal').classList.add('on'); }

  /* ---- الألعاب: ٥ جولات، وفي الآخر ملصق ---- */
  function game(kind) {
    let qs = [];
    if (kind === 'letters') qs = shuffle(LETTERS).slice(0, 5).map((l) => ({ say: l[0], a: l[0], o: shuffle([l[0], ...shuffle(LETTERS.filter((x) => x !== l).map((x) => x[0])).slice(0, 2)]), big: true, q: 'اسمع الحرف، ووين هو؟' }));
    if (kind === 'words') { const all = Object.values(WORDS).flat(); qs = shuffle(WORDS[cat]).slice(0, 5).map((w) => ({ say: w[0], a: w[2], o: shuffle([w[2], ...shuffle(all.filter((x) => x[2] !== w[2])).slice(0, 2).map((x) => x[2])]), big: true, q: 'اسمع الكلمة، ووين صورتها؟' })); }
    if (kind === 'mean') qs = shuffle(SENT).slice(0, 5).map((x) => ({ say: nm(x[0]), show: nm(x[0]), a: nm(x[1]), o: shuffle([nm(x[1]), ...shuffle(SENT.filter((y) => y !== x)).slice(0, 2).map((y) => nm(y[1]))]), q: 'وش معنى الجملة؟' }));
    if (kind === 'build') qs = shuffle(SENT.filter((x) => x[0].split(' ').length <= 5)).slice(0, 5).map((x) => ({ build: true, words: nm(x[0]).split(' '), ar: nm(x[1]), say: nm(x[0]) }));
    G = { kind, qs, i: 0, score: 0, picked: null, built: [] };
    draw();
    $('gameModal').classList.add('on');
  }
  function draw() {
    const c = C(), it = G.qs[G.i];
    if (!it) {
      const stars = '⭐'.repeat(G.score) + '☆'.repeat(G.qs.length - G.score);
      $('gameBody').innerHTML = `<h2>🎉 Great job!</h2><div class="celebrate" style="font-size:28px">${stars}</div><p class="ptext" style="color:var(--ink);text-align:center">${G.score >= 4 ? 'Excellent! ممتاز 🏆' : G.score >= 2 ? 'Good! زين، كمّل 👏' : 'Try again! جرّب مرة ثانية 💪'}</p>
        <div class="row"><button class="btn" onclick="EN.game('${G.kind}')">العب مرة ثانية 🔁</button><button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div>`;
      Play.logAct('en', { id: 'en-' + G.kind }, G.score);
      return;
    }
    const head = `<h2>${{ letters: '🎯 وين الحرف؟', words: '🎧 اسمع واختار', mean: '❓ وش معناها؟', build: '🧱 رتّب الجملة' }[G.kind]} <small class="muted">${G.i + 1}/${G.qs.length}</small></h2>`;
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
    $('gameBody').innerHTML = `${head}<p class="ptext" style="color:var(--ink)">${c.esc(it.q)}</p>${it.show ? `<p class="ent" dir="ltr">${c.esc(it.show)}</p>` : ''}
      <button class="btn alt" onclick="EN.say('${it.say.replace(/'/g, "\\'")}')">🔊 اسمع</button>
      <div class="opts ${it.big ? 'big' : ''}">${it.o.map((o, k) => `<button class="opt ${ans ? (o === it.a ? 'ok' : k === G.picked ? 'no' : '') : ''}" ${ans ? 'disabled' : `onclick="EN.answer(${k})"`}>${c.esc(o)}</button>`).join('')}</div>
      ${ans ? `<p class="fb">${it.o[G.picked] === it.a ? '✅ Yes! صح' : '💡 الجواب: ' + c.esc(it.a)}</p><button class="btn" onclick="EN.next(0)">التالي ←</button>` : ''}`;
    if (!ans) setTimeout(() => say(it.say), 250);
  }
  function answer(k) { const it = G.qs[G.i]; G.picked = k; if (it.o[k] === it.a) G.score++; draw(); }
  function pick(k) { const it = G.qs[G.i]; G.built.push(it.pool[k]); if (G.built.length === it.words.length) say(it.say); draw(); }
  function unpick(k) { G.built.splice(k, 1); draw(); }
  function next(add) { G.score += add || 0; G.i++; G.picked = null; G.built = []; draw(); }

  return { render, setLevel, setCat, letter, word, sent, say, game, answer, pick, unpick, next };
})();

/* سِراج | SIRAJ — الدفعة ٢: أذكار النوم، أصوات النوم، مكافأة الأسبوع، رسالة من بابا/ماما */
const Night = (() => {
  const $ = (id) => document.getElementById(id);
  const C = () => App.ctx();
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);

  /* ---------- أذكار النوم (من الصحيحين والسنن) ---------- */
  const ADHKAR = [
    { t: 'آية الكرسي', n: 1, src: 'صحيح البخاري (٢٣١١)', why: 'من قرأها عند النوم لا يزال عليه من الله حافظ حتى يصبح.',
      x: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ' },
    { t: 'المعوّذات', n: 3, src: 'صحيح البخاري (٥٠١٧)', why: 'نجمع الكفّين، ننفث فيهما ونقرأ، ثم نمسح بهما ما استطعنا من الجسد، ثلاث مرات.',
      x: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ\n\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ\n\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ' },
    { t: 'آخر آيتين من سورة البقرة', n: 1, src: 'صحيح البخاري (٥٠٠٩)', why: 'من قرأهما في ليلة كفتاه.',
      x: 'آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ' },
    { t: 'التسبيح قبل النوم', n: 1, src: 'صحيح البخاري (٣٧٠٥)، صحيح مسلم (٢٧٢٧)', why: 'علّمه النبي ﷺ فاطمة وعليًّا رضي الله عنهما.', tasbih: [['سُبْحَانَ اللَّهِ', 33], ['الْحَمْدُ لِلَّهِ', 33], ['اللَّهُ أَكْبَرُ', 34]] },
    { t: 'دعاء النوم', n: 1, src: 'صحيح البخاري (٦٣٢٤)', why: 'كان النبي ﷺ إذا أخذ مضجعه قالها.', x: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا' },
    { t: 'دعاء وضع الجنب', n: 1, src: 'صحيح البخاري (٦٣٢٠)', why: 'نقوله ونحن نضع جنبنا على الفراش.',
      x: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، إِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ' }
  ];
  let A = null;
  const dk = () => { const d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); };
  function adhkar() {
    A = { i: 0, c: 0, tb: 0 }; drawA(); $('gameModal').classList.add('on');
  }
  function drawA() {
    const c = C(), d = ADHKAR[A.i];
    if (!d) {
      $('gameBody').innerHTML = `<div class="adk done"><div style="font-size:64px">🤲</div><h2>أحسنتم! خلّصتوا أذكار النوم</h2><p class="muted">تصبحون على خير، الله يحفظكم 🌙</p>
        <div class="row"><button class="btn" onclick="Night.sounds()">🌧️ أصوات النوم</button><button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div></div>`;
      const s = c.S(); if (s.adkDay !== dk()) { s.adkDay = dk(); c.save(); Play.logAct('adhkar', { id: 'adhkar' }, 1); }
      return;
    }
    const prog = ADHKAR.map((_, k) => `<i class="${k < A.i ? 'ok' : k === A.i ? 'now' : ''}"></i>`).join('');
    let body;
    if (d.tasbih) {
      const [w, max] = d.tasbih[A.tb];
      body = `<p class="adx" style="font-size:30px">${w}</p><button class="tsb" onclick="Night.tap()"><b>${AR(A.c)}</b><small>من ${AR(max)}</small></button>
        <div class="tsrow">${d.tasbih.map(([x, m], k) => `<span class="${k < A.tb ? 'ok' : k === A.tb ? 'now' : ''}">${x} ${AR(m)}</span>`).join('')}</div>`;
    } else {
      body = `<div class="adx">${c.esc(d.x).replace(/\n\n/g, '<br><br>')}</div>
        ${d.n > 1 ? `<p class="muted">${AR(Math.min(A.c + 1, d.n))} من ${AR(d.n)} مرات</p>` : ''}
        <div class="row"><button class="btn alt" onclick="Night.sayA()">🔊 اسمع</button><button class="btn" onclick="Night.tap()">${d.n > 1 && A.c + 1 < d.n ? 'مرة ثانية ✓' : 'تم ✓'}</button></div>`;
    }
    $('gameBody').innerHTML = `<div class="adk"><div class="adprog">${prog}</div><h2>${d.t}</h2><p class="muted" style="margin-top:-4px">${c.esc(d.why)}</p>${body}<p class="adsrc">📚 ${d.src}</p></div>`;
  }
  function tap() {
    const d = ADHKAR[A.i]; if (!d) return;
    if (d.tasbih) { A.c++; if (navigator.vibrate) navigator.vibrate(8); if (A.c >= d.tasbih[A.tb][1]) { A.tb++; A.c = 0; if (A.tb >= d.tasbih.length) { A.i++; A.tb = 0; } } }
    else { A.c++; if (A.c >= d.n) { A.i++; A.c = 0; } }
    drawA();
  }
  function sayA() { const d = ADHKAR[A.i]; if (d && d.x) C().speak(d.x.replace(/[۝ۚۖۗ]/g, '،'), true); }

  /* ---------- أصوات النوم (تتولد بالجهاز، بدون ملفات ولا إنترنت) ---------- */
  let ctx = null, nodes = [], tmr = null, endAt = 0, tick = null, cur = null;
  const SOUNDS = [['rain', '🌧️', 'مطر'], ['waves', '🌊', 'موج البحر'], ['desert', '🏜️', 'ليل الصحراء'], ['fan', '🌀', 'هدوء']];
  function noise(c, color) {
    const len = c.sampleRate * 4, b = c.createBuffer(1, len, c.sampleRate), d = b.getChannelData(0); let last = 0;
    for (let i = 0; i < len; i++) { const w = Math.random() * 2 - 1; if (color === 'brown') { last = (last + 0.02 * w) / 1.02; d[i] = last * 3.5; } else d[i] = w; }
    const s = c.createBufferSource(); s.buffer = b; s.loop = true; return s;
  }
  function stop(silent) {
    clearTimeout(tmr); clearInterval(tick);
    nodes.forEach((n) => { try { n.stop ? n.stop() : n.disconnect(); } catch (e) {} }); nodes = []; cur = null;
    if (ctx) { try { ctx.close(); } catch (e) {} ctx = null; }
    if (!silent && $('snd')) drawS();
  }
  function play(kind) {
    stop(true);
    const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return;
    ctx = new AC(); cur = kind;
    const out = ctx.createGain(); out.gain.value = 0; out.connect(ctx.destination);
    out.gain.linearRampToValueAtTime(0.9, ctx.currentTime + 2);
    if (kind === 'rain' || kind === 'fan') {
      const n = noise(ctx, kind === 'fan' ? 'brown' : 'white'), f = ctx.createBiquadFilter();
      f.type = kind === 'fan' ? 'lowpass' : 'bandpass'; f.frequency.value = kind === 'fan' ? 500 : 1400; f.Q.value = .6;
      const g = ctx.createGain(); g.gain.value = kind === 'fan' ? .5 : .35; n.connect(f); f.connect(g); g.connect(out); n.start(); nodes.push(n);
      if (kind === 'rain') { const n2 = noise(ctx, 'brown'), g2 = ctx.createGain(); g2.gain.value = .35; n2.connect(g2); g2.connect(out); n2.start(); nodes.push(n2); }
    } else if (kind === 'waves') {
      const n = noise(ctx, 'brown'), f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = 900;
      const g = ctx.createGain(); g.gain.value = .2; const lfo = ctx.createOscillator(), lg = ctx.createGain();
      lfo.frequency.value = 0.09; lg.gain.value = .55; lfo.connect(lg); lg.connect(g.gain);
      n.connect(f); f.connect(g); g.connect(out); n.start(); lfo.start(); nodes.push(n, lfo);
    } else if (kind === 'desert') {
      const n = noise(ctx, 'brown'), f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = 400;
      const g = ctx.createGain(); g.gain.value = .25; n.connect(f); f.connect(g); g.connect(out); n.start(); nodes.push(n);
      const chirp = () => { if (!ctx || cur !== 'desert') return; const o = ctx.createOscillator(), og = ctx.createGain(); o.frequency.value = 4200 + Math.random() * 400; o.type = 'sine';
        const t = ctx.currentTime; og.gain.value = 0; [0, .08, .16].forEach((d) => { og.gain.setValueAtTime(0, t + d); og.gain.linearRampToValueAtTime(.025, t + d + .02); og.gain.linearRampToValueAtTime(0, t + d + .05); });
        o.connect(og); og.connect(out); o.start(t); o.stop(t + .3); setTimeout(chirp, 900 + Math.random() * 1600); };
      chirp();
    }
    nodes.push(out);
    drawS();
  }
  function setTimer(min) {
    clearTimeout(tmr); clearInterval(tick); endAt = Date.now() + min * 6e4;
    tmr = setTimeout(() => { if (!ctx) return; const g = nodes[nodes.length - 1]; try { g.gain.linearRampToValueAtTime(0, ctx.currentTime + 8); } catch (e) {} setTimeout(() => stop(), 8500); }, min * 6e4 - 8000);
    tick = setInterval(drawS, 15000); drawS();
  }
  function sounds() {
    $('gameModal').classList.add('on'); $('gameBody').innerHTML = '<div id="snd"></div>';
    document.body.classList.add('sleepmode'); drawS();
  }
  function drawS() {
    const el = $('snd'); if (!el) return;
    const left = endAt && cur ? Math.max(0, Math.round((endAt - Date.now()) / 6e4)) : 0;
    el.innerHTML = `<div class="snd"><div class="snd-sky">${Array.from({ length: 22 }, (_, i) => `<i style="left:${(i * 37) % 100}%;top:${(i * 53) % 70}%;animation-delay:${(i % 7) * .4}s"></i>`).join('')}<div class="snd-moon">🌙</div></div>
      <h2>أصوات النوم</h2><p class="muted">اختر صوت، وغمّض عيونك… ويطفي لحاله 😴</p>
      <div class="sndg">${SOUNDS.map(([k, i, t]) => `<button class="${cur === k ? 'on' : ''}" onclick="Night.play('${k}')"><span>${i}</span>${t}</button>`).join('')}</div>
      <p class="muted" style="margin:10px 0 6px">يطفي بعد:</p>
      <div class="seg">${[10, 20, 30].map((m) => `<button class="${endAt && cur && Math.abs((endAt - Date.now()) / 6e4 - m) < .3 ? 'on' : ''}" onclick="Night.setTimer(${m})">${AR(m)} د</button>`).join('')}</div>
      ${cur ? `<p class="snd-left">${left ? '⏳ باقي ' + AR(left) + ' دقيقة' : '🎵 شغّال'}</p><button class="btn alt" onclick="Night.stop()">⏹ إيقاف</button>` : ''}
      <button class="btn ghost" onclick="Night.closeS()">إغلاق</button></div>`;
  }
  function closeS() { document.body.classList.remove('sleepmode'); Play.closeGame(); }

  /* ---------- مكافأة الأسبوع ---------- */
  function weekStart(d = new Date()) { const x = new Date(d); x.setHours(0, 0, 0, 0); x.setDate(x.getDate() - x.getDay()); return x; } // الأسبوع يبدأ الأحد
  function weekStars(k) {
    const c = C(), ws = weekStart().getTime();
    const days = new Set(c.allLogs().filter((e) => (e.k || []).includes(k.id) && e.t >= ws).map((e) => e.d));
    return days.size;
  }
  function rewardCard(ks) {
    const c = C(), r = c.S().fam.reward; if (!r || !r.text || !ks.length) return '';
    const need = r.stars || 5;
    return `<div class="card rwd"><div class="rwd-h"><span>🎁</span><div><small>مكافأة الأسبوع</small><b>${c.esc(r.text)}</b></div></div>
      ${ks.map((k) => { const n = Math.min(need, weekStars(k)); return `<div class="rwd-k"><span>${c.esc(k.name)}</span><div class="rwd-s">${Array.from({ length: need }, (_, i) => `<i class="${i < n ? 'on' : ''}">⭐</i>`).join('')}</div><em>${n >= need ? 'كسبتها! 🎉' : AR(n) + '/' + AR(need)}</em></div>`; }).join('')}
      <p class="muted" style="margin:6px 0 0;font-size:12.5px">كل ليلة تقرون فيها قصة = نجمة ⭐ (الأسبوع يبدأ من الأحد)</p></div>`;
  }

  /* ---------- رسالة من بابا/ماما ---------- */
  function msgCard(ks) {
    const c = C(), S = c.S(), m = S.fam.msg; if (!m || !m.t) return '';
    if (S.role === 'parent' && S.parentMode !== 'kids') return `<div class="card msg mine"><span>💌</span><div><small>رسالتك للعيال (تظهر لهم فوق)</small><p>${c.esc(m.t)}</p></div></div>`;
    if ((S.msgSeen || 0) >= m.at) return '';
    if (m.to && m.to !== 'all' && !ks.some((k) => m.to.includes(k.id))) return '';
    return `<div class="card msg"><span>💌</span><div><small>رسالة من ${c.esc(m.from || S.fam.dad || 'بابا')}</small><p>${c.esc(m.t)}</p></div><button onclick="Night.seen()" aria-label="تم">❤️</button></div>`;
  }
  function seen() { const c = C(), S = c.S(); S.msgSeen = (S.fam.msg || {}).at || Date.now(); c.save(); App.renderHome(); }

  return { adhkar, tap, sayA, sounds, play, stop, setTimer, closeS, rewardCard, msgCard, seen, weekStars };
})();

/* سِراج | SIRAJ — الدفعة ٤: لوحة شرف العائلة والشارات، وتقرير الأسبوع */
const Honors = (() => {
  const $ = (id) => document.getElementById(id);
  const C = () => App.ctx();
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  const DAY = 864e5;

  /* إحصائيات طفل في فترة */
  function stats(k, from, to = Date.now()) {
    const c = C(), logs = c.allLogs().filter((e) => (e.k || []).includes(k.id) && e.t >= from && e.t < to);
    const acts = c.allActs().filter((a) => (a.k || []).includes(k.id) && a.t >= from && a.t < to);
    const nights = new Set(logs.map((e) => e.d)).size;
    const cnt = (f) => acts.filter(f).length;
    const pro = new Set(logs.map((e) => e.s).filter((id) => /^p\d/.test(id))).size;
    return { stories: logs.length, nights, en: cnt((a) => a.a === 'en'), space: cnt((a) => a.a === 'space'), adhkar: new Set(acts.filter((a) => a.a === 'adhkar').map((a) => new Date(a.t).toDateString())).size,
      play: cnt((a) => ['color', 'puzzle', 'quiz'].includes(a.a)), pro, logs, acts };
  }
  function streak(k) {
    const c = C(), days = new Set(c.allLogs().filter((e) => (e.k || []).includes(k.id)).map((e) => e.d));
    const key = (d) => d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
    let n = 0; const d = new Date(); if (!days.has(key(d))) d.setDate(d.getDate() - 1);
    while (days.has(key(d))) { n++; d.setDate(d.getDate() - 1); }
    return n;
  }
  const weekStart = () => { const x = new Date(); x.setHours(0, 0, 0, 0); x.setDate(x.getDate() - x.getDay()); return x.getTime(); };

  /* ألقاب الأسبوع: تروح لأكثر واحد (ولو تعادلوا ياخذونها كلهم) */
  const TITLES = [
    ['nights', '📚', 'قارئ الأسبوع', 'قارئة الأسبوع', 3],
    ['adhkar', '🤲', 'صاحب الأذكار', 'صاحبة الأذكار', 3],
    ['en', '🔤', 'بطل الإنجليزي', 'بطلة الإنجليزي', 3],
    ['space', '🚀', 'رائد الفضاء', 'رائدة الفضاء', 1],
    ['play', '🎨', 'الفنان المبدع', 'الفنانة المبدعة', 3]
  ];
  /* شارات دائمة (إنجازات) */
  const BADGES = [
    ['s10', '📖', '١٠ قصص', (t) => t.stories >= 10], ['s25', '📚', '٢٥ قصة', (t) => t.stories >= 25], ['s50', '🏅', '٥٠ قصة', (t) => t.stories >= 50], ['s100', '🏆', '١٠٠ قصة', (t) => t.stories >= 100],
    ['st7', '🔥', '٧ ليالٍ متتالية', (t, k) => streak(k) >= 7], ['pro10', '🕌', '١٠ قصص أنبياء', (t) => t.pro >= 10], ['adk7', '🤲', '٧ ليالٍ أذكار', (t) => t.adhkar >= 7],
    ['en20', '🔤', '٢٠ نشاط إنجليزي', (t) => t.en >= 20], ['sp3', '🪐', 'مستكشف الفضاء', (t) => t.space >= 3]
  ];
  function titlesFor(kids, from) {
    const st = kids.map((k) => [k, stats(k, from)]), out = {};
    TITLES.forEach(([key, icon, m, f, min]) => {
      const best = Math.max(0, ...st.map(([, s]) => s[key]));
      if (best >= min) st.filter(([, s]) => s[key] === best).forEach(([k]) => (out[k.id] = out[k.id] || []).push([icon, k.g === 'f' ? f : m]));
    });
    return { out, st };
  }
  function badgesOf(k) { const t = stats(k, 0); return BADGES.map(([id, icon, name, ok]) => [icon, name, ok(t, k)]); }

  /* لوحة الشرف (في سمائي والمتابعة) */
  function board() {
    const c = C(), kids = c.S().fam.kids; if (!kids.length) return '';
    const { out, st } = titlesFor(kids, weekStart());
    return `<div class="card honor"><h3>🏆 لوحة شرف العائلة <small>هذا الأسبوع</small></h3>
      <div class="hrows">${st.map(([k, s]) => `<div class="hrow">${ART.avatarSVG(k.av, k.g, 48)}<div><b>${c.esc(k.name)}</b>
        <div class="htitles">${(out[k.id] || []).map(([i, t]) => `<span>${i} ${t}</span>`).join('') || '<em>كمّل وتاخذ لقب ✨</em>'}</div>
        <small>📖 ${AR(s.nights)} ليالٍ · 🤲 ${AR(s.adhkar)} · 🔤 ${AR(s.en)} · 🪐 ${AR(s.space)}</small></div></div>`).join('')}</div>
      <button class="btn alt" onclick="Honors.badges()">🎖️ شارات الإنجازات</button></div>`;
  }
  function badges() {
    const c = C(), kids = c.S().role === 'child' ? c.myKids() : c.S().fam.kids;
    $('gameBody').innerHTML = `<div class="encard"><h2>🎖️ شارات الإنجازات</h2>${kids.map((k) => `<div class="bdk"><h3>${ART.avatarSVG(k.av, k.g, 40)} ${c.esc(k.name)}</h3>
      <div class="bdg">${badgesOf(k).map(([i, n, ok]) => `<div class="${ok ? 'on' : ''}"><span>${ok ? i : '🔒'}</span><small>${n}</small></div>`).join('')}</div></div>`).join('')}</div>`;
    $('gameModal').classList.add('on');
  }

  /* تقرير الأسبوع (آخر ٧ أيام) */
  function report() {
    const c = C(), S = c.S(), kids = S.fam.kids, from = Date.now() - 7 * DAY, prev = from - 7 * DAY;
    const { out } = titlesFor(kids, from);
    const rows = kids.map((k) => {
      const s = stats(k, from), p = stats(k, prev, from), diff = s.nights - p.nights;
      const titles = (out[k.id] || []).map(([i, t]) => `<span>${i} ${t}</span>`).join('');
      const last = s.logs.sort((a, b) => b.t - a.t).slice(0, 3).map((e) => { const st = STORIES.find((x) => x.id === e.s); return st ? c.fill(st.title, [k]) : ''; }).filter(Boolean);
      return `<div class="rpk"><div class="rph">${ART.avatarSVG(k.av, k.g, 52)}<div><b>${c.esc(k.name)}</b><div class="htitles">${titles}</div></div></div>
        <div class="rps"><div><b>${AR(s.nights)}</b><small>ليالي قراءة</small></div><div><b>${AR(s.stories)}</b><small>قصة</small></div><div><b>${AR(s.adhkar)}</b><small>أذكار</small></div><div><b>${AR(s.en)}</b><small>إنجليزي</small></div><div><b>${AR(s.space + s.play)}</b><small>فضاء وألعاب</small></div></div>
        <p class="rpd">${diff > 0 ? '📈 أحسن من الأسبوع اللي قبله بـ' + AR(diff) + ' ' + (diff === 1 ? 'ليلة' : 'ليالٍ') : diff < 0 ? '📉 أقل من الأسبوع اللي قبله، شجّعهم 💪' : '➖ نفس الأسبوع اللي قبله'} · 🔥 ${AR(streak(k))} متتالية</p>
        ${last.length ? `<p class="muted" style="font-size:12.5px;margin:2px 0 0">آخر القصص: ${last.map((t) => '«' + c.esc(t) + '»').join('، ')}</p>` : ''}</div>`;
    }).join('');
    $('gameBody').innerHTML = `<div class="encard rp"><h2>📊 تقرير الأسبوع</h2><p class="muted">آخر ٧ أيام</p>${rows}
      ${S.fam.reward && S.fam.reward.text ? `<p class="muted">🎁 مكافأة الأسبوع: ${c.esc(S.fam.reward.text)} (${AR(S.fam.reward.stars || 5)} نجوم)</p>` : ''}</div>`;
    $('gameModal').classList.add('on');
  }
  function reportBtn() { return '<button class="card rpbtn" onclick="Honors.report()"><span>📊</span><div><b>تقرير الأسبوع</b><small>وش سوّوا العيال آخر ٧ أيام · يوصلك إشعار كل جمعة</small></div><em>←</em></button>'; }

  return { board, badges, report, reportBtn, stats };
})();

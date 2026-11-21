/* سِراج | SIRAJ — v5.0 غرفتي: غرفة الطفل تتزيّن بالأثاث كل ما جمع نجوم (ليالي قراءة)، والملصقات تتعلّق على لوحته */
const Room = (() => {
  const C = () => App.ctx();
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  /* [المعرّف، الاسم، النجوم المطلوبة، رسمته في الغرفة] — viewBox 360×240 */
  const ITEMS = [
    ['rug', 'سجادة وردية', 1, '<ellipse cx="180" cy="214" rx="92" ry="16" fill="#F7A8C8"/><ellipse cx="180" cy="214" rx="74" ry="11" fill="none" stroke="#fff" stroke-width="2" stroke-dasharray="5 5"/>'],
    ['lamp', 'فانوس دافي', 3, '<g transform="translate(218 128)"><rect x="-14" y="38" width="44" height="40" rx="4" fill="#C98A55"/><rect x="-14" y="38" width="44" height="7" rx="3" fill="#B0703E"/><path d="M0 8h16l3 26H-3z" fill="#FFD966"/><rect x="-4" y="4" width="24" height="5" rx="2" fill="#6B4A2E"/><path d="M8 0v4" stroke="#6B4A2E" stroke-width="3"/><circle cx="8" cy="22" r="20" fill="#FFE9A0" opacity=".35"/></g>'],
    ['shelf', 'رف كتب', 5, '<g transform="translate(18 70)"><rect width="62" height="8" rx="2" fill="#B0703E"/><rect y="44" width="62" height="8" rx="2" fill="#B0703E"/><rect x="6" y="-24" width="9" height="24" rx="1.5" fill="#FF6B6B"/><rect x="16" y="-20" width="9" height="20" rx="1.5" fill="#5B8DEF"/><rect x="26" y="-26" width="9" height="26" rx="1.5" fill="#4CD97B"/><rect x="40" y="-18" width="16" height="8" rx="1.5" fill="#FFB547" transform="rotate(-8 48 -14)"/><rect x="6" y="22" width="9" height="22" rx="1.5" fill="#B57BEA"/><rect x="16" y="26" width="9" height="18" rx="1.5" fill="#FFD23F"/><rect x="30" y="20" width="9" height="24" rx="1.5" fill="#FF8FC4"/></g>'],
    ['plant', 'نبتة خضراء', 7, '<g transform="translate(30 166)"><path d="M6 20h26l-4 26H10z" fill="#E07B39"/><path d="M19 20c-10-6-14-18-8-26 6 6 8 16 8 26zM19 20c4-12 14-18 22-14-4 8-12 14-22 14zM19 20c-2-14 2-24 10-28 2 10-2 20-10 28z" fill="#4CAF50"/></g>'],
    ['garland', 'زينة نجوم', 10, '<path d="M110 26q70 30 140 0" stroke="#E4D7FF" stroke-width="2" fill="none"/><g fill="#FFD23F"><path d="M128 33l2 4.5 5 .5-3.8 3.4 1.1 4.9-4.3-2.6-4.3 2.6 1.1-4.9-3.8-3.4 5-.5z"/><path d="M158 40l2 4.5 5 .5-3.8 3.4 1.1 4.9-4.3-2.6-4.3 2.6 1.1-4.9-3.8-3.4 5-.5z"/><path d="M190 41l2 4.5 5 .5-3.8 3.4 1.1 4.9-4.3-2.6-4.3 2.6 1.1-4.9-3.8-3.4 5-.5z"/><path d="M222 37l2 4.5 5 .5-3.8 3.4 1.1 4.9-4.3-2.6-4.3 2.6 1.1-4.9-3.8-3.4 5-.5z"/></g>'],
    ['bear', 'دبدوب', 14, '<g transform="translate(238 168)"><circle cx="0" cy="-30" r="7" fill="#B07A4F"/><circle cx="24" cy="-30" r="7" fill="#B07A4F"/><ellipse cx="12" cy="6" rx="18" ry="20" fill="#C98F5F"/><circle cx="12" cy="-22" r="15" fill="#C98F5F"/><ellipse cx="12" cy="-17" rx="7" ry="5" fill="#F2D3B0"/><circle cx="6" cy="-25" r="2" fill="#3B2A20"/><circle cx="18" cy="-25" r="2" fill="#3B2A20"/><circle cx="12" cy="-18" r="2" fill="#3B2A20"/><ellipse cx="12" cy="8" rx="9" ry="10" fill="#F2D3B0"/></g>'],
    ['scope', 'تلسكوب', 18, '<g transform="translate(330 120)"><path d="M-6 0l-16 60M-6 0l4 60M-6 0l18 58" stroke="#6B4A2E" stroke-width="3"/><rect x="-36" y="-20" width="46" height="13" rx="6" fill="#5B8DEF" transform="rotate(-28 -10 -12)"/><circle cx="-6" cy="-2" r="4" fill="#3B2A20"/></g>'],
    ['globe', 'كرة أرضية', 22, '<g transform="translate(288 92)"><circle r="14" fill="#4DB8F0"/><path d="M-8-6c4-2 6 1 7 4s-2 5-1 8c-4-1-7-4-8-7 0-2 0-4 2-5zM4-11c4 0 7 3 8 6-3 1-4 0-5 2s1 4-1 5-3-1-4-3 0-4 1-5-1-3 1-5z" fill="#5CCB6E"/><path d="M0 14v8M-10 24h20" stroke="#6B4A2E" stroke-width="3"/></g>'],
    ['tent', 'خيمة قراءة', 27, '<g transform="translate(96 108)"><path d="M0 100L34 0l34 100z" fill="#B57BEA"/><path d="M34 0l14 100H20z" fill="#FBF7FF"/><path d="M34 0L0 100M34 0l34 100" stroke="#8B4FD0" stroke-width="3"/><g fill="#FFD23F"><circle cx="14" cy="76" r="2.5"/><circle cx="54" cy="70" r="2.5"/><circle cx="24" cy="50" r="2.5"/></g></g>'],
    ['trophy', 'كأس الأبطال', 33, '<g transform="translate(46 32) scale(.7)"><path d="M14 8h20v10a10 10 0 0 1-20 0z" fill="#FFD23F"/><path d="M14 11H7c0 7 4 10 8 10M34 11h7c0 7-4 10-8 10" stroke="#FFB300" stroke-width="3" fill="none"/><rect x="21" y="27" width="6" height="7" fill="#FFB300"/><rect x="14" y="34" width="20" height="7" rx="2" fill="#8A5A3B"/></g>'],
    ['nlight', 'قمر ينوّر', 40, '<g transform="translate(90 32)"><circle r="12" fill="#FFE27A"/><circle r="22" fill="#FFE9A0" opacity=".3"/><path d="M-4-2q2-3 4 0M2-2q2-3 4 0" stroke="#3B2A20" stroke-width="1.5" fill="none"/></g>'],
    ['crown', 'تاج على الجدار', 50, '<g transform="translate(184 92)"><rect x="-4" y="-4" width="48" height="38" rx="4" fill="#fff" stroke="#E0B85C" stroke-width="3"/><path d="M4 26l4-16 8 9 4-12 4 12 8-9 4 16z" fill="#FFD23F"/></g>']
  ];
  function starsOf(k) { return typeof Honors !== 'undefined' ? Honors.stats(k, 0).nights : 0; }

  function svg(k, stars, stickers) {
    const on = ITEMS.filter((it) => stars >= it[2]).map((it) => it[3]).join('');
    const board = stickers.slice(-8).map((s, i) => `<text x="${246 + (i % 4) * 22}" y="${46 + Math.floor(i / 4) * 24}" font-size="17" text-anchor="middle">${s}</text>`).join('');
    const hero = typeof ART !== 'undefined' ? ART.avatarSVG(k.av, k.g, 70).replace('<svg', '<svg x="130" y="128" width="70" height="80"') : '';
    return `<svg class="roomsvg" viewBox="0 0 360 240" aria-label="غرفتي"><defs><linearGradient id="rmW" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#EDE4FF"/><stop offset="1" stop-color="#F9E8F3"/></linearGradient><linearGradient id="rmF" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E7B98A"/><stop offset="1" stop-color="#D49A69"/></linearGradient></defs>
      <rect width="360" height="190" fill="url(#rmW)"/><g fill="#fff" opacity=".5"><circle cx="40" cy="20" r="2"/><circle cx="120" cy="12" r="2"/><circle cx="330" cy="30" r="2"/></g>
      <rect x="112" y="18" width="62" height="54" rx="8" fill="#2B2F6B" stroke="#F6E2C6" stroke-width="5"/><path d="M143 18v54M112 45h62" stroke="#F6E2C6" stroke-width="3"/><circle cx="130" cy="34" r="7" fill="#FFE27A"/><circle cx="133" cy="32" r="6" fill="#2B2F6B"/><g fill="#fff"><circle cx="160" cy="30" r="1.3"/><circle cx="125" cy="58" r="1.1"/><circle cx="162" cy="60" r="1.3"/></g>
      <rect x="226" y="24" width="98" height="56" rx="6" fill="#D9A877"/><rect x="230" y="28" width="90" height="48" rx="4" fill="#F3D9B8"/>${board || '<text x="275" y="58" font-size="11" text-anchor="middle" fill="#B08560" font-family="sans-serif">لوحة ملصقاتي</text>'}
      <rect y="186" width="360" height="54" fill="url(#rmF)"/><rect y="184" width="360" height="5" fill="#C78B58"/>
      <g transform="translate(250 150)"><rect x="-8" y="30" width="110" height="12" rx="4" fill="#9B6A45"/><rect x="0" y="12" width="100" height="22" rx="8" fill="#B79BF5"/><rect x="0" y="12" width="34" height="16" rx="6" fill="#fff"/><rect x="-8" y="-6" width="12" height="48" rx="5" fill="#9B6A45"/></g>
      ${on}${hero}</svg>`;
  }

  function card(k) {
    const c = C(), stars = starsOf(k), ev = typeof Play !== 'undefined' ? Play.kidEvents(k) : [], stickers = ev.map((e) => e.st[0]);
    const next = ITEMS.find((it) => stars < it[2]), got = ITEMS.filter((it) => stars >= it[2]).length;
    const prev = [...ITEMS].reverse().find((it) => stars >= it[2]), from = prev ? prev[2] : 0;
    const pct = next ? Math.round((stars - from) / (next[2] - from) * 100) : 100;
    return `<div class="card room"><div class="roomh"><h3>غرفة ${c.esc(k.name)} 🏠</h3><span class="roomst">${Stk.icon('star')}<b>${AR(stars)}</b></span></div>
      <div class="roomart">${svg(k, stars, stickers)}</div>
      ${next ? `<div class="roomnext"><span>${AR(next[2] - stars)} ${next[2] - stars === 1 ? 'نجمة' : 'نجوم'} وينفتح لك <b>${next[1]}</b> 🎁</span><i><b style="width:${Math.max(6, pct)}%"></b></i></div>` : '<div class="roomnext"><span>🏆 غرفتك كاملة! أنت بطل القراءة</span></div>'}
      <div class="roomgrid">${ITEMS.map((it) => `<div class="${stars >= it[2] ? 'on' : ''}"><svg viewBox="${box(it[0])}">${it[3]}</svg><small>${stars >= it[2] ? it[1] : '🔒 ' + AR(it[2]) + ' ⭐'}</small></div>`).join('')}</div>
      <p class="muted roomtip">كل ليلة تقرأ فيها قصة = نجمة ⭐ والملصقات اللي تجمعها تتعلّق على لوحتك (${AR(got)} من ${AR(ITEMS.length)})</p></div>`;
  }
  /* إطار كل قطعة للقائمة */
  const BOX = { rug: '80 190 200 50', lamp: '196 116 60 92', shelf: '14 40 72 84', plant: '26 140 52 72', garland: '106 20 150 46', bear: '222 132 40 60', scope: '296 92 56 92', globe: '268 74 40 54', tent: '90 102 80 110', trophy: '46 34 36 32', nlight: '64 6 52 52', crown: '174 82 60 48' };
  const box = (id) => BOX[id] || '0 0 360 240';
  function render() { const c = C(); return c.myKids().map(card).join(''); }
  return { render, ITEMS };
})();

/* سِراج | SIRAJ — الرسومات: الشخصيات والمشاهد (SVG) */
const ART = (() => {
  const SKIN = ['#FDDCC0', '#F1C08F', '#D9A06B', '#A96F45'];
  const HAIR = ['#2B1B12', '#5A3420', '#9C5B2E', '#E0B062', '#C0392B'];
  const SHIRT = ['#FF6B6B', '#FF9F1C', '#FFD93D', '#4CD97B', '#4DB8F0', '#9B6BF2', '#FF7AB6', '#1ABC9C', '#2B2350', '#FFFFFF', '#8B5A2B', '#E84393'];
  const HEADC = ['#FF7AB6', '#9B6BF2', '#4DB8F0', '#2B2350', '#FFFFFF', '#1ABC9C', '#FFD93D', '#8B5A2B'];
  // خيارات الشكل (يختارها الطفل بنفسه)
  const STYLES = { m: ['قصير', 'منكوش', 'كيرلي', 'محلوق'], f: ['طويل', 'ذيل حصان', 'ضفائر', 'قصير'] };
  const HEADS = { m: [['', 'بدون'], ['shmagh', 'شماغ'], ['ghutra', 'غترة'], ['taqiya', 'طاقية']], f: [['', 'بدون'], ['hijab', 'حجاب']] };
  const OUTFITS = { m: [['tee', 'تيشيرت'], ['thobe', 'ثوب'], ['hoodie', 'هودي']], f: [['tee', 'تيشيرت'], ['dress', 'فستان'], ['hoodie', 'هودي']] };

  const PANTS = ['#3B5BA5', '#2B2350', '#8B5A2B', '#4CD97B', '#FF7AB6', '#9B6BF2', '#E0E0E0', '#FF9F1C'];
  // الشكل الافتراضي: البنت مثل يارا، والولد مثل وليد
  const DEFAULTS = {
    f: { skin: 0, hair: 1, style: 0, head: '', outfit: 'hoodie', shirt: 2, pants: 0 },
    m: { skin: 0, hair: 0, style: 0, head: 'shmagh', outfit: 'tee', shirt: 10, pants: 1 }
  };
  OUTFITS.m.push(['overalls', 'صدرية']); OUTFITS.f.push(['overalls', 'صدرية']);

  function headOf(av, girl) { const h = av.head != null ? av.head : (av.hijab ? 'hijab' : ''); return girl ? (h === 'hijab' ? 'hijab' : '') : (['shmagh', 'ghutra', 'taqiya'].includes(h) ? h : ''); }
  const shade = (hex, k) => { const n = parseInt(hex.slice(1), 16); const f = (v) => Math.max(0, Math.min(255, Math.round(v * k))); return '#' + [n >> 16, (n >> 8) & 255, n & 255].map((v) => f(v).toString(16).padStart(2, '0')).join(''); };

  /* شخصية كاملة (راس كبير وجسم صغير) على لوحة 100×150 */
  function avatar(av, g) {
    av = av || {};
    const girl = g === 'f', skin = SKIN[av.skin ?? 0] || SKIN[0], hair = HAIR[av.hair ?? 0] || HAIR[0];
    const shirt = SHIRT[av.shirt ?? 0] || SHIRT[0], pants = PANTS[av.pants ?? 0] || PANTS[0], head = headOf(av, girl), st = av.style || 0;
    const outfit = ([...OUTFITS[girl ? 'f' : 'm']].find((o) => o[0] === av.outfit) || OUTFITS.m[0])[0];
    const line = '#3A2E5C', sw = 'stroke="' + line + '" stroke-width="1.6" stroke-linejoin="round"';
    const dark = shade(shirt === '#FFFFFF' ? '#DDDDDD' : shirt, .82);
    let hairBack = '', front = '', drape = '', over = '';
    /* ----- الشعر وغطاء الرأس (بإحداثيات الراس: مركز 50،40 نصف قطر 30) ----- */
    if (head === 'hijab') {
      const hc = HEADC[av.hc ?? 0] || HEADC[0];
      drape = `<path d="M18 44 Q16 6 50 6 Q84 6 82 44 Q84 74 70 84 L30 84 Q16 74 18 44Z" fill="${hc}" ${sw}/><path d="M28 80 Q50 92 72 80 L74 92 Q50 100 26 92Z" fill="${shade(hc, .9)}" ${sw}/>`;
    } else if (head === 'shmagh' || head === 'ghutra') {
      const fill = head === 'shmagh' ? 'url(#shmP)' : '#FFFFFF';
      drape = `<defs><pattern id="shmP" width="7" height="7" patternUnits="userSpaceOnUse"><rect width="7" height="7" fill="#fff"/><path d="M0 0h3.5v3.5H0zM3.5 3.5h3.5v3.5H3.5z" fill="#D63031"/></pattern></defs>
        <path d="M14 46 Q12 6 50 6 Q88 6 86 46 L90 90 Q74 84 70 66 L30 66 Q26 84 10 90Z" fill="${fill}" ${sw}/>`;
      over = `<ellipse cx="50" cy="14" rx="31" ry="7" fill="none" stroke="#1E1E24" stroke-width="4"/><ellipse cx="50" cy="8" rx="26" ry="5" fill="none" stroke="#1E1E24" stroke-width="3.4"/>`;
    } else if (head === 'taqiya') {
      over = `<path d="M22 30 Q22 6 50 6 Q78 6 78 30Z" fill="#FFFFFF" ${sw}/><path d="M23 26 H77" stroke="#DDD" stroke-width="1.5"/>`;
    } else if (girl) {
      const bow = SHIRT[((av.shirt || 0) + 3) % SHIRT.length];
      const fringe = `<path d="M20 40 Q20 8 50 8 Q80 8 80 40 Q72 22 56 26 Q46 16 34 28 Q26 30 20 40Z" fill="${hair}" ${sw}/>`;
      if (st === 1) { hairBack = `<path d="M70 18 Q100 22 92 66 Q88 52 76 44Z" fill="${hair}" ${sw}/>`; front = fringe + `<circle cx="74" cy="20" r="5" fill="${bow}" ${sw}/>`; }
      else if (st === 2) { hairBack = [20, 80].map((x) => `<path d="M${x} 42 q-7 11 0 20 q7 9 0 18 q-6 9 0 16" fill="none" stroke="${line}" stroke-width="12.5" stroke-linecap="round"/><path d="M${x} 42 q-7 11 0 20 q7 9 0 18 q-6 9 0 16" fill="none" stroke="${hair}" stroke-width="9.5" stroke-linecap="round"/><circle cx="${x}" cy="97" r="4.5" fill="${bow}" ${sw}/>`).join(''); front = fringe; }
      else if (st === 3) { hairBack = `<path d="M16 46 Q12 6 50 6 Q88 6 84 46 Q84 62 74 64 L26 64 Q16 62 16 46Z" fill="${hair}" ${sw}/>`; front = fringe; }
      else { hairBack = `<path d="M15 44 Q13 5 50 5 Q87 5 85 44 L88 92 Q70 98 66 70 L34 70 Q30 98 12 92Z" fill="${hair}" ${sw}/>`; front = fringe + `<circle cx="76" cy="22" r="5.5" fill="${bow}" ${sw}/>`; }
    } else {
      if (st === 1) front = `<path d="M20 42 Q18 10 50 9 Q82 10 80 42 L75 26 L68 34 L62 18 L55 30 L48 15 L42 30 L35 18 L29 32 L24 24Z" fill="${hair}" ${sw}/>`;
      else if (st === 2) front = [24, 34, 44, 56, 66, 76, 29, 39, 50, 61, 71].map((x, i) => `<circle cx="${x}" cy="${i < 6 ? 22 : 13}" r="${i < 6 ? 8.5 : 7.5}" fill="${hair}" ${sw}/>`).join('') + `<path d="M20 42 Q20 24 30 22 L70 22 Q80 24 80 42 Q72 30 50 28 Q28 30 20 42Z" fill="${hair}"/>`;
      else if (st === 3) front = `<path d="M23 34 Q25 12 50 12 Q75 12 77 34 Q64 24 50 24 Q36 24 23 34Z" fill="${hair}" opacity=".55"/>`;
      else front = `<path d="M19 42 Q17 7 50 7 Q83 7 81 42 Q76 22 60 24 Q50 16 38 24 Q26 24 19 42Z" fill="${hair}" ${sw}/>`;
    }
    /* ----- الجسم واللبس (تحت الراس) ----- */
    const arm = (x, sleeve) => `<path d="M${x} 84 q${x < 50 ? -9 : 9} 6 ${x < 50 ? -8 : 8} 22" stroke="${line}" stroke-width="10" stroke-linecap="round" fill="none"/><path d="M${x} 84 q${x < 50 ? -9 : 9} 6 ${x < 50 ? -8 : 8} 22" stroke="${sleeve}" stroke-width="7.4" stroke-linecap="round" fill="none"/><circle cx="${x < 50 ? x - 8 : x + 8}" cy="107" r="4.4" fill="${skin}" ${sw}/>`;
    const legs = (c) => `<rect x="36" y="112" width="11" height="24" rx="5" fill="${c}" ${sw}/><rect x="53" y="112" width="11" height="24" rx="5" fill="${c}" ${sw}/>`;
    const shoes = `<path d="M33 136 h15 v4 q0 4 -4 4 h-9 q-4 0 -4 -4z" fill="#FFFFFF" ${sw}/><path d="M52 136 h15 v4 q0 4 -4 4 h-9 q-4 0 -4 -4z" fill="#FFFFFF" ${sw}/><path d="M33 141 h15 M52 141 h15" stroke="${shirt === '#FFFFFF' ? '#9B6BF2' : shirt}" stroke-width="2"/>`;
    let body = '';
    if (outfit === 'thobe') {
      body = arm(34, '#FAFAF5') + arm(66, '#FAFAF5') + `<path d="M34 76 Q50 70 66 76 L70 138 L30 138Z" fill="#FAFAF5" ${sw}/><path d="M50 74 V100" stroke="#D8D5CC" stroke-width="1.6"/><circle cx="50" cy="82" r="1.6" fill="#BDB9AE"/><circle cx="50" cy="90" r="1.6" fill="#BDB9AE"/>` + shoes.replace(/#FFFFFF/g, '#5A3B2A');
    } else if (outfit === 'dress') {
      body = arm(34, skin) + arm(66, skin) + legs(skin) + `<path d="M36 76 Q50 70 64 76 L66 92 L78 120 Q50 128 22 120 L34 92Z" fill="${shirt}" ${sw}/><path d="M34 92 Q50 98 66 92" fill="none" stroke="#fff" stroke-width="2" opacity=".7"/>` + shoes;
    } else if (outfit === 'overalls') {
      body = arm(34, shirt) + arm(66, shirt) + legs(pants) + `<path d="M34 76 Q50 70 66 76 L67 114 L33 114Z" fill="${shirt}" ${sw}/><path d="M38 88 H62 V114 H38Z" fill="${pants}" ${sw}/><path d="M38 88 L36 76 M62 88 L64 76" stroke="${pants}" stroke-width="4"/><circle cx="41" cy="92" r="1.8" fill="#FFD93D"/><circle cx="59" cy="92" r="1.8" fill="#FFD93D"/><rect x="45" y="96" width="10" height="8" rx="2" fill="none" stroke="${line}" stroke-width="1.2"/>` + shoes;
    } else if (outfit === 'hoodie') {
      body = arm(34, shirt) + arm(66, shirt) + legs(pants) + `<path d="M33 76 Q50 70 67 76 L68 114 L32 114Z" fill="${shirt}" ${sw}/><path d="M38 76 Q50 88 62 76" fill="none" stroke="${dark}" stroke-width="4"/><rect x="40" y="100" width="20" height="10" rx="4" fill="${dark}"/><path d="M46 82 v9 M54 82 v9" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/>` + shoes;
    } else {
      body = arm(34, skin) + arm(66, skin) + legs(pants) + `<path d="M30 80 L36 75 Q50 70 64 75 L70 80 L66 88 L66 114 L34 114 L34 88Z" fill="${shirt}" ${sw}/><path d="M43 74 Q50 80 57 74" fill="none" stroke="${dark}" stroke-width="2"/>` + shoes;
    }
    const cape = av.acc === 'cape' ? `<path d="M34 78 Q16 112 20 140 L80 140 Q84 112 66 78Z" fill="#FF6B6B" ${sw}/>` : '';
    const face = `<circle cx="50" cy="40" r="30" fill="${skin}" ${sw}/><circle cx="20" cy="44" r="5" fill="${skin}" ${sw}/><circle cx="80" cy="44" r="5" fill="${skin}" ${sw}/><circle cx="50" cy="40" r="28.6" fill="${skin}"/>`;
    const eyes = `<ellipse cx="39" cy="44" rx="4.4" ry="5.2" fill="#2B1B12"/><ellipse cx="61" cy="44" rx="4.4" ry="5.2" fill="#2B1B12"/><circle cx="40.6" cy="42" r="1.6" fill="#fff"/><circle cx="62.6" cy="42" r="1.6" fill="#fff"/>
      <path d="M44 55 Q50 60 56 55" fill="none" stroke="#7A3B1F" stroke-width="2.6" stroke-linecap="round"/><ellipse cx="31" cy="52" rx="5" ry="3.2" fill="#FF7A9C" opacity=".5"/><ellipse cx="69" cy="52" rx="5" ry="3.2" fill="#FF7A9C" opacity=".5"/>`;
    const neck = `<rect x="45" y="66" width="10" height="10" rx="4" fill="${skin}" ${sw}/>`;
    const headGroup = drape && head === 'hijab'
      ? `${drape}<ellipse cx="50" cy="44" rx="22" ry="25" fill="${skin}" ${sw}/>${eyes}`
      : drape ? `${drape}<ellipse cx="50" cy="42" rx="23" ry="25" fill="${skin}" ${sw}/>${eyes}${over}`
      : `${face}${eyes}${front}${over}`;
    const headAcc = `<g transform="translate(50 40) scale(1.07) translate(-50 -54)">${acc(av.acc === 'cape' ? '' : av.acc, false)}</g>`;
    return `<g>${cape}${hairBack}${neck}${body}${headGroup}${headAcc}</g>`;
  }

  /* صورة الشخصية: كاملة، أو الراس والكتفين للأيقونات الصغيرة */
  function avatarSVG(av, g, size = 80) {
    if (size <= 62) return `<svg viewBox="6 2 88 92" width="${size}" height="${Math.round(size * 92 / 88)}" aria-hidden="true">${avatar(av, g)}</svg>`;
    return `<svg viewBox="0 0 100 150" width="${size}" height="${Math.round(size * 1.5)}" aria-hidden="true">${avatar(av, g)}</svg>`;
  }

  /* إكسسوارات تنفتح من «سماء سِراج» (كل كوكبة = إكسسوار) */
  const ACC = [
    { id: 'crown', name: 'تاج', icon: '👑' },
    { id: 'star', name: 'مشبك نجمة', icon: '⭐' },
    { id: 'glasses', name: 'نظارة', icon: '👓' },
    { id: 'cap', name: 'كاب', icon: '🧢' },
    { id: 'flowers', name: 'إكليل ورد', icon: '🌸' },
    { id: 'headphones', name: 'سماعات', icon: '🎧' },
    { id: 'moon', name: 'هلال', icon: '🌙' },
    { id: 'cape', name: 'عباءة بطل', icon: '🦸' }
  ];
  function acc(id, hijab) {
    const top = hijab ? 14 : 20;
    switch (id) {
      case 'crown': return `<path d="M32 ${top + 6} L36 ${top - 10} L44 ${top} L50 ${top - 14} L56 ${top} L64 ${top - 10} L68 ${top + 6}Z" fill="#FFD93D" stroke="#E0A800" stroke-width="1.5"/><circle cx="50" cy="${top - 3}" r="2.6" fill="#FF6B6B"/>`;
      case 'star': return `<path d="M72 ${top + 4} l3.5 7 7.6 1 -5.5 5.3 1.3 7.6 -6.9 -3.6 -6.9 3.6 1.3 -7.6 -5.5 -5.3 7.6 -1z" fill="#FFD93D" stroke="#E0A800" stroke-width="1"/>`;
      case 'glasses': return `<g fill="none" stroke="#2B2350" stroke-width="2.4"><circle cx="40" cy="56" r="8"/><circle cx="60" cy="56" r="8"/><path d="M48 56 h4 M32 54 l-8 -3 M68 54 l8 -3"/></g>`;
      case 'cap': return `<path d="M22 ${top + 22} Q22 ${top - 4} 50 ${top - 4} Q78 ${top - 4} 78 ${top + 22}Z" fill="#4DB8F0"/><path d="M50 ${top + 20} Q78 ${top + 14} 92 ${top + 24} Q72 ${top + 28} 50 ${top + 24}Z" fill="#2E8FCC"/><circle cx="50" cy="${top - 3}" r="3" fill="#2E8FCC"/>`;
      case 'flowers': return [26, 36, 50, 64, 74].map((x, i) => `<circle cx="${x}" cy="${top + (i % 2 ? 0 : 4)}" r="5" fill="${['#FF7AB6', '#FFD93D', '#FF6B6B', '#9B6BF2', '#FF7AB6'][i]}"/><circle cx="${x}" cy="${top + (i % 2 ? 0 : 4)}" r="1.8" fill="#fff"/>`).join('');
      case 'headphones': return `<path d="M20 58 Q20 ${top - 6} 50 ${top - 6} Q80 ${top - 6} 80 58" fill="none" stroke="#2B2350" stroke-width="5"/><rect x="14" y="50" width="11" height="18" rx="5" fill="#FF6B6B"/><rect x="75" y="50" width="11" height="18" rx="5" fill="#FF6B6B"/>`;
      case 'moon': return `<path d="M50 ${top - 16} a9 9 0 1 0 7 15 a7 7 0 1 1 -7 -15z" fill="#FFE27A"/>`;
      case 'cape': return `<path d="M24 88 Q10 110 14 122 L86 122 Q90 110 76 88 Q50 96 24 88Z" fill="#FF6B6B" opacity=".9"/>`;
      default: return '';
    }
  }


  function stars(n, seed, w = 400, h = 200) {
    let s = seed, out = '';
    const r = () => (s = (s * 9301 + 49297) % 233280) / 233280;
    for (let i = 0; i < n; i++) {
      out += `<circle cx="${(r() * w).toFixed(0)}" cy="${(r() * h).toFixed(0)}" r="${(r() * 1.8 + .6).toFixed(1)}" fill="#fff" opacity="${(r() * .6 + .4).toFixed(2)}"/>`;
    }
    return out;
  }

  const SCENES = {
    desert: `<defs><linearGradient id="sd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7B5CD6"/><stop offset="1" stop-color="#FFB36B"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sd)"/><circle cx="315" cy="140" r="34" fill="#FFE29A"/>
      <path d="M0 190 Q100 150 200 185 T400 172 V260 H0Z" fill="#E9A95B"/>
      <path d="M0 218 Q120 188 240 216 T400 204 V260 H0Z" fill="#D98B3F"/>
      <polygon points="40,205 90,145 140,205" fill="#8E5A3C"/><polygon points="80,205 90,170 100,205" fill="#5A3420"/>
      <rect x="352" y="140" width="9" height="70" rx="4" fill="#8B5A2B"/>
      <g fill="#3FAE4A"><ellipse cx="340" cy="140" rx="22" ry="7" transform="rotate(20 340 140)"/><ellipse cx="373" cy="140" rx="22" ry="7" transform="rotate(-20 373 140)"/><ellipse cx="356" cy="132" rx="7" ry="20"/></g>`,
    sea: `<defs><linearGradient id="ss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6CCBF5"/><stop offset="1" stop-color="#D4F3FF"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#ss)"/><circle cx="70" cy="55" r="28" fill="#FFE066"/>
      <g fill="#fff" opacity=".9"><ellipse cx="250" cy="45" rx="34" ry="12"/><ellipse cx="275" cy="38" rx="22" ry="12"/></g>
      <path d="M300 70 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#3B3B5C" stroke-width="2.5"/>
      <rect y="135" width="400" height="90" fill="#2FA4E7"/>
      <path d="M0 140 Q25 130 50 140 T100 140 T150 140 T200 140 T250 140 T300 140 T350 140 T400 140 V150 H0Z" fill="#7FD3F7"/>
      <path d="M20 175 q15 -8 30 0 M200 165 q15 -8 30 0 M300 190 q15 -8 30 0" fill="none" stroke="#BDEBFF" stroke-width="3" stroke-linecap="round"/>
      <path d="M0 214 Q200 192 400 214 V260 H0Z" fill="#F7D9A0"/>`,
    space: `<defs><linearGradient id="sp" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1B1747"/><stop offset="1" stop-color="#4A2F8F"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sp)"/>${stars(55, 7, 400, 260)}
      <circle cx="320" cy="70" r="30" fill="#FF8FB1"/><ellipse cx="320" cy="70" rx="48" ry="11" fill="none" stroke="#FFD93D" stroke-width="5" transform="rotate(-15 320 70)"/>
      <circle cx="60" cy="60" r="16" fill="#4DD8E6"/><circle cx="54" cy="55" r="4" fill="#fff" opacity=".4"/>
      <circle cx="380" cy="220" r="40" fill="#7B5CD6" opacity=".6"/>`,
    garden: `<defs><linearGradient id="sg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9BE1FF"/><stop offset="1" stop-color="#E8FAFF"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sg)"/><circle cx="330" cy="50" r="26" fill="#FFD93D"/>
      <path d="M0 175 Q100 140 200 170 T400 160 V260 H0Z" fill="#8EE065"/>
      <path d="M0 205 Q150 180 300 205 T400 200 V260 H0Z" fill="#5CC24A"/>
      <rect x="330" y="110" width="14" height="70" rx="5" fill="#8B5A2B"/>
      <g fill="#3FAE4A"><circle cx="337" cy="100" r="30"/><circle cx="312" cy="115" r="20"/><circle cx="362" cy="115" r="20"/></g>
      <g><circle cx="40" cy="225" r="7" fill="#FF7AB6"/><circle cx="40" cy="225" r="3" fill="#FFD93D"/>
      <circle cx="80" cy="235" r="7" fill="#9B6BF2"/><circle cx="80" cy="235" r="3" fill="#FFD93D"/>
      <circle cx="250" cy="232" r="7" fill="#FF6B6B"/><circle cx="250" cy="232" r="3" fill="#FFD93D"/></g>`,
    home: `<rect width="400" height="260" fill="#4B3F9E"/>
      <rect x="230" y="30" width="120" height="100" rx="10" fill="#FFD8A8"/><rect x="238" y="38" width="104" height="84" rx="6" fill="#1B1747"/>
      ${'<g>' + stars(14, 3, 100, 80).replace(/cx="(\d+)" cy="(\d+)"/g, (m, x, y) => `cx="${+x + 240}" cy="${+y + 40}"`) + '</g>'}
      <path d="M312 58 a16 16 0 1 0 12 28 a13 13 0 1 1 -12 -28z" fill="#FFF3C4"/>
      <line x1="290" y1="38" x2="290" y2="122" stroke="#FFD8A8" stroke-width="5"/>
      <rect y="205" width="400" height="55" fill="#6D4C9E"/><ellipse cx="160" cy="232" rx="110" ry="16" fill="#FF8FB1" opacity=".5"/>
      <circle cx="40" cy="120" r="34" fill="#FFD93D" opacity=".18"/><path d="M28 132 Q28 118 40 118 Q54 118 58 124 L66 122 Q68 128 60 130 Q56 140 40 140 Q28 140 28 132Z" fill="#FFB547"/>
      <path d="M40 104 Q34 112 37 116 Q40 119 43 116 Q46 112 40 104Z" fill="#FFE27A"/>`,
    school: `<rect width="400" height="260" fill="#FFF1D6"/>
      <rect x="40" y="30" width="230" height="110" rx="8" fill="#8B5A2B"/><rect x="48" y="38" width="214" height="94" rx="4" fill="#2E7D5B"/>
      <text x="155" y="98" text-anchor="middle" font-size="34" fill="#fff" font-family="sans-serif">أ ب ت</text>
      <circle cx="335" cy="65" r="26" fill="#fff" stroke="#FF9F1C" stroke-width="5"/><path d="M335 65 V50 M335 65 H346" stroke="#3B3B5C" stroke-width="3" stroke-linecap="round"/>
      <rect y="200" width="400" height="60" fill="#F2C48D"/>
      <rect x="250" y="170" width="120" height="14" rx="4" fill="#C47A3A"/><rect x="260" y="184" width="8" height="40" fill="#A0602A"/><rect x="352" y="184" width="8" height="40" fill="#A0602A"/>`,
    night: `<defs><radialGradient id="sn" cx=".5" cy=".3" r=".8"><stop offset="0" stop-color="#3B2A7A"/><stop offset="1" stop-color="#120F33"/></radialGradient></defs>
      <rect width="400" height="260" fill="url(#sn)"/>${stars(70, 11, 400, 260)}
      <path d="M200 40 a55 55 0 1 0 40 95 a44 44 0 1 1 -40 -95z" fill="#FFF3C4"/>`,
    mosque: `<defs><linearGradient id="sm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6E5AD8"/><stop offset="1" stop-color="#FFB37A"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sm)"/>${stars(10, 5, 400, 70)}
      <rect x="215" y="105" width="150" height="110" fill="#F7EEDC"/>
      <path d="M240 108 Q240 55 290 52 Q340 55 340 108Z" fill="#2E9E6B"/><circle cx="290" cy="46" r="5" fill="#FFD93D"/>
      <rect x="360" y="60" width="18" height="155" fill="#F7EEDC"/><path d="M356 60 L369 36 L382 60Z" fill="#2E9E6B"/>
      <path d="M369 26 a6 6 0 1 0 5 9 a5 5 0 1 1 -5 -9z" fill="#FFD93D"/>
      <path d="M272 215 V170 Q290 148 308 170 V215Z" fill="#8B5A2B"/>
      <path d="M232 160 Q232 145 245 145 Q258 145 258 160 V180 H232Z M322 160 Q322 145 335 145 Q348 145 348 160 V180 H322Z" fill="#7FD3F7"/>
      <rect y="212" width="400" height="48" fill="#E9D3A8"/>`,
    park: `<defs><linearGradient id="sk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FDBFF"/><stop offset="1" stop-color="#E6F9FF"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sk)"/><circle cx="60" cy="50" r="24" fill="#FFD93D"/>
      <g fill="#fff" opacity=".9"><ellipse cx="190" cy="40" rx="30" ry="10"/><ellipse cx="210" cy="33" rx="18" ry="10"/></g>
      <path d="M0 190 Q200 165 400 190 V260 H0Z" fill="#7ED957"/>
      <path d="M240 200 L270 95 L300 200 M270 95 H360 M330 95 L360 200 M360 95 L390 200" fill="none" stroke="#FF6B6B" stroke-width="6" stroke-linecap="round"/>
      <path d="M300 95 V160 M320 95 V160" stroke="#3B3B5C" stroke-width="2"/><rect x="295" y="158" width="30" height="7" rx="3" fill="#4DB8F0"/>
      <path d="M20 205 L60 130 H80 L80 205" fill="none" stroke="#9B6BF2" stroke-width="6"/><path d="M80 130 Q120 150 140 205" fill="none" stroke="#FFD93D" stroke-width="10" stroke-linecap="round"/>`,
    market: `<rect width="400" height="260" fill="#FFF0F5"/>
      <rect x="20" y="20" width="360" height="22" rx="8" fill="#FF7AB6"/><text x="200" y="37" text-anchor="middle" font-size="15" fill="#fff" font-family="sans-serif">سوق</text>
      <g>${[60, 110, 160].map((y, i) => `<rect x="30" y="${y}" width="340" height="6" fill="#C47A3A"/>` + [0, 1, 2, 3, 4, 5, 6, 7].map((k) => `<rect x="${40 + k * 41}" y="${y - 26}" width="30" height="26" rx="4" fill="${['#FF6B6B', '#4CD97B', '#FFD93D', '#4DB8F0', '#9B6BF2', '#FF9F1C'][(k + i) % 6]}"/>`).join('')).join('')}</g>
      <rect y="205" width="400" height="55" fill="#E8DFF5"/>
      <path d="M300 180 h60 l-8 30 h-44z" fill="none" stroke="#6E668F" stroke-width="5"/><circle cx="312" cy="218" r="6" fill="#6E668F"/><circle cx="346" cy="218" r="6" fill="#6E668F"/>`,
    road: `<defs><linearGradient id="sr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9BD9FF"/><stop offset="1" stop-color="#F2FBFF"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sr)"/><circle cx="340" cy="45" r="22" fill="#FFD93D"/>
      ${[[20, '#FFB5A7', 90], [110, '#B8E0D2', 70], [190, '#FFE5A5', 100], [290, '#D6C5F0', 80]].map(([x, c, h]) => `<rect x="${x}" y="${180 - h}" width="80" height="${h}" fill="${c}"/><rect x="${x + 30}" y="${150}" width="20" height="30" fill="#8B5A2B"/><rect x="${x + 10}" y="${190 - h}" width="16" height="16" fill="#fff"/><rect x="${x + 54}" y="${190 - h}" width="16" height="16" fill="#fff"/>`).join('')}
      <rect y="180" width="400" height="22" fill="#D9D3C7"/><rect y="202" width="400" height="58" fill="#5A5A6E"/>
      <path d="M10 232 H50 M90 232 H130 M170 232 H210 M250 232 H290 M330 232 H370" stroke="#FFD93D" stroke-width="5"/>`,
    mountain: `<defs><linearGradient id="sh" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A5E1FF"/><stop offset="1" stop-color="#EAFBFF"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sh)"/>
      <path d="M0 170 L80 70 L150 150 L230 50 L320 140 L400 80 V260 H0Z" fill="#5CAE6A"/>
      <path d="M0 200 L100 120 L190 190 L290 110 L400 180 V260 H0Z" fill="#3E9150"/>
      <path d="M232 52 Q236 120 240 190" stroke="#DFF6FF" stroke-width="6" fill="none"/>
      <g fill="#fff" opacity=".75"><ellipse cx="120" cy="110" rx="60" ry="12"/><ellipse cx="300" cy="95" rx="70" ry="12"/></g>
      ${[30, 70, 330, 370].map((x) => `<path d="M${x} 230 l14 -38 l14 38z" fill="#2A6E3A"/>`).join('')}
      <path d="M40 30 L360 70" stroke="#6E668F" stroke-width="2"/><rect x="180" y="45" width="26" height="20" rx="4" fill="#FF6B6B"/>`,
    /* v2.5 مشاهد تراثية لقصص الأنبياء (بلا أي أشخاص) */
    hills: `<defs><linearGradient id="sl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F7C98B"/><stop offset="1" stop-color="#FFF0D6"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sl)"/><circle cx="80" cy="60" r="26" fill="#FFE08A"/>
      <path d="M0 175 L70 85 L120 130 L200 45 L270 125 L330 75 L400 140 V260 H0Z" fill="#B9825A"/>
      <path d="M200 45 L215 70 L190 72Z M70 85 L82 100 L60 102Z" fill="#D6A27A"/>
      <path d="M0 210 L90 150 L170 200 L260 155 L400 205 V260 H0Z" fill="#8C5E3C"/>
      <path d="M0 232 Q200 214 400 232 V260 H0Z" fill="#E9B97A"/>
      <path d="M150 128 q10 -14 20 0z" fill="#4A2F1F" opacity=".7"/>`,
    souq: `<defs><linearGradient id="so" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFD9A0"/><stop offset="1" stop-color="#FFF4E0"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#so)"/>
      <rect y="70" width="400" height="140" fill="#E8C49A"/>
      ${[0, 1, 2].map((k) => `<path d="M${20 + k * 130} 210 V115 Q${75 + k * 130} 70 ${130 + k * 130} 115 V210Z" fill="#C99566"/><path d="M${34 + k * 130} 210 V122 Q${75 + k * 130} 88 ${116 + k * 130} 122 V210Z" fill="#7A4E2D"/>`).join('')}
      ${[0, 1, 2].map((k) => `<path d="M${10 + k * 130} 120 L${140 + k * 130} 120 L${130 + k * 130} 140 L${20 + k * 130} 140Z" fill="${['#E85D5D', '#4DB8A8', '#F2B84B'][k]}"/><path d="M${10 + k * 130} 140 ${[0, 1, 2, 3, 4, 5].map((j) => `q${10.8} 10 ${21.6} 0`).join(' ')}" fill="${['#E85D5D', '#4DB8A8', '#F2B84B'][k]}"/>`).join('')}
      <rect y="208" width="400" height="52" fill="#D9A86C"/>
      ${[40, 70, 175, 300, 330].map((x, i) => `<path d="M${x} 222 q-12 0 -12 -14 q0 -12 12 -16 q12 4 12 16 q0 14 -12 14z" fill="${i % 2 ? '#B5643B' : '#C97B4A'}"/><rect x="${x - 4}" y="188" width="8" height="6" fill="#8C4A2A"/>`).join('')}
      <ellipse cx="240" cy="222" rx="26" ry="8" fill="#8C5E3C"/><g fill="#F2C94C">${[226, 236, 246, 256].map((x) => `<circle cx="${x}" cy="216" r="5"/>`).join('')}</g>`,
    oldhome: `<rect width="400" height="260" fill="#C9A27A"/>
      <g fill="#B88E66" opacity=".7">${Array.from({ length: 18 }, (_, k) => `<rect x="${(k * 67) % 400}" y="${20 + ((k * 41) % 150)}" width="34" height="12" rx="3"/>`).join('')}</g>
      <path d="M250 150 V80 Q290 40 330 80 V150Z" fill="#241C4A"/>${stars(14, 9, 400, 140).replace(/<circle cx="(\d+)" cy="(\d+)"/g, (m, x, y) => (+x > 254 && +x < 326 && +y > 70 && +y < 148 ? m : '<circle cx="-9" cy="-9"'))}
      <path d="M296 92 a10 10 0 1 0 8 16 a8 8 0 1 1 -8 -16z" fill="#FFE27A"/>
      <path d="M250 150 V80 Q290 40 330 80 V150" fill="none" stroke="#8C5E3C" stroke-width="6"/>
      <rect y="200" width="400" height="60" fill="#9C6B45"/><rect x="40" y="212" width="250" height="34" rx="6" fill="#B5333A"/>
      <path d="M40 220 H290 M40 238 H290" stroke="#F2C94C" stroke-width="3" stroke-dasharray="8 6"/>
      <path d="M78 118 q14 -8 28 0 l-4 10 h-20z" fill="#C98B3A"/><path d="M92 104 q5 6 0 12 q-5 -6 0 -12z" fill="#FFB52E"/><circle cx="92" cy="112" r="16" fill="#FFD27A" opacity=".25"/>`,
    fields: `<defs><linearGradient id="si" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9BE1FF"/><stop offset="1" stop-color="#FFF8E1"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#si)"/><circle cx="60" cy="50" r="24" fill="#FFD93D"/>
      <path d="M0 175 Q200 155 400 175 V260 H0Z" fill="#E8C35A"/>
      <g stroke="#C9962E" stroke-width="3" stroke-linecap="round">${Array.from({ length: 26 }, (_, k) => { const x = 8 + k * 15, y = 190 + (k % 3) * 8; return `<line x1="${x}" y1="${y + 40}" x2="${x}" y2="${y}"/><ellipse cx="${x}" cy="${y - 4}" rx="3.5" ry="8" fill="#F2C94C" stroke="none"/>`; }).join('')}</g>
      ${[300, 350].map((x) => `<path d="M${x} 175 q4 -50 0 -90" stroke="#8C5E3C" stroke-width="7" fill="none"/><g fill="#3E9150">${[-60, -25, 15, 50].map((a) => `<path d="M${x} 85 q${a * .9} ${-10 + Math.abs(a) * .2} ${a * 1.2} ${20 + Math.abs(a) * .3}" stroke="#3E9150" stroke-width="7" fill="none" stroke-linecap="round"/>`).join('')}</g>`).join('')}`,
    farm: `<defs><linearGradient id="sf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9BE1FF"/><stop offset="1" stop-color="#FFF8E1"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sf)"/><circle cx="60" cy="50" r="24" fill="#FFD93D"/>
      <path d="M0 180 Q200 160 400 180 V260 H0Z" fill="#9BD86A"/>
      <rect x="250" y="95" width="110" height="90" fill="#E84A4A"/><path d="M240 100 L305 55 L370 100Z" fill="#B83232"/>
      <rect x="285" y="135" width="40" height="50" fill="#fff"/><path d="M285 135 L325 185 M325 135 L285 185" stroke="#E84A4A" stroke-width="4"/>
      <g stroke="#C47A3A" stroke-width="5">${[0, 1, 2, 3, 4].map((k) => `<line x1="${20 + k * 40}" y1="185" x2="${20 + k * 40}" y2="215"/>`).join('')}<line x1="10" y1="195" x2="190" y2="195"/><line x1="10" y1="208" x2="190" y2="208"/></g>
      <ellipse cx="220" cy="215" rx="22" ry="14" fill="#F2C94C"/>`,
    kitchen: `<rect width="400" height="260" fill="#FFF6E5"/>
      <g fill="#FFE0B2">${[0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map((k) => `<rect x="${k * 40 + 2}" y="120" width="36" height="36"/>`).join('')}</g>
      <rect x="20" y="20" width="160" height="70" rx="6" fill="#FF9F1C"/><line x1="100" y1="20" x2="100" y2="90" stroke="#E07E00" stroke-width="3"/>
      <rect x="230" y="20" width="110" height="80" rx="6" fill="#BDEBFF" stroke="#fff" stroke-width="6"/>
      <rect y="160" width="400" height="20" fill="#C47A3A"/><rect y="180" width="400" height="80" fill="#4DB8F0"/>
      ${[40, 140, 240, 340].map((x) => `<circle cx="${x}" cy="220" r="4" fill="#fff"/>`).join('')}
      <path d="M260 160 h50 v-22 a25 8 0 0 0 -50 0z" fill="#6E668F"/><path d="M275 120 q5 -10 0 -18 M295 120 q5 -10 0 -18" stroke="#fff" stroke-width="3" fill="none" opacity=".8"/>`,
    rain: `<defs><linearGradient id="sw" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7C8DB5"/><stop offset="1" stop-color="#C9D6F0"/></linearGradient></defs>
      <rect width="400" height="260" fill="url(#sw)"/>
      <g fill="#5E6C92"><ellipse cx="100" cy="45" rx="70" ry="25"/><ellipse cx="150" cy="35" rx="45" ry="22"/><ellipse cx="290" cy="50" rx="80" ry="26"/><ellipse cx="340" cy="38" rx="45" ry="20"/></g>
      <g stroke="#E6F2FF" stroke-width="2.5" stroke-linecap="round" opacity=".8">${Array.from({ length: 40 }, (_, k) => { const x = (k * 53) % 400, y = 75 + ((k * 37) % 120); return `<line x1="${x}" y1="${y}" x2="${x - 5}" y2="${y + 14}"/>`; }).join('')}</g>
      <rect y="205" width="400" height="55" fill="#6B7A9E"/><ellipse cx="300" cy="230" rx="50" ry="8" fill="#9FB4E0"/>
      <rect x="250" y="160" width="100" height="40" rx="10" fill="#FF6B6B"/><circle cx="270" cy="203" r="10" fill="#333"/><circle cx="330" cy="203" r="10" fill="#333"/>`
  };

  function page(sceneName, prop, heroes) {
    // كل رسمة تاخذ معرّفات خاصة فيها عشان ما تتعارض التدرجات بين الرسومات
    const u = 'g' + (++page.n);
    const scene = (SCENES[sceneName] || SCENES.home).replace(/id="(s\w)"/g, `id="$1${u}"`).replace(/url\(#(s\w)\)/g, `url(#$1${u})`);
    let people = '';
    if (heroes && heroes.length) {
      const [main, ...rest] = heroes;
      rest.slice(0, 3).forEach((k, i) => {
        const x = 26 + i * 58;
        people += `<g transform="translate(${x} 168) scale(.6)"><g class="bob b${i + 2}">${avatar(k.av, k.g)}</g></g>`;
      });
      const mx = rest.length ? 26 + Math.min(rest.length, 3) * 58 + 6 : 132;
      people += `<g transform="translate(${mx} 120) scale(.92)"><g class="bob b1">${avatar(main.av, main.g)}</g></g>`;
    }
    const p = prop ? `<g class="floaty"><text x="318" y="210" font-size="62" text-anchor="middle">${prop}</text></g>` : '';
    return `<svg viewBox="0 0 400 260" preserveAspectRatio="xMidYMid slice" class="art"><g class="scene">${scene}</g>${people}${p}</svg>`;
  }

  page.n = 0;
  return { avatar, avatarSVG, page, SKIN, HAIR, SHIRT, PANTS, DEFAULTS, HEADC, STYLES, HEADS, OUTFITS, headOf, ACC, SCENES: Object.keys(SCENES) };
})();

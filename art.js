/* سِراج | SIRAJ — الرسومات: الشخصيات والمشاهد (SVG) */
const ART = (() => {
  const SKIN = ['#FDDCC0', '#F1C08F', '#D9A06B', '#A96F45'];
  const HAIR = ['#2B1B12', '#5A3420', '#9C5B2E', '#E0B062'];
  const SHIRT = ['#FF6B6B', '#FF9F1C', '#FFD93D', '#4CD97B', '#4DB8F0', '#9B6BF2', '#FF7AB6'];

  function avatar(av, g) {
    const skin = SKIN[av.skin ?? 0], hair = HAIR[av.hair ?? 0], shirt = SHIRT[av.shirt ?? 0];
    const girl = g === 'f';
    let back = '', front = '';
    if (girl && av.hijab) {
      back = `<path d="M15 56 Q15 13 50 13 Q85 13 85 56 Q85 92 50 98 Q15 92 15 56Z" fill="${shirt}"/>
              <path d="M15 56 Q15 13 50 13 Q85 13 85 56 Q85 92 50 98 Q15 92 15 56Z" fill="#fff" opacity=".25"/>`;
    } else if (girl) {
      back = `<path d="M19 54 Q17 17 50 17 Q83 17 81 54 L83 92 Q67 96 64 74 L36 74 Q33 96 17 92Z" fill="${hair}"/>`;
      front = `<path d="M23 48 Q25 21 50 21 Q75 21 77 48 Q64 33 50 37 Q36 33 23 48Z" fill="${hair}"/>
               <circle cx="74" cy="34" r="6" fill="${SHIRT[((av.shirt || 0) + 3) % SHIRT.length]}"/>`;
    } else {
      front = `<path d="M21 52 Q19 19 50 19 Q81 19 79 52 Q74 35 50 34 Q28 35 21 52Z" fill="${hair}"/>`;
    }
    const face = girl && av.hijab
      ? `<ellipse cx="50" cy="56" rx="23" ry="26" fill="${skin}"/>`
      : `<circle cx="50" cy="54" r="28" fill="${skin}"/>`;
    return `<g>
      <path d="M18 122 Q18 84 50 84 Q82 84 82 122Z" fill="${shirt}"/>
      <rect x="44" y="76" width="12" height="12" rx="5" fill="${skin}"/>
      ${back}${face}${front}
      <circle cx="40" cy="56" r="3.8" fill="#2B1B12"/><circle cx="60" cy="56" r="3.8" fill="#2B1B12"/>
      <circle cx="41.3" cy="54.6" r="1.2" fill="#fff"/><circle cx="61.3" cy="54.6" r="1.2" fill="#fff"/>
      <path d="M42 66 Q50 73 58 66" fill="none" stroke="#7A3B1F" stroke-width="3" stroke-linecap="round"/>
      <circle cx="33" cy="64" r="5" fill="#FF7A9C" opacity=".45"/><circle cx="67" cy="64" r="5" fill="#FF7A9C" opacity=".45"/>
    </g>`;
  }

  function avatarSVG(av, g, size = 80) {
    return `<svg viewBox="0 0 100 122" width="${size}" height="${size * 1.22}" aria-hidden="true">${avatar(av, g)}</svg>`;
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
        const x = 30 + i * 62;
        people += `<g transform="translate(${x} 170) scale(.68)">${avatar(k.av, k.g)}</g>`;
      });
      const mx = rest.length ? 30 + Math.min(rest.length, 3) * 62 + 4 : 120;
      people += `<g transform="translate(${mx} 128) scale(1.05)">${avatar(main.av, main.g)}</g>`;
    }
    const p = prop ? `<text x="318" y="210" font-size="62" text-anchor="middle">${prop}</text>` : '';
    return `<svg viewBox="0 0 400 260" preserveAspectRatio="xMidYMid slice" class="art">${scene}${people}${p}</svg>`;
  }

  page.n = 0;
  return { avatar, avatarSVG, page, SKIN, HAIR, SHIRT };
})();

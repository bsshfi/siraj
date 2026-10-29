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
      <path d="M200 40 a55 55 0 1 0 40 95 a44 44 0 1 1 -40 -95z" fill="#FFF3C4"/>`
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

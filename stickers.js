/* سِراج | SIRAJ — v5.0 أيقونات ملصقات موحّدة + القمر اللي يقرأ + لفّ الإيموجي بإطار ملصق في الواجهة */
const Stk = (() => {
  const D = '#3B2A20';
  const W = (inner, vb = '0 0 48 48') => `<svg class="stkv" viewBox="${vb}" aria-hidden="true">${inner}</svg>`;
  const I = {
    cal: (d) => W(`<rect x="7" y="10" width="34" height="31" rx="6" fill="#fff"/><rect x="7" y="10" width="34" height="11" rx="5" fill="#FF6B6B"/><rect x="7" y="17" width="34" height="4" fill="#FF6B6B"/><rect x="15" y="6" width="4" height="9" rx="2" fill="#7A4BE0"/><rect x="29" y="6" width="4" height="9" rx="2" fill="#7A4BE0"/><text x="24" y="37" text-anchor="middle" font-family="Poppins,sans-serif" font-weight="800" font-size="14" fill="#2B2350">${d}</text>`),
    autumn: () => W(`<path d="M24 6c8 6 14 13 14 21 0 8-6 14-14 14S10 35 10 27c0-8 6-15 14-21z" fill="#F08A2C"/><path d="M24 10v31M24 22l-7-5M24 28l8-6M24 34l-6-4" stroke="#C25E12" stroke-width="2" stroke-linecap="round" fill="none"/><path d="M33 9c4 3 7 7 7 12-5 0-8-3-9-7" fill="#8BC34A"/>`),
    winter: () => W(`<g stroke="#5AA9EE" stroke-width="3.5" stroke-linecap="round"><path d="M24 6v36M8.4 15l31.2 18M8.4 33l31.2-18"/><path d="M19 9l5 4 5-4M19 39l5-4 5 4M9 21l6-1-2-6M39 27l-6 1 2 6M9 27l6 1-2 6M39 21l-6-1 2-6"/></g>`),
    spring: () => W(`<g fill="#FF8FC4"><circle cx="24" cy="13" r="8"/><circle cx="35" cy="22" r="8"/><circle cx="31" cy="35" r="8"/><circle cx="17" cy="35" r="8"/><circle cx="13" cy="22" r="8"/></g><circle cx="24" cy="25" r="6" fill="#FFD23F"/>`),
    summer: () => W(`<g stroke="#FFB300" stroke-width="3.5" stroke-linecap="round"><path d="M24 4v6M24 38v6M4 24h6M38 24h6M10 10l4 4M34 34l4 4M38 10l-4 4M14 34l-4 4"/></g><circle cx="24" cy="24" r="11" fill="#FFD23F"/><path d="M19 25q5 5 10 0" stroke="${D}" stroke-width="2" fill="none" stroke-linecap="round"/>`),
    plane: () => W(`<path d="M6 27l36-15-9 26-8-8-6 8v-11z" fill="#5AA9EE"/><path d="M19 27l23-15-17 18z" fill="#2E7FD0"/><path d="M19 27v11l6-8z" fill="#1F5FA8"/>`),
    planet: () => W(`<circle cx="24" cy="24" r="12" fill="#B57BEA"/><path d="M14 20c4-2 8 1 12 0s6-3 9-1M14 28c5 1 8-1 12 0s7 2 9 0" stroke="#8B4FD0" stroke-width="2" fill="none"/><ellipse cx="24" cy="26" rx="21" ry="6" fill="none" stroke="#FFB547" stroke-width="3.5" transform="rotate(-15 24 26)"/><circle cx="24" cy="24" r="12" fill="none"/>`),
    books: () => W(`<rect x="6" y="14" width="10" height="28" rx="2" fill="#FF6B6B"/><rect x="17" y="10" width="10" height="32" rx="2" fill="#5B8DEF"/><rect x="29" y="15" width="10" height="27" rx="2" fill="#4CD97B" transform="rotate(12 34 28)"/><path d="M8 20h6M19 16h6M19 36h6" stroke="#fff" stroke-width="2"/>`),
    abc: () => W(`<rect x="5" y="19" width="20" height="20" rx="4" fill="#FF6B6B"/><text x="15" y="35" text-anchor="middle" font-family="Poppins,sans-serif" font-weight="800" font-size="14" fill="#fff">A</text><rect x="23" y="8" width="20" height="20" rx="4" fill="#5B8DEF" transform="rotate(8 33 18)"/><text x="33.5" y="24" text-anchor="middle" font-family="Poppins,sans-serif" font-weight="800" font-size="13" fill="#fff" transform="rotate(8 33 18)">b</text>`),
    palette: () => W(`<path d="M24 6C13 6 5 14 5 24s8 18 17 18c3 0 4-2 3-4-1-3 1-5 4-5h5c6 0 9-4 9-9C43 13 35 6 24 6z" fill="#FFD9A0"/><circle cx="15" cy="20" r="4" fill="#FF6B6B"/><circle cx="23" cy="14" r="4" fill="#FFD23F"/><circle cx="32" cy="16" r="4" fill="#4CD97B"/><circle cx="35" cy="25" r="4" fill="#5B8DEF"/>`),
    gear: () => W(`<path d="M24 6l4 1 1 5 4 2 4-3 3 3-3 4 2 4 5 1v6l-5 1-2 4 3 4-3 3-4-3-4 2-1 5h-6l-1-5-4-2-4 3-3-3 3-4-2-4-5-1v-6l5-1 2-4-3-4 3-3 4 3 4-2 1-5z" fill="#8E9AAF"/><circle cx="24" cy="24" r="7" fill="#fff"/>`),
    letter: () => W(`<rect x="6" y="12" width="36" height="26" rx="5" fill="#FF8FC4"/><path d="M7 14l17 13 17-13" stroke="#fff" stroke-width="3" fill="none" stroke-linejoin="round"/><path d="M24 33c-3-2-5-3.5-5-5.5a2.5 2.5 0 0 1 5-1 2.5 2.5 0 0 1 5 1c0 2-2 3.5-5 5.5z" fill="#fff"/>`),
    gift: () => W(`<rect x="7" y="20" width="34" height="21" rx="4" fill="#FF6B6B"/><rect x="5" y="14" width="38" height="9" rx="3" fill="#FF8A8A"/><rect x="21" y="14" width="6" height="27" fill="#FFD23F"/><path d="M24 14c-4-7-12-7-11-2 1 3 7 2 11 2zM24 14c4-7 12-7 11-2-1 3-7 2-11 2z" fill="#FFD23F"/>`),
    refresh: () => W(`<path d="M38 22A14 14 0 1 0 34 34" stroke="#4CD97B" stroke-width="5" fill="none" stroke-linecap="round"/><path d="M40 10v13H27z" fill="#4CD97B"/>`),
    passport: () => W(`<rect x="10" y="6" width="28" height="36" rx="4" fill="#0E7A43"/><circle cx="24" cy="21" r="7" fill="none" stroke="#FFD23F" stroke-width="2"/><path d="M17 21h14M24 14c-3 4-3 10 0 14M24 14c3 4 3 10 0 14" stroke="#FFD23F" stroke-width="1.5" fill="none"/><rect x="16" y="33" width="16" height="3" rx="1.5" fill="#FFD23F"/>`),
    flag: () => W(`<rect x="9" y="6" width="4" height="36" rx="2" fill="#8A5A3B"/><path d="M13 8c8-3 12 3 22 0v17c-10 3-14-3-22 0z" fill="#FF6B6B"/><circle cx="24" cy="16" r="3.5" fill="#fff"/>`),
    landmark: () => W(`<path d="M24 5L5 15h38z" fill="#FFB547"/><rect x="7" y="15" width="34" height="4" fill="#E0922A"/><g fill="#FFD9A0"><rect x="10" y="20" width="5" height="16"/><rect x="19" y="20" width="5" height="16"/><rect x="28" y="20" width="5" height="16"/><rect x="36" y="20" width="3" height="16"/></g><rect x="5" y="36" width="38" height="6" rx="1" fill="#E0922A"/>`),
    star: () => W(`<path d="M24 4l6 13 14 1.5-10.5 9.5 3 14L24 35l-12.5 7 3-14L4 18.5 18 17z" fill="#FFD23F"/><path d="M19 25q5 4 10 0" stroke="${D}" stroke-width="2" fill="none" stroke-linecap="round"/><circle cx="19" cy="21" r="1.8" fill="${D}"/><circle cx="29" cy="21" r="1.8" fill="${D}"/>`),
    shield: () => W(`<path d="M24 5l16 6v11c0 10-7 17-16 21C15 39 8 32 8 22V11z" fill="#5B8DEF"/><path d="M24 5l16 6v11c0 10-7 17-16 21z" fill="#4373D6"/><path d="M17 23l5 5 9-10" stroke="#fff" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`),
    medal: () => W(`<path d="M14 4h8l4 12h-8zM34 4h-8l-4 12h8z" fill="#5B8DEF"/><circle cx="24" cy="30" r="13" fill="#FFB547"/><circle cx="24" cy="30" r="9" fill="#FFD23F"/><path d="M24 24l2 4 4.5.5-3.3 3 1 4.4-4.2-2.4-4.2 2.4 1-4.4-3.3-3 4.5-.5z" fill="#fff"/>`),
    trophy: () => W(`<path d="M14 8h20v10a10 10 0 0 1-20 0z" fill="#FFD23F"/><path d="M14 11H7c0 7 4 10 8 10M34 11h7c0 7-4 10-8 10" stroke="#FFB300" stroke-width="3" fill="none"/><rect x="21" y="27" width="6" height="7" fill="#FFB300"/><rect x="14" y="34" width="20" height="7" rx="2" fill="#8A5A3B"/>`),
    chart: () => W(`<rect x="6" y="6" width="36" height="36" rx="7" fill="#fff"/><rect x="12" y="24" width="6" height="12" rx="2" fill="#5B8DEF"/><rect x="21" y="16" width="6" height="20" rx="2" fill="#FF8FC4"/><rect x="30" y="11" width="6" height="25" rx="2" fill="#4CD97B"/>`)
  };
  const icon = (name, arg) => (I[name] ? I[name](arg) : '');

  /* القمر اللي يقرأ كتاب ويجلس على غيمة */
  function moonReader() {
    return `<svg class="moonread" viewBox="0 0 220 190" aria-hidden="true"><defs>
      <radialGradient id="mrGlow" cx="50%" cy="45%" r="50%"><stop offset="0" stop-color="#FFF6C8" stop-opacity=".95"/><stop offset=".55" stop-color="#FFE9A0" stop-opacity=".35"/><stop offset="1" stop-color="#FFE9A0" stop-opacity="0"/></radialGradient>
      <radialGradient id="mrMoon" cx="38%" cy="32%" r="70%"><stop offset="0" stop-color="#FFF3B8"/><stop offset=".6" stop-color="#FFDF72"/><stop offset="1" stop-color="#F4C24A"/></radialGradient>
      <linearGradient id="mrBook" x1="0" x2="1"><stop offset="0" stop-color="#6D45D9"/><stop offset="1" stop-color="#8E5BEA"/></linearGradient></defs>
      <circle cx="112" cy="84" r="92" fill="url(#mrGlow)"/>
      <g class="mrb">
        <circle cx="112" cy="80" r="62" fill="url(#mrMoon)"/>
        <g fill="#F7D35E" opacity=".75"><circle cx="78" cy="58" r="9"/><circle cx="150" cy="56" r="7"/><circle cx="140" cy="104" r="6"/><circle cx="74" cy="100" r="5"/><circle cx="160" cy="84" r="4"/></g>
        <path d="M88 74q8-9 16 0M122 74q8-9 16 0" stroke="#3B2A20" stroke-width="4.2" fill="none" stroke-linecap="round"/>
        <ellipse cx="84" cy="88" rx="9" ry="6" fill="#FF9AA8" opacity=".75"/><ellipse cx="142" cy="88" rx="9" ry="6" fill="#FF9AA8" opacity=".75"/>
        <path d="M100 88q13 16 26 0z" fill="#B23A48"/><path d="M106 95q7 5 14 0q-7-5-14 0z" fill="#FF7A8A"/>
        <path d="M150 32l2.5 5.5 6 .6-4.5 4 1.3 6-5.3-3-5.3 3 1.3-6-4.5-4 6-.6z" fill="#fff" opacity=".9"/>
      </g>
      <g class="mrleaf"><path d="M40 150c-6-18 4-34 20-36-2 16-8 28-20 36z" fill="#4CAF50"/><path d="M40 150c4-12 10-22 20-36" stroke="#2E7D32" stroke-width="2" fill="none"/><path d="M52 156c2-16 16-24 30-20-6 12-16 20-30 20z" fill="#66BB6A"/></g>
      <g class="mrcloud" fill="#fff"><ellipse cx="66" cy="160" rx="40" ry="18"/><ellipse cx="112" cy="150" rx="46" ry="24"/><ellipse cx="164" cy="160" rx="40" ry="18"/><ellipse cx="112" cy="168" rx="80" ry="16"/></g>
      <g fill="#E4DDF9" opacity=".85"><ellipse cx="112" cy="174" rx="78" ry="8"/></g>
      <g class="mrbk" transform="translate(4 14) scale(.96)">
        <path d="M80 128l32 6 32-6v-30l-32 6-32-6z" fill="url(#mrBook)"/>
        <path d="M84 125l28 5V104l-28-5z" fill="#fff"/><path d="M140 125l-28 5V104l28-5z" fill="#FBF7FF"/>
        <path d="M89 106l18 3.4M89 112l18 3.4M89 118l18 3.4" stroke="#D5CBEF" stroke-width="1.6"/>
        <circle cx="126" cy="114" r="6" fill="#E85A8A" opacity=".85"/>
        <ellipse cx="80" cy="114" rx="9" ry="10" fill="#FFD966"/><ellipse cx="144" cy="114" rx="9" ry="10" fill="#FFD966"/>
      </g>
      <g fill="#FFE27A"><path d="M34 40l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"/><path d="M196 110l1.6 4 4 1.6-4 1.6-1.6 4-1.6-4-4-1.6 4-1.6z"/><path d="M190 24l1.4 3.4 3.4 1.4-3.4 1.4-1.4 3.4-1.4-3.4-3.4-1.4 3.4-1.4z"/></g>
    </svg>`;
  }

  /* غيوم ونجوم خلف الرأس */
  function skyfx() {
    const st = [[8, 14, 16], [30, 6, 10], [55, 18, 9], [72, 8, 14], [90, 20, 11], [18, 40, 8], [62, 36, 10], [84, 44, 8]]
      .map(([l, t, w], i) => `<i style="left:${l}%;top:${t}%;width:${w}px;height:${w}px;animation-delay:${-i * .7}s"><svg viewBox="0 0 20 20"><path d="M10 0l2.6 6.4L19 7.6l-4.8 4.3L15.5 19 10 15.6 4.5 19l1.3-7.1L1 7.6l6.4-1.2z" fill="#FFE27A"/></svg></i>`).join('');
    return `<div class="skyfx" aria-hidden="true">${st}<svg class="skycl" viewBox="0 0 400 90" preserveAspectRatio="none"><g fill="#fff" opacity=".85"><ellipse cx="40" cy="70" rx="70" ry="30"/><ellipse cx="120" cy="80" rx="70" ry="24"/><ellipse cx="330" cy="72" rx="80" ry="30"/><ellipse cx="400" cy="60" rx="50" ry="30"/></g><g fill="#fff" opacity=".55"><ellipse cx="230" cy="84" rx="90" ry="18"/></g></svg></div>`;
  }

  /* لفّ الإيموجي في عناصر الواجهة بإطار ملصق أبيض (بدون ما نلمس نص القصص) */
  let RX;
  try { RX = new RegExp('((?:\\p{Regional_Indicator}{2})|(?:\\p{Extended_Pictographic}(?:\\uFE0F|\\u20E3|[\\u{1F3FB}-\\u{1F3FF}]|\\u200D\\p{Extended_Pictographic}\\uFE0F?)*))', 'gu'); }
  catch (e) { try { RX = new RegExp('([\\u{1F1E6}-\\u{1F1FF}]{2}|[\\u{1F300}-\\u{1FAFF}\\u{2600}-\\u{27BF}\\u{2B00}-\\u{2BFF}](?:\\uFE0F|\\u200D[\\u{1F300}-\\u{1FAFF}\\u{2600}-\\u{27BF}]\\uFE0F?)*)', 'gu'); } catch (e2) { RX = null; } }
  const SEL = 'button,h1,h2,h3,label,.chip,.hpill,.klbl,.card>span,.trstats span,.trops span,.ilist li>b,.achg span,.rpbtn>span,.pgrid span,.facts span,.bigflag,.stamp span,.stampnew span,.trflag,.vbig,.tops button';
  const SKIP = '#ptext,#stage,.ptext,input,textarea,svg,.stk,#nowBar,.toast,script,style';
  function wrap(root) {
    try { wrap0(root); } catch (e) {}
  }
  function wrap0(root) {
    if (!RX || !root || root.nodeType !== 1 || root.closest(SKIP)) return;
    const els = root.matches(SEL) ? [root, ...root.querySelectorAll(SEL)] : root.querySelectorAll(SEL);
    els.forEach((el) => {
      if (el.closest(SKIP)) return;
      [...el.childNodes].forEach((n) => {
        if (n.nodeType !== 3 || !RX.test(n.nodeValue)) return; RX.lastIndex = 0;
        const f = document.createDocumentFragment(); let last = 0; const t = n.nodeValue;
        t.replace(RX, (m, _g, i) => { if (i > last) f.appendChild(document.createTextNode(t.slice(last, i))); const s = document.createElement('span'); s.className = 'stk'; s.textContent = m; f.appendChild(s); last = i + m.length; return m; });
        if (last < t.length) f.appendChild(document.createTextNode(t.slice(last)));
        n.replaceWith(f);
      });
    });
  }
  let busy = false;
  const mo = new MutationObserver((ms) => { if (busy) return; busy = true; try { ms.forEach((m) => m.addedNodes.forEach((n) => { if (n.nodeType === 1) wrap(n); else if (n.parentElement) wrap(n.parentElement); })); } finally { busy = false; } });
  function start() { try { document.querySelectorAll('i[data-ic]').forEach((x) => (x.innerHTML = icon(x.dataset.ic))); wrap(document.body); if (RX) mo.observe(document.body, { childList: true, subtree: true }); } catch (e) {} }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
  return { icon, moonReader, skyfx, wrap };
})();

/* سِراج | SIRAJ — تبويب الكواكب 🪐: قمر الليلة، منازل القمر، الكواكب، النجوم، واختبار الفضاء (بأسلوب يناسب الأطفال) */
const Space = (() => {
  const $ = (id) => document.getElementById(id);
  const C = () => App.ctx();
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  let sec = 'moon', Q = null;

  /* ---- حساب القمر (تقريبي ويكفي للأطفال) ---- */
  const SYN = 29.530588853;
  const jd = (d) => d.getTime() / 864e5 + 2440587.5;
  function moonAge(d = new Date()) { let a = ((jd(d) - 2451550.1) / SYN) % 1; if (a < 0) a += 1; return a * SYN; }
  function illum(age) { return Math.round((1 - Math.cos(2 * Math.PI * age / SYN)) / 2 * 100); }
  const PHASES = [
    [1.5, 'محاق', 'القمر مختفي تقريبًا، لأن وجهه المضيء يطالع الشمس مو إحنا.'],
    [6.4, 'هلال', 'خيط رفيع من النور يكبر كل ليلة، وبه نعرف بداية الشهر الهجري.'],
    [8.4, 'تربيع أول', 'نصف القمر مضيء! مرّ ربع رحلته حول الأرض.'],
    [13.8, 'أحدب متزايد', 'القمر قرب يكتمل، باقي له ليالي قليلة ويصير بدر.'],
    [15.8, 'بدر', 'القمر كامل ومضيء كله، وهذي ليالي الأيام البيض.'],
    [21.1, 'أحدب متناقص', 'بدأ النور يصغر شوي شوي بعد البدر.'],
    [23.1, 'تربيع ثانٍ', 'نصفه مضيء مرة ثانية، لكن من الجهة الثانية.'],
    [28.0, 'هلال متناقص', 'هلال صغير قبل الفجر، يودّعنا قبل شهر جديد.'],
    [99, 'محاق', 'القمر مختفي تقريبًا، وقريب يطلع هلال جديد.']
  ];
  const phaseOf = (age) => PHASES.find((p) => age < p[0]);
  function moonSVG(age, size = 140, glow = true) {
    const r = 44, p = age / SYN, k = Math.cos(2 * Math.PI * p), rx = Math.abs(k) * r, wax = p < 0.5;
    const outer = wax ? `M50 ${50 - r} A${r} ${r} 0 0 1 50 ${50 + r}` : `M50 ${50 - r} A${r} ${r} 0 0 0 50 ${50 + r}`;
    const sweep = wax ? (k > 0 ? 0 : 1) : (k > 0 ? 1 : 0);
    const lit = `${outer} A${rx.toFixed(2)} ${r} 0 0 ${sweep} 50 ${50 - r}Z`;
    const u = 'm' + Math.random().toString(36).slice(2, 7);
    const craters = [[36, 34, 7], [62, 56, 9], [44, 66, 5.5], [66, 32, 4], [28, 54, 4.5], [54, 78, 3.5], [74, 70, 3], [48, 24, 3], [24, 40, 2.5], [70, 46, 2.5], [38, 50, 2], [58, 40, 2.2], [32, 72, 2.4], [78, 56, 2]]
      .map(([x, y, cr]) => `<circle cx="${x}" cy="${y}" r="${cr}" fill="url(#${u}c)"/>`).join('');
    return `<svg viewBox="0 0 100 100" width="${size}" height="${size}" aria-hidden="true" style="overflow:visible"><defs>
      <radialGradient id="${u}l" cx=".42" cy=".38" r=".72"><stop offset="0" stop-color="#FFFBEA"/><stop offset=".6" stop-color="#F7E7B0"/><stop offset="1" stop-color="#E6CD84"/></radialGradient>
      <radialGradient id="${u}d" cx=".45" cy=".4" r=".7"><stop offset="0" stop-color="#454C72"/><stop offset="1" stop-color="#262B47"/></radialGradient>
      <radialGradient id="${u}c" cx=".4" cy=".35" r=".7"><stop offset="0" stop-color="#C9AE66" stop-opacity=".55"/><stop offset="1" stop-color="#B89A55" stop-opacity=".15"/></radialGradient>
      <radialGradient id="${u}g" cx=".5" cy=".5" r=".5"><stop offset=".6" stop-color="#FFF1B8" stop-opacity=".35"/><stop offset="1" stop-color="#FFF1B8" stop-opacity="0"/></radialGradient>
      <filter id="${u}s" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation=".7"/></filter>
      <clipPath id="${u}k"><path d="${lit}"/></clipPath></defs>
      ${glow ? `<circle cx="50" cy="50" r="${r * (1.1 + illum(age) / 160)}" fill="url(#${u}g)"/>` : ''}
      <circle cx="50" cy="50" r="${r}" fill="url(#${u}d)"/><g opacity=".22">${craters.replace(/url\(#${u}c\)/g, '#1C2038')}</g>
      <path d="${lit}" fill="url(#${u}l)" filter="url(#${u}s)"/><g clip-path="url(#${u}k)"><g fill="#D9BE78" opacity=".35"><path d="M30 30 q10 -8 20 0 q6 8 -4 14 q-12 4 -16 -6z"/><path d="M52 50 q12 -6 18 6 q2 12 -10 12 q-12 -2 -8 -18z"/><path d="M34 60 q6 -4 10 2 q0 6 -6 6 q-6 -2 -4 -8z"/></g>${craters}</g>
      <circle cx="50" cy="50" r="${r}" fill="none" stroke="#ffffff" stroke-opacity=".08"/></svg>`;
  }
  function moonLon(d = new Date()) {
    const n = jd(d) - 2451545, L = 218.316 + 13.176396 * n, M = (134.963 + 13.064993 * n) * Math.PI / 180;
    return ((L + 6.289 * Math.sin(M)) % 360 + 360) % 360;
  }

  /* ---- منازل القمر الثمانية والعشرون ---- */
  const MAN = [
    ['الشرطين', 'العلامتين', 'نجمان صغيران متجاوران، كانت العرب تعدّهما أول المنازل.'],
    ['البطين', 'البطن الصغير', 'ثلاث نجيمات خافتة، تحتاج عيون حادة عشان تشوفها!'],
    ['الثريا', 'الكثيرة', 'عنقود نجوم صغيرة متلاصقة مثل حبات اللؤلؤ، من أجمل ما في السماء.'],
    ['الدبران', 'الذي يتبع', 'نجم أحمر لامع، سمّوه الدبران لأنه يمشي «دُبُر» الثريا ويلحقها.'],
    ['الهقعة', 'الدائرة', 'ثلاث نجيمات متقاربة فوق كتف صورة الجبّار.'],
    ['الهنعة', 'الانحناء', 'نجمان في صورة التوأمين، يظهران وقت اشتداد الحر.'],
    ['الذراع', 'ذراع الأسد', 'نجمان لامعان، تخيّلتهم العرب ذراعًا ممدودة.'],
    ['النثرة', 'أنف الأسد', 'لطخة ضوء خفيفة، هي في الحقيقة عنقود نجوم بعيد.'],
    ['الطرف', 'عين الأسد', 'نجمان صغيران، كأنهما نظرة الأسد.'],
    ['الجبهة', 'جبهة الأسد', 'أربعة نجوم، ألمعها «قلب الأسد».'],
    ['الزبرة', 'كاهل الأسد', 'نجمان على ظهر الأسد مثل الشعر الكثيف.'],
    ['الصرفة', 'الانصراف', 'سمّوها الصرفة لأن الحر ينصرف ويبدأ الجو يلطف عند طلوعها.'],
    ['العوّاء', 'التي تعوي', 'خمسة نجوم على شكل حرف مائل.'],
    ['السماك', 'المرتفع', 'نجم أزرق لامع اسمه السماك الأعزل، من ألمع نجوم السماء.'],
    ['الغفر', 'الغطاء', 'ثلاث نجيمات خافتة كأنها مغطّاة.'],
    ['الزبانى', 'قرنا العقرب', 'نجمان لامعان، تخيّلتهم العرب قرون العقرب.'],
    ['الإكليل', 'التاج', 'ثلاثة نجوم على رأس العقرب مثل التاج.'],
    ['القلب', 'قلب العقرب', 'نجم أحمر عملاق اسمه قلب العقرب، أكبر من الشمس بمئات المرات!'],
    ['الشولة', 'ذيل العقرب', 'نجمان في ذيل العقرب المرفوع.'],
    ['النعائم', 'النعام', 'ثمانية نجوم، تخيّلتها العرب نعامًا ترد الماء.'],
    ['البلدة', 'الأرض الخالية', 'مكان في السماء ما فيه نجوم لامعة، مثل أرض فاضية.'],
    ['سعد الذابح', 'السعد الأول', 'نجمان متقاربان، وهو أول «السعود».'],
    ['سعد بلع', 'السعد البالع', 'نجمان، كأن أحدهما يبلع الآخر من قربه.'],
    ['سعد السعود', 'أسعد السعود', 'سمّوه كذا لأن وقته يبشّر بالخير والمطر.'],
    ['سعد الأخبية', 'سعد الخيام', 'أربعة نجوم مثل خيمة صغيرة.'],
    ['الفرغ المقدّم', 'مقدّم الدلو', 'نجمان لامعان، أول دلو الماء.'],
    ['الفرغ المؤخّر', 'مؤخّر الدلو', 'نجمان يكمّلان صورة الدلو.'],
    ['الرشاء', 'حبل الدلو', 'نجوم على شكل حبل، وتسمّى أيضًا «بطن الحوت».']
  ];
  const mansionIdx = (d) => Math.floor((((moonLon(d) - 24) % 360) + 360) % 360 / (360 / 28));

  /* ---- الكواكب ---- */
  // d: البعد عن الشمس، sz: الحجم مقارنة بالأرض، day: طول اليوم، yr: السنة بأيام الأرض، mo: الأقمار، t: الحرارة، r: نصف القطر النسبي للرسم
  const PL = [
    { n: 'عطارد', e: 'Mercury', c: ['#C9C2B8', '#8A8178'], s: 16, d: '٥٨ مليون كم', sz: 'أصغر من الأرض بحوالي ٣ مرات', day: '١٧٦ يومًا من أيامنا!', yr: 88, mo: 'ما له أقمار', t: 'من ١٨٠- إلى ٤٣٠ درجة', r: .38,
      f: ['أقرب كوكب للشمس وأصغر الكواكب.', 'ما عنده هواء يحميه، فنهاره حار جدًا وليله بارد جدًا.', 'سطحه مليان حفر مثل قمرنا.'] },
    { n: 'الزهرة', e: 'Venus', c: ['#FFE0A3', '#E3A857'], s: 24, d: '١٠٨ ملايين كم', sz: 'تقريبًا بحجم الأرض', day: 'أطول من سنتها! ٢٤٣ يومًا', yr: 225, mo: 'ما لها أقمار', t: 'حوالي ٤٦٥ درجة', r: .95,
      f: ['أسخن كوكب في المجموعة الشمسية، أسخن حتى من عطارد! لأن هواءها الكثيف يحبس الحرارة.', 'أشد الكواكب لمعانًا في سمائنا، تبان مثل نجمة قوية عند الغروب أو قبل الفجر.', 'تدور حول نفسها بالعكس، فالشمس عندها تطلع من الغرب!'] },
    { n: 'الأرض', e: 'Earth', c: ['#6CC6FF', '#2E7FD1'], s: 25, land: 1, d: '١٥٠ مليون كم', sz: 'هذا مقياسنا 😊', day: '٢٤ ساعة', yr: 365, mo: 'قمر واحد', t: 'معتدلة، تقريبًا ١٥ درجة', r: 1,
      f: ['بيتنا الجميل، والكوكب الوحيد اللي نعرف فيه حياة.', 'أغلبها ماء، لذلك تبان زرقاء من الفضاء.', 'يحيطها غلاف جوي مثل البطانية، يحمينا ويعطينا الهواء.'] },
    { n: 'المريخ', e: 'Mars', c: ['#FF9A6B', '#C4492A'], s: 19, d: '٢٢٨ مليون كم', sz: 'نصف حجم الأرض تقريبًا', day: '٢٤ ساعة و٣٧ دقيقة', yr: 687, mo: 'قمران صغيران', t: 'بارد، حوالي ٦٠- درجة', r: .53,
      f: ['الكوكب الأحمر، لونه من غبار يشبه الصدأ.', 'فيه أعلى جبل في المجموعة الشمسية، أعلى من إيفرست بحوالي ٣ مرات.', 'العلماء أرسلوا له سيارات روبوت تستكشفه.'] },
    { n: 'المشتري', e: 'Jupiter', c: ['#F3D3A8', '#C98B5A'], s: 50, bands: 1, d: '٧٧٨ مليون كم', sz: 'أعرض من الأرض ١١ مرة!', day: '١٠ ساعات بس', yr: 4333, mo: 'أكثر من ٩٠ قمرًا', t: 'بارد جدًا، حوالي ١١٠- درجة', r: 11.2,
      f: ['أكبر الكواكب، يتسع لأكثر من ألف كوكب مثل الأرض!', 'فيه «البقعة الحمراء العظيمة»، عاصفة ضخمة أكبر من الأرض.', 'كوكب غازي، يعني ما فيه أرض نمشي عليها.'] },
    { n: 'زحل', e: 'Saturn', c: ['#FBE3A6', '#D9AE5F'], s: 42, ring: 1, d: '١٫٤ مليار كم', sz: 'أعرض من الأرض ٩ مرات', day: '١٠ ساعات ونص', yr: 10759, mo: 'أكثر من ١٤٠ قمرًا', t: 'حوالي ١٤٠- درجة', r: 9.4,
      f: ['مشهور بحلقاته الجميلة، وهي من قطع ثلج وصخر.', 'خفيف جدًا مع إنه ضخم، لو فيه حوض ماء بحجمه كان يطفو!', 'من أكثر الكواكب أقمارًا.'] },
    { n: 'أورانوس', e: 'Uranus', c: ['#B9F0F2', '#5FC3CF'], s: 32, d: '٢٫٩ مليار كم', sz: 'أعرض من الأرض ٤ مرات', day: '١٧ ساعة', yr: 30687, mo: '٢٧ قمرًا أو أكثر', t: 'حوالي ١٩٥- درجة', r: 4,
      f: ['لونه أزرق مخضر جميل.', 'يدور وهو مايل على جنبه، كأنه كرة تتدحرج!', 'أول كوكب اكتشفوه بالتلسكوب.'] },
    { n: 'نبتون', e: 'Neptune', c: ['#8FB5FF', '#3554C9'], s: 31, d: '٤٫٥ مليار كم', sz: 'أعرض من الأرض ٤ مرات تقريبًا', day: '١٦ ساعة', yr: 60190, mo: 'أكثر من ١٤ قمرًا', t: 'أبرد الكواكب، حوالي ٢٠٠- درجة', r: 3.9,
      f: ['أبعد كوكب عن الشمس.', 'رياحه أسرع رياح في المجموعة الشمسية.', 'ضوء الشمس ياخذ حوالي ٤ ساعات عشان يوصله!'] }
  ];
  function planetSVG(p, size) {
    const u = 'p' + Math.random().toString(36).slice(2, 7), R = 40;
    const ring = p.ring ? `<g transform="rotate(-18 50 50)"><ellipse cx="50" cy="50" rx="${R * 1.55}" ry="${R * .38}" fill="none" stroke="#C9A35E" stroke-width="7"/></g>` : '';
    const ringFront = p.ring ? `<g transform="rotate(-18 50 50)" clip-path="url(#${u}f)"><ellipse cx="50" cy="50" rx="${R * 1.55}" ry="${R * .38}" fill="none" stroke="#F4DB9F" stroke-width="7"/></g>` : '';
    const bands = p.bands ? `<g opacity=".55"><rect x="10" y="34" width="80" height="6" fill="#B5764A"/><rect x="10" y="52" width="80" height="8" fill="#D9A273"/><rect x="10" y="66" width="80" height="5" fill="#B5764A"/></g><ellipse cx="62" cy="62" rx="8" ry="5" fill="#C8553A"/>` : '';
    const land = p.land ? `<g fill="#4FBF6A"><path d="M30 34 q10 -8 18 2 q4 10 -6 14 q-10 2 -12 -6z"/><path d="M58 56 q12 -4 16 8 q-2 12 -14 10 q-8 -6 -2 -18z"/><path d="M40 70 q6 -2 8 4 q-4 6 -8 -4z"/></g><g fill="#fff" opacity=".7"><ellipse cx="62" cy="30" rx="12" ry="3"/><ellipse cx="34" cy="60" rx="10" ry="2.5"/></g>` : '';
    return `<svg viewBox="-20 -10 140 120" width="${size}" height="${Math.round(size * 120 / 140)}" aria-hidden="true"><defs><radialGradient id="${u}" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="${p.c[0]}"/><stop offset="1" stop-color="${p.c[1]}"/></radialGradient><clipPath id="${u}c"><circle cx="50" cy="50" r="${R}"/></clipPath><clipPath id="${u}f"><rect x="-40" y="50" width="180" height="60"/></clipPath></defs>
      ${ring}<circle cx="50" cy="50" r="${R}" fill="url(#${u})"/><g clip-path="url(#${u}c)">${bands}${land}<circle cx="72" cy="66" r="${R}" fill="#000" opacity=".14"/></g>${ringFront}</svg>`;
  }

  /* ---- النجوم ---- */
  const STARS = [
    ['☀️', 'الشمس', 'هي نجم! أقرب نجم لنا، ونورها يوصل الأرض في حوالي ٨ دقائق.'],
    ['✨', 'الشِّعرى اليمانية', 'ألمع نجم في سماء الليل، وجاء ذكرها في القرآن: ﴿وأنه هو ربّ الشّعرى﴾.'],
    ['🌟', 'سهيل', 'ثاني ألمع نجم. لما يطلع في آخر الصيف يقول الناس: «إذا طلع سهيل، برد الليل».'],
    ['🧭', 'الجدي (النجم القطبي)', 'نجم ثابت تقريبًا في جهة الشمال، كان المسافرون يهتدون به في الليل.'],
    ['🐻', 'بنات نعش', 'سبعة نجوم لامعة على شكل مغرفة، وتدور حول الجدي طول الليل.'],
    ['💎', 'الثريا', 'عنقود من نجوم صغيرة متلاصقة، تقدر تعدّ منها ٦ أو ٧ بعينك.'],
    ['🌌', 'درب التبّانة', 'مجرّتنا! فيها مليارات النجوم، والشمس وحدة منها.'],
    ['☄️', 'الشهب', 'حبات غبار صغيرة تحترق في الهواء فوقنا، فنشوفها خطوط نور سريعة.']
  ];
  const QUIZ = [
    ['وش أكبر كوكب في المجموعة الشمسية؟', 'المشتري', 'الأرض', 'المريخ'],
    ['أي كوكب مشهور بحلقاته؟', 'زحل', 'الزهرة', 'عطارد'],
    ['وش اسم القمر لما يكون كامل ومضيء كله؟', 'البدر', 'الهلال', 'المحاق'],
    ['الشمس هي…', 'نجم', 'كوكب', 'قمر'],
    ['وش لون كوكب المريخ؟', 'أحمر', 'أزرق', 'أخضر'],
    ['كم عدد منازل القمر؟', '٢٨', '١٢', '٧'],
    ['أي نجم يدل على جهة الشمال؟', 'الجدي', 'سهيل', 'الشعرى'],
    ['أي كوكب هو بيتنا؟', 'الأرض', 'نبتون', 'زحل'],
    ['أسخن كوكب في المجموعة الشمسية هو…', 'الزهرة', 'عطارد', 'المشتري'],
    ['وش يصير للحر لما تطلع منزلة «الصرفة»؟', 'ينصرف ويلطف الجو', 'يزيد', 'ما يتغير']
  ];

  function say(t) { const c = C(); if (c.speak) c.speak(t, true); }
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const qs = (t) => t.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '&quot;');

  function render() {
    const c = C(), esc = c.esc, now = new Date(), age = moonAge(now), ph = phaseOf(age), mi = mansionIdx(now), m = MAN[mi];
    const SECS = [['moon', '🌙 منازل القمر'], ['planets', '🪐 الكواكب'], ['stars', '⭐ النجوم'], ['quiz', '🧠 اختبار']];
    let body = '';
    if (sec === 'moon') {
      const steps = [0, 3.7, 7.4, 11.1, 14.8, 18.5, 22.1, 25.8];
      body = `<p class="muted">القمر يمرّ كل شهر على ٢٨ منزلة في السماء، وينزل كل ليلة في منزلة. اضغط أي منزلة 👇</p>
        <div class="phstrip">${steps.map((a) => `<div class="${Math.abs(a - age) < 1.9 || (a === 0 && age > 27.6) ? 'on' : ''}">${moonSVG(a, 34, false)}<small>${phaseOf(a)[1]}</small></div>`).join('')}</div>
        <div class="mgrid">${MAN.map((x, i) => `<button class="mz ${i === mi ? 'on' : ''}" onclick="Space.mansion(${i})"><i>${AR(i + 1)}</i><b>${x[0]}</b>${i === mi ? '<em>🌙 الليلة</em>' : ''}</button>`).join('')}</div>
        <p class="ayah">﴿وَالْقَمَرَ قَدَّرْنَاهُ مَنَازِلَ حَتَّىٰ عَادَ كَالْعُرْجُونِ الْقَدِيمِ﴾<small>سورة يس ٣٩</small></p>`;
    }
    if (sec === 'planets') body = `<p class="muted">٨ كواكب تدور حول الشمس. اضغط أي كوكب وتعرّف عليه 👇</p>
      <div class="solar"><div class="sun"></div>${PL.map((p, i) => `<button onclick="Space.planet(${i})" title="${p.n}">${planetSVG(p, Math.round(p.s * 1.25))}</button>`).join('')}</div>
      <div class="plist">${PL.map((p, i) => `<button class="pcard" onclick="Space.planet(${i})">${planetSVG(p, 64)}<div><b>${p.n}</b><small dir="ltr">${p.e}</small><span>${esc(p.f[0])}</span></div></button>`).join('')}</div>`;
    if (sec === 'stars') body = `<p class="muted">نجوم وأشياء جميلة تقدر تدوّر عليها في السماء مع أهلك ✨</p>
      <div class="slist">${STARS.map((s, i) => `<button class="scard" onclick="Space.star(${i})"><span>${s[0]}</span><div><b>${s[1]}</b><small>${esc(s[2])}</small></div></button>`).join('')}</div>`;
    if (sec === 'quiz') body = `<div style="text-align:center;padding:8px 0"><div style="font-size:64px">🚀</div><h2>اختبار رواد الفضاء</h2><p class="muted">٥ أسئلة عن القمر والكواكب والنجوم</p><button class="btn" onclick="Space.quiz()">ابدأ الاختبار 🧠</button></div>`;
    $('space').innerHTML = `<div class="card mooncard"><div class="mc-art">${moonSVG(age, 170)}</div>
        <div class="mc-in"><small>قمر الليلة</small><h2>${ph[1]}</h2><p>${esc(ph[2])}</p>
        <div class="mc-stats"><div><b>${AR(Math.max(1, Math.round(age)))}</b><span>عمره بالأيام</span></div><div><b>${AR(illum(age))}٪</b><span>مضيء</span></div><div><b>${m[0]}</b><span>منزلته الليلة</span></div></div>
        <button class="btn alt" onclick="Space.sayMoon()">🔊 احكِ لي عن قمر الليلة</button></div></div>
      <div class="ensub spsub">${SECS.map(([v, t]) => `<button class="chip ${v === sec ? 'on' : ''}" onclick="Space.setSec('${v}')">${t}</button>`).join('')}</div>
      <div class="card">${body}</div>`;
  }
  function setSec(v) { sec = v; render(); }
  function sayMoon() {
    const age = moonAge(), ph = phaseOf(age), m = MAN[mansionIdx(new Date())];
    say(`قمر الليلة ${ph[1]}. ${ph[2]} وهو الليلة في منزلة ${m[0]}.`);
  }
  function modal(html) { $('gameBody').innerHTML = `<div class="encard">${html}</div>`; $('gameModal').classList.add('on'); }
  function mansion(i) {
    const m = MAN[i], c = C();
    modal(`<div class="bige" style="font-size:60px">${i === mansionIdx(new Date()) ? '🌙' : '✨'}</div><p class="ent" style="font-family:inherit">${m[0]}</p><p class="muted">المنزلة رقم ${AR(i + 1)} · معنى اسمها: ${c.esc(m[1])}</p>
      <p class="gq" style="direction:rtl;text-align:right;font-family:inherit">${c.esc(m[2])}</p>
      <div class="row"><button class="btn alt" onclick="Space.mansion(${(i + 27) % 28})">→ السابقة</button><button class="btn alt" onclick="Space.mansion(${(i + 1) % 28})">التالية ←</button></div>`);
    say(`${m[0]}. معنى اسمها ${m[1]}. ${m[2]}`);
  }
  function planet(i) {
    const p = PL[i], c = C(), e = PL[2];
    const k = (c.heroes()[0] || c.myKids()[0]), yrs = k && k.age ? [4, 7, 10][k.age - 1] || 10 : 10;
    const there = p.yr === 365 ? '' : (() => { const v = yrs * 365 / p.yr; return v >= 1 ? 'عمرك هناك تقريبًا ' + AR(Math.round(v * 10) / 10) + ' سنة' : 'ما كمّلت سنة وحدة هناك! 😄 (' + AR(Math.round(v * 100)) + '٪ من سنة)'; })();
    const pw = p.r > 1 ? 110 : Math.round(80 * p.r), ew = p.r > 1 ? Math.max(8, Math.round(110 / p.r)) : 80;
    const ball = (w, q) => `<i style="width:${w}px;height:${w}px;background:radial-gradient(circle at 35% 30%,${q.c[0]},${q.c[1]})"></i>`;
    const cmp = p.r === 1 ? '' : `<div class="cmp"><div>${ball(pw, p)}${p.n}</div><div>${ball(ew, e)}الأرض</div></div><p class="muted" style="font-size:12px;margin-top:-4px">الحجم الحقيقي بالمقارنة 👆</p>`;
    modal(`<div class="spin">${planetSVG(p, 160)}</div><p class="ent" style="font-family:inherit">${p.n} <small class="muted" dir="ltr">${p.e}</small></p>
      <p class="muted">الكوكب رقم ${AR(i + 1)} من الشمس</p>${cmp}
      <div class="pstats"><div>📏 الحجم<b>${p.sz}</b></div><div>☀️ البعد عن الشمس<b>${p.d}</b></div><div>🌗 طول اليوم<b>${p.day}</b></div>
        <div>🗓️ طول السنة<b>${p.yr === 365 ? '٣٦٥ يومًا' : p.yr < 1000 ? AR(p.yr) + ' يومًا' : 'حوالي ' + AR(Math.round(p.yr / 365)) + ' سنة من سنواتنا'}</b></div><div>🌙 الأقمار<b>${p.mo}</b></div><div>🌡️ الحرارة<b>${p.t}</b></div></div>
      ${there ? `<p class="myage">🎂 لو عمرك ${AR(yrs)} سنين على الأرض، ${there}</p>` : ''}
      <div class="facts">${p.f.map((x) => `<p>💡 ${c.esc(x)}</p>`).join('')}</div>
      <div class="row"><button class="btn alt" onclick="Space.planet(${(i + 7) % 8})">→ السابق</button><button class="btn alt" onclick="Space.planet(${(i + 1) % 8})">التالي ←</button></div>`);
    say(p.n + '. ' + p.f.join(' '));
  }
  function star(i) { const s = STARS[i]; modal(`<div class="bige">${s[0]}</div><p class="ent" style="font-family:inherit">${s[1]}</p><p class="gq" style="direction:rtl;text-align:right;font-family:inherit">${C().esc(s[2])}</p>`); say(s[1] + '. ' + s[2]); }

  function quiz() { Q = { qs: shuffle(QUIZ).slice(0, 5).map((x) => ({ q: x[0], a: x[1], o: shuffle(x.slice(1)) })), i: 0, sc: 0, pk: null }; drawQ(); $('gameModal').classList.add('on'); }
  function drawQ() {
    const c = C(), it = Q.qs[Q.i];
    if (!it) {
      $('gameBody').innerHTML = `<h2>🚀 أحسنت يا رائد الفضاء!</h2><div class="celebrate" style="font-size:28px">${'⭐'.repeat(Q.sc)}${'☆'.repeat(5 - Q.sc)}</div>
        <div class="row"><button class="btn" onclick="Space.quiz()">مرة ثانية 🔁</button><button class="btn alt" onclick="Play.closeGame()">إغلاق</button></div>`;
      Play.logAct('space', { id: 'space-quiz' }, Q.sc); return;
    }
    const ans = Q.pk != null;
    $('gameBody').innerHTML = `<h2>🧠 اختبار الفضاء <small class="muted">${AR(Q.i + 1)}/${AR(5)}</small></h2><p class="ptext" style="color:var(--ink)">${c.esc(it.q)}</p>
      <div class="opts">${it.o.map((o, k) => `<button class="opt ${ans ? (o === it.a ? 'ok' : k === Q.pk ? 'no' : '') : ''}" ${ans ? 'disabled' : `onclick="Space.ans(${k})"`}>${c.esc(o)}</button>`).join('')}</div>
      ${ans ? `<p class="fb">${it.o[Q.pk] === it.a ? '✅ صح!' : '💡 الجواب: ' + c.esc(it.a)}</p><button class="btn" onclick="Space.nextQ()">التالي ←</button>` : ''}`;
  }
  function ans(k) { const it = Q.qs[Q.i]; Q.pk = k; if (it.o[k] === it.a) Q.sc++; drawQ(); }
  function nextQ() { Q.i++; Q.pk = null; drawQ(); }

  function phaseName() { return phaseOf(moonAge())[1]; }
  return { planetSVG: (i, s) => planetSVG(PL[i], s), phaseName, render, setSec, sayMoon, mansion, planet, star, quiz, ans, nextQ, moonSVG, moonAge };
})();

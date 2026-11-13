/* سِراج | SIRAJ — حول التطبيق، الخصوصية، التواصل، الإضافة للشاشة الرئيسية (عند وليّ الأمر فقط)
   وتذييل صغير للعيال في «أنا» (الإصدار والشعار، بدون روابط) */
const Info = (() => {
  const $ = (id) => document.getElementById(id);
  const MAIL = 'siraj@wamdarc.com';
  const AR = (n) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  let installEvt = null;
  window.addEventListener('beforeinstallprompt', (e) => { installEvt = e; });

  const logo = (link) => `${link ? '<a class="wamdf" href="https://wamdarc.com" target="_blank" rel="noopener" aria-label="WAMD ARC">' : '<div class="wamdf">'}<img class="wl" src="wamdarc-light.png" alt="WAMD ARC" width="132" height="21"><img class="wd" src="wamdarc-dark.png" alt="WAMD ARC" width="132" height="21"><span dir="ltr">WAMDARC.COM</span>${link ? '</a>' : '</div>'}`;
  const sheet = (html) => { $('gameBody').innerHTML = `<div class="infos">${html}</div>`; $('gameModal').classList.add('on'); $('gameBody').parentElement.scrollTop = 0; };
  const hero = (title, sub) => `<div class="ihero"><img src="icons/icon-192.png" alt=""><h2>${title}</h2><div class="v">${sub}</div></div>`;

  function about() {
    const n = typeof STORIES !== 'undefined' ? STORIES.length : 0;
    const F = [
      ['📖', 'قصص بأسماء أطفالك', `أكثر من ${AR(Math.floor(n / 10) * 10)} قصة أصلية: قيم، وقصص أنبياء وصحابة، وعلوم، وقصص «اختر طريقك».`],
      ['🎨', 'شخصيات يصممها الطفل', 'الشكل واللبس والأحذية وقمصان الأندية، وتظهر في رسومات القصص.'],
      ['🔤', 'إنجليزي وألعاب', 'حروف وكلمات ونطق وتلوين وألغاز، حسب عمر كل طفل.'],
      ['🪐', 'الكواكب والقمر', 'منازل القمر والكواكب والنجوم بأسلوب يناسب الصغار.'],
      ['✈️', 'رحلات حول العالم', 'يسافر مع العائلة من مطار الرياض، ويتعلم الأعلام والعواصم.'],
      ['🤲', 'أذكار وأصوات النوم', 'أذكار النوم بمصادرها، وأصوات هادئة بمؤقت.'],
      ['👨‍👩‍👧', 'متابعة الوالدين', 'لوحة شرف، ورسائل للعيال، ومكافأة الأسبوع، وتقرير كل جمعة.'],
      ['🔒', 'خصوصية العائلة', 'أسماء الأطفال وكل بياناتهم تنشفّر على جهازك قبل أي مزامنة.']
    ];
    sheet(hero('سِراج | SIRAJ', 'v' + CONFIG.VERSION) + `<p class="itag">قصص قبل النوم بأسماء أطفالك 🌙</p>
      <p class="itext">سِراج يحوّل وقت النوم لحكاية يكون أطفالك أبطالها: قصة كل ليلة بأسمائهم، ورسومات فيها شخصياتهم، وأنشطة خفيفة تعلّمهم وتسعدهم. بدون إعلانات، وبدون مشتريات داخل التطبيق.</p>
      <ul class="ilist">${F.map(([e, t, d]) => `<li><b>${e}</b><span><b>${t}</b><i>${d}</i></span></li>`).join('')}</ul>
      <p class="iby">من تطوير</p>${logo(true)}
      <button class="btn" onclick="App.shareApp()">مشاركة التطبيق 📤</button><button class="btn alt" style="margin-top:8px" onclick="Play.closeGame()">إغلاق</button>`);
  }
  function contact() { location.href = 'mailto:' + MAIL + '?subject=' + encodeURIComponent('سِراج — ملاحظة v' + CONFIG.VERSION); }
  async function privacy() {
    let body = '';
    try {
      const d = new DOMParser().parseFromString(await (await fetch('privacy.html')).text(), 'text/html'), m = d.getElementById('ar');
      if (m) { m.querySelectorAll('script,style').forEach((x) => x.remove()); body = m.innerHTML; }
    } catch (e) {}
    if (!body) return App.ctx().toast('تعذّر فتح السياسة، تأكد من الإنترنت');
    sheet(hero('سياسة الخصوصية', 'سِراج | SIRAJ') + `<div class="pv">${body}</div><button class="btn" onclick="Play.closeGame()">تم</button>`);
    document.querySelectorAll('.pv a[href^="http"]').forEach((x) => { x.target = '_blank'; x.rel = 'noopener'; });
  }
  const standalone = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone;
  const isIOS = () => /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  async function addHome() {
    if (standalone()) return App.ctx().toast('سِراج مضاف للشاشة الرئيسية ✓');
    if (installEvt) { installEvt.prompt(); try { await installEvt.userChoice; } catch (e) {} installEvt = null; return; }
    const ios = isIOS();
    sheet(hero('إضافة إلى الشاشة الرئيسية', 'يفتح مثل التطبيق، بملء الشاشة') + `<ol class="isteps">${ios
      ? '<li>افتح سِراج من متصفح <b>Safari</b></li><li>اضغط زر المشاركة <b>⬆️</b> تحت (أو فوق في الآيباد)</li><li>اختر <b>«إضافة إلى الشاشة الرئيسية»</b></li><li>اضغط <b>«إضافة»</b> ✓</li>'
      : '<li>افتح سِراج من متصفح <b>Chrome</b></li><li>اضغط القائمة <b>⋮</b> فوق</li><li>اختر <b>«إضافة إلى الشاشة الرئيسية»</b> أو <b>«تثبيت التطبيق»</b></li><li>اضغط <b>«تثبيت»</b> ✓</li>'}</ol>
      <p class="muted">سوّها على كل جهاز في البيت، وتطلع أيقونة سِراج مع باقي التطبيقات.</p><button class="btn" onclick="Play.closeGame()">تمام</button>`);
  }
  function fill() {
    document.querySelectorAll('.verV').forEach((x) => (x.textContent = CONFIG.VERSION));
    const k = $('kidFoot');
    if (k) k.innerHTML = `<b>سِراج — الإصدار ${CONFIG.VERSION}</b>${logo(false)}`;
  }
  document.addEventListener('DOMContentLoaded', fill); if (document.readyState !== 'loading') setTimeout(fill);
  return { about, contact, privacy, addHome, fill };
})();

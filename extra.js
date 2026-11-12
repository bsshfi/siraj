/* سِراج | SIRAJ — قصص مضافة من لوحة الإدارة (admin.wamdarc.com)
   - تنحفظ في الجهاز وتشتغل بدون إنترنت، وتتحدث بالخلفية كل ما فتح التطبيق.
   - القصة اللي تنحذف من اللوحة تبقى مخفية (عشان سجل القراءة ما يخرب) وما تطلع في الدور ولا المكتبة.
   - «تاريخ العرض» (شهر-يوم) يخلّي القصة قصة ذاك اليوم لكل العائلات. */
(function () {
  var KEY = 'siraj-extra', API = 'https://push-wamdarc.bsshfi.workers.dev/stories?app=siraj';
  if (typeof STORIES === 'undefined') return;
  function load() { try { return JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { return {}; } }
  function apply(map) {
    Object.keys(map).forEach(function (id) {
      var s = map[id]; if (!s || !s.pages || !s.pages.length) return;
      var o = { id: id, title: s.title, value: s.value || '', scene: s.scene || 'home', pages: s.pages, extra: 1 };
      if (s.off) { o.hidden = 1; o.occ = { cal: 'x', m: 0, d: [] }; }
      else if (s.date) { var p = String(s.date).split('-'); o.occ = { cal: 'g', m: +p[0], d: [+p[1]] }; }
      var i = -1; for (var k = 0; k < STORIES.length; k++) if (STORIES[k].id === id) { i = k; break; }
      if (i >= 0) { if (STORIES[i].extra) STORIES[i] = o; } else STORIES.push(o);
    });
  }
  var map = load(); apply(map);
  try {
    fetch(API, { cache: 'no-store' }).then(function (r) { return r.ok ? r.json() : null; }).then(function (j) {
      if (!j || !Array.isArray(j.stories)) return;
      var seen = {};
      j.stories.forEach(function (s) { if (s && s.id) { seen[s.id] = 1; s.off = 0; map[s.id] = s; } });
      Object.keys(map).forEach(function (id) { if (!seen[id]) map[id].off = 1; });
      try { localStorage.setItem(KEY, JSON.stringify(map)); } catch (e) {}
    }).catch(function () {});
  } catch (e) {}
})();

/* سِراج | SIRAJ — طبقة توافق لنسخة الأندرويد فقط (ما تنحمّل في نسخة الويب أبدًا)
   تنحمّل قبل باقي السكربتات، وتسد الفروقات بين المتصفح وتطبيق الأندرويد:
   ١) يتصرّف كأنه "مثبّت على الشاشة الرئيسية" فما تطلع شاشة التثبيت
   ٢) يوقف Service Worker (الملفات أصلًا داخل التطبيق)
   ٣) القراءة بالصوت عبر محرك الكلام في الجهاز (المتصفح الداخلي ما يدعم speechSynthesis)
   ٤) المشاركة عبر قائمة المشاركة في الأندرويد
   ٥) تذكير وقت القصة كإشعار محلي من الجهاز نفسه (بدل إشعارات السيرفر) */
(function () {
  'use strict';
  var C = window.Capacitor;
  if (!C || !C.isNativePlatform || !C.isNativePlatform()) return;
  var P = C.Plugins || {};

  /* ١) وضع التطبيق المثبّت */
  try { Object.defineProperty(navigator, 'standalone', { value: true, configurable: true }); } catch (e) {}

  /* ٢) بدون Service Worker */
  try { delete Navigator.prototype.serviceWorker; } catch (e) {}

  /* ٣) القراءة بالصوت */
  var TTS = P.TextToSpeech;
  if (TTS) {
    var voices = [], current = null;
    var fire = function (u, name, ev) { try { if (u && typeof u[name] === 'function') u[name](ev || {}); } catch (e) {} };
    var Utter = function (text) {
      this.text = String(text || ''); this.lang = ''; this.rate = 1; this.pitch = 1; this.volume = 1; this.voice = null;
      this.onstart = this.onend = this.onerror = this.onboundary = null;
    };
    var synth = {
      speaking: false, pending: false, paused: false, onvoiceschanged: null,
      getVoices: function () { return voices.slice(); },
      speak: function (u) {
        current = u; synth.speaking = true;
        var opts = { text: u.text, lang: u.lang || 'ar-SA', rate: u.rate || 1, pitch: u.pitch || 1, volume: u.volume == null ? 1 : u.volume, queueStrategy: 0 };
        if (u.voice && typeof u.voice._i === 'number') opts.voice = u.voice._i;
        setTimeout(function () { if (current === u) fire(u, 'onstart'); }, 0);
        TTS.speak(opts).then(function () {
          if (current === u) { current = null; synth.speaking = false; fire(u, 'onend'); }
        }).catch(function (e) {
          if (current === u) { current = null; synth.speaking = false; fire(u, 'onerror', { error: String(e) }); fire(u, 'onend'); }
        });
      },
      cancel: function () { current = null; synth.speaking = false; TTS.stop().catch(function () {}); },
      pause: function () {}, resume: function () {}
    };
    try {
      TTS.addListener('onRangeStart', function (info) {
        if (current) fire(current, 'onboundary', { name: 'word', charIndex: info.start, charLength: info.end - info.start });
      });
    } catch (e) {}
    TTS.getSupportedVoices().then(function (r) {
      voices = ((r && r.voices) || []).map(function (v, i) {
        return { name: v.name, lang: String(v.lang || '').replace('_', '-'), voiceURI: v.voiceURI, localService: v.localService !== false, default: !!v.default, _i: i };
      });
      fire(synth, 'onvoiceschanged');
    }).catch(function () {});
    try { Object.defineProperty(window, 'speechSynthesis', { value: synth, configurable: true, writable: true }); } catch (e) { window.speechSynthesis = synth; }
    window.SpeechSynthesisUtterance = Utter;
  }

  /* ٤) المشاركة */
  if (P.Share) {
    navigator.share = function (d) {
      d = d || {};
      return P.Share.share({ title: d.title, text: d.text, url: d.url, dialogTitle: d.title });
    };
  }

  /* ٥) تذكير وقت القصة (لأجهزة الأطفال، مثل نسخة الويب) */
  var LN = P.LocalNotifications;
  if (LN) {
    var REMIND_ID = 1, lastKey = null, busy = false;
    var state = function () { try { return JSON.parse(localStorage.getItem('siraj')) || {}; } catch (e) { return {}; } };
    var bodyFor = function (S) {
      var kids = (S.fam && S.fam.kids) || [], sel = S.sel || [];
      var list = kids.filter(function (k) { return sel.indexOf(k.id) >= 0; });
      if (!list.length) list = kids;
      var names = list.map(function (k) { return k.n; }).filter(Boolean).join(' و');
      return names ? 'يا ' + names + '، سِراج ينتظركم بقصة جديدة ✨' : 'سِراج ينتظركم بقصة جديدة ✨';
    };
    var syncReminder = function () {
      if (busy) return;
      var S = state(), f = S.fam || {};
      var on = S.role === 'child' && !!f.remind && /^\d{1,2}:\d{2}$/.test(f.bedtime || '');
      var body = on ? bodyFor(S) : '';
      var key = on ? f.bedtime + '|' + body : 'off';
      if (key === lastKey) return;
      busy = true;
      var done = function () { busy = false; };
      LN.cancel({ notifications: [{ id: REMIND_ID }] }).catch(function () {}).then(function () {
        if (!on) { lastKey = key; return; }
        return LN.checkPermissions().then(function (p) {
          if (p.display === 'granted') return p;
          var asked = false; try { asked = localStorage.getItem('siraj-native-notif-asked') === '1'; } catch (e) {}
          if (asked) return p;
          try { localStorage.setItem('siraj-native-notif-asked', '1'); } catch (e) {}
          return LN.requestPermissions();
        }).then(function (p) {
          if (!p || p.display !== 'granted') return;
          var hm = f.bedtime.split(':').map(Number);
          return LN.schedule({ notifications: [{
            id: REMIND_ID, title: '🌙 حان وقت حكاية الليلة', body: body,
            schedule: { on: { hour: hm[0], minute: hm[1] }, allowWhileIdle: true }
          }] }).then(function () { lastKey = key; });
        });
      }).then(done, done);
    };
    setTimeout(syncReminder, 2500);
    setInterval(syncReminder, 20000);
    document.addEventListener('visibilitychange', function () { if (!document.hidden) syncReminder(); });
    /* الضغط على الإشعار يفتح التطبيق، وهذا يكفي */
  }

  /* ٦) التحكم عن بُعد + إجبار التحديث
     يقرأ ملف إعدادات صغير من الموقع. ما يرسل أي معرّف للجهاز (مناسب لسياسة تطبيقات الأطفال).
     لو الملف مو موجود أو ما فيه نت: يستخدم آخر نسخة محفوظة، وإلا الإعدادات الافتراضية. */
  var CONFIG_URL = 'https://siraj.wamdarc.com/app-config.json';
  var STORE_URL = 'https://play.google.com/store/apps/details?id=com.wamdarc.siraj';
  var CFG_KEY = 'siraj-remote-config';
  var DEFAULT_FLAGS = { ads: false, accounts: false, analytics: false };

  var cached = null;
  try { cached = JSON.parse(localStorage.getItem(CFG_KEY)); } catch (e) {}
  window.SIRAJ_FLAGS = Object.assign({}, DEFAULT_FLAGS, (cached && cached.flags) || {});

  var el = function (tag, css, text) { var n = document.createElement(tag); n.style.cssText = css; if (text) n.textContent = text; return n; };
  var FONT = "font-family:'Baloo Bhaijaan 2',system-ui,sans-serif;";

  var showUpdateScreen = function (cfg, force) {
    if (document.getElementById('siraj-update')) return;
    var a = cfg.android || {};
    var wrap = el('div', 'position:fixed;inset:0;z-index:2147483647;display:flex;align-items:' + (force ? 'center' : 'flex-end') +
      ';justify-content:center;background:' + (force ? 'linear-gradient(160deg,#5B4BDB,#120F33)' : 'rgba(18,15,51,.55)') +
      ';padding:24px;padding-bottom:max(24px,env(safe-area-inset-bottom));direction:rtl;' + FONT);
    wrap.id = 'siraj-update';
    var card = el('div', 'background:#fff;color:#1d1a3a;border-radius:24px;padding:28px 22px;max-width:380px;width:100%;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.35)');
    card.appendChild(el('div', 'font-size:44px;line-height:1;margin-bottom:10px', '🌙'));
    card.appendChild(el('div', 'font-size:22px;font-weight:800;margin-bottom:8px', a.title || (force ? 'تحديث مطلوب' : 'تحديث جديد متوفر')));
    card.appendChild(el('div', 'font-size:16px;line-height:1.7;color:#55507a;margin-bottom:20px',
      a.message || (force ? 'نزّلنا نسخة جديدة من سِراج. حدّث التطبيق عشان تكمل الحكايات ✨' : 'فيه نسخة أحدث من سِراج بميزات جديدة.')));
    var btn = el('button', 'width:100%;border:0;border-radius:16px;padding:14px;font-size:18px;font-weight:700;color:#fff;background:#5B4BDB;' + FONT, 'حدّث الآن');
    btn.onclick = function () { window.location.href = a.storeUrl || STORE_URL; };
    card.appendChild(btn);
    if (!force) {
      var later = el('button', 'width:100%;border:0;background:none;margin-top:10px;padding:10px;font-size:16px;color:#7a75a0;' + FONT, 'لاحقًا');
      later.onclick = function () {
        wrap.remove();
        try { localStorage.setItem('siraj-update-snooze', String(Date.now())); } catch (e) {}
      };
      card.appendChild(later);
    }
    wrap.appendChild(card);
    (document.body || document.documentElement).appendChild(wrap);
  };

  var applyConfig = function (cfg, build) {
    if (!cfg) return;
    window.SIRAJ_FLAGS = Object.assign({}, DEFAULT_FLAGS, cfg.flags || {});
    try { window.dispatchEvent(new CustomEvent('siraj:flags', { detail: window.SIRAJ_FLAGS })); } catch (e) {}
    var a = cfg.android || {};
    if (!build) return;
    if (a.minBuild && build < a.minBuild) return showUpdateScreen(cfg, true);
    if (a.latestBuild && build < a.latestBuild) {
      var snoozed = 0; try { snoozed = Number(localStorage.getItem('siraj-update-snooze')) || 0; } catch (e) {}
      if (Date.now() - snoozed > 3 * 24 * 3600 * 1000) showUpdateScreen(cfg, false);
    }
  };

  var getBuild = function () {
    return P.App ? P.App.getInfo().then(function (i) { return Number(i.build) || 0; }).catch(function () { return 0; }) : Promise.resolve(0);
  };

  var refreshConfig = function () {
    var ctrl = window.AbortController ? new AbortController() : null;
    var t = ctrl ? setTimeout(function () { ctrl.abort(); }, 6000) : null;
    return fetch(CONFIG_URL + '?t=' + Date.now(), { cache: 'no-store', signal: ctrl && ctrl.signal })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (cfg) {
        if (cfg && typeof cfg === 'object') { try { localStorage.setItem(CFG_KEY, JSON.stringify(cfg)); } catch (e) {} return cfg; }
        return cached;
      })
      .catch(function () { return cached; })
      .then(function (cfg) { if (t) clearTimeout(t); return cfg; });
  };

  /* ٧) التحديثات الفورية (Live updates)
     تبدّل ملفات الواجهة فقط، والهيكل الأصلي (الإشعارات، الصوت…) يبقى كما هو.
     التحديث ينزل بالخلفية ويتطبّق في الفتحة الجاية. لو فشلت النسخة الجديدة بالتشغيل،
     يرجع التطبيق تلقائيًا للنسخة اللي قبلها (notifyAppReady). ما يرسل أي بيانات لأي جهة. */
  var UP = P.CapacitorUpdater;
  if (UP) { try { UP.notifyAppReady(); } catch (e) {} }
  var liveBusy = false;
  var checkLive = function (cfg, build) {
    var live = cfg && cfg.android && cfg.android.live;
    if (!UP || liveBusy || !live || !live.version || !live.url) return;
    if (live.minBuild && build < live.minBuild) return;           /* نسخة الواجهة تحتاج هيكل أحدث */
    var fail = {}; try { fail = JSON.parse(localStorage.getItem('siraj-live-fail')) || {}; } catch (e) {}
    if (fail.v === live.version && Date.now() - fail.t < 6 * 3600 * 1000) return;   /* فشل قريب: جرّب بعد 6 ساعات */
    liveBusy = true;
    UP.current().then(function (cur) {
      var now = cur && cur.bundle && cur.bundle.version;
      var pending = null; try { pending = localStorage.getItem('siraj-live-pending'); } catch (e) {}
      if (now === live.version || pending === live.version) return;
      return UP.download({ url: live.url, version: live.version, checksum: live.checksum || undefined })
        .then(function (b) { return UP.next({ id: b.id }); })
        .then(function () { try { localStorage.setItem('siraj-live-pending', live.version); } catch (e) {} });
    }).catch(function () {
      try { localStorage.setItem('siraj-live-fail', JSON.stringify({ v: live.version, t: Date.now() })); } catch (e) {}
    }).then(function () { liveBusy = false; });
  };

  var runConfig = function () {
    Promise.all([refreshConfig(), getBuild()]).then(function (r) {
      cached = r[0] || cached; applyConfig(cached, r[1]); checkLive(cached, r[1]);
    });
  };
  /* أول تشغيل: طبّق المحفوظ فورًا (يشتغل بدون نت)، ثم حدّث من السيرفر */
  getBuild().then(function (b) { if (cached) applyConfig(cached, b); });
  setTimeout(runConfig, 1500);
  document.addEventListener('visibilitychange', function () { if (!document.hidden) runConfig(); });
})();

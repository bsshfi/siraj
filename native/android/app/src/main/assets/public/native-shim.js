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
})();

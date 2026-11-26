import 'package:hijri/hijri_calendar.dart';

import 'data.dart';
import 'family.dart';

/// منطق "قصص الليلة" — منقول حرفيًا من app.js عشان التطبيق والموقع يعرضون نفس القصة لنفس العائلة
class Tonight {
  /* ---- نفس hash و rng (mulberry32) في الويب، بحساب ٣٢ بت ---- */
  static int _i32(int x) => x.toSigned(32);
  static int _u32(int x) => x & 0xFFFFFFFF;
  static int _imul(int a, int b) => _i32(_i32(a) * _i32(b));

  static int hash(String s) {
    var h = 2166136261;
    for (final c in s.runes) {
      h = _u32(h ^ c);
      h = _u32(_imul(h, 16777619));
    }
    return h;
  }

  static double Function() rng(int seed) {
    var s = _i32(seed);
    return () {
      s = _i32(s + 0x6D2B79F5);
      var t = _imul(s ^ (_u32(s) >> 15), 1 | s);
      t = _i32(_i32(t + _imul(t ^ (_u32(t) >> 7), 61 | t)) ^ t);
      return _u32(t ^ (_u32(t) >> 14)) / 4294967296;
    };
  }

  static List<Story> get _all => Library.stories;
  static Story? byId(String id) {
    for (final s in _all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /* ---- المناسبات (ميلادي أو هجري أم القرى) ---- */
  static Story? occasion(DateTime d) {
    HijriCalendar? h;
    try {
      h = HijriCalendar.fromDate(d);
    } catch (_) {}
    for (final s in _all) {
      final o = s.occ;
      if (o == null) continue;
      final days = ((o['d'] as List?) ?? []).map((x) => (x as num).toInt()).toList();
      final m = (o['m'] as num?)?.toInt();
      if (o['cal'] == 'g' && m == d.month && days.contains(d.day)) return s;
      if (o['cal'] == 'h' && h != null && m == h.hMonth && days.contains(h.hDay)) return s;
    }
    return null;
  }

  /// القصص بالدور: ترتيب ثابت لكل عائلة
  static List<Story> queue() {
    final r = rng(hash('${Family.I.code.isEmpty ? 'x' : Family.I.code}#queue'));
    final reg = _all.where((s) => s.occ == null && !s.isNarr && !s.laterPart).map((s) => (r(), s)).toList()..sort((a, b) => a.$1.compareTo(b.$1));
    final regs = reg.map((x) => x.$2).toList();
    final pro = <Story>[], sah = _all.where((s) => s.isSah).toList(), out = <Story>[], qan = _all.where((s) => s.isQan).toList();
    final pros = _all.where((s) => s.isPro).toList();
    for (var j = 0; j < pros.length; j++) {
      pro.add(pros[j]);
      if (j % 4 == 3 && qan.isNotEmpty) pro.add(qan.removeAt(0));
    }
    pro.addAll(qan);
    var i = 0, p = 0, c = 0, turn = 0;
    while (i < regs.length || p < pro.length || c < sah.length) {
      for (var k = 0; k < 2 && i < regs.length; k++) {
        out.add(regs[i++]);
      }
      if (turn % 2 == 0 ? p < pro.length : c >= sah.length) {
        if (p < pro.length) out.add(pro[p++]);
      } else if (c < sah.length) {
        out.add(sah[c++]);
      }
      turn++;
    }
    return out;
  }

  static List<Story>? _q;
  static String _qKey = '';
  static List<Story> get _queue {
    if (_q == null || _qKey != Family.I.code) {
      _q = queue();
      _qKey = Family.I.code;
    }
    return _q!;
  }

  /// قائمة قصص الليلة لأبطال الليلة (أول ٦)
  static List<Story> list(List<Kid> hs) {
    final ids = hs.map((h) => h.id).where((x) => x.isNotEmpty).toList();
    final f = Family.I;
    final today = {Family.dateKey(DateTime.now()), f.nightKey};
    final logs = f.allLogs.where((e) => ids.isEmpty || ((e['k'] as List?) ?? []).any(ids.contains)).toList();
    final before = logs.where((e) => !today.contains(e['d'])).toList();
    final readB = before.map((e) => e['s'].toString()).toSet();
    final out = <Story>[];
    final occ = occasion(DateTime.now());
    if (occ != null) out.add(occ);
    for (final e in before) {
      final s = byId(e['s'].toString());
      if (s != null && s.ser.isNotEmpty) {
        Story? nx;
        for (final x in _all) {
          if (x.ser == s.ser && x.part == s.part + 1) nx = x;
        }
        if (nx != null && !readB.contains(nx.id)) out.add(nx);
        break;
      }
    }
    final q = _queue;
    var fresh = q.where((s) => !readB.contains(s.id) && !out.contains(s)).toList();
    if (fresh.length < 6) fresh = [...fresh, ...q.where((s) => !fresh.contains(s) && !out.contains(s))];
    return [...out, ...fresh].take(6).toList();
  }

  /// كم قصة انقرت الليلة من القائمة
  static int readCount(List<Kid> hs) {
    final day = {Family.dateKey(DateTime.now()), Family.I.nightKey};
    final hid = hs.map((h) => h.id).toSet();
    final ids = Family.I.allLogs.where((e) => day.contains(e['d']) && (hid.isEmpty || ((e['k'] as List?) ?? []).any(hid.contains))).map((e) => e['s'].toString()).toSet();
    if (hid.every((x) => x.isEmpty)) {
      for (final e in Family.I.log) {
        if (day.contains(e['d'])) ids.add(e['s'].toString());
      }
    }
    return list(hs).where((s) => ids.contains(s.id)).length;
  }

  /// القصة الجاية الليلة (أو null لو خلصوا العدد المسموح)
  static Story? next(List<Kid> hs) {
    final n = readCount(hs);
    return n < Family.I.allowedTonight ? list(hs)[n] : null;
  }

  /* ---- التصنيفات ---- */
  static final cats = <(String, String, String, RegExp?)>[
    ('pro', '🕌', 'قصص الأنبياء', null),
    ('sahaba', '🌟', 'قصص الصحابة', null),
    ('saudi', '🇸🇦', 'سعوديتي', null),
    ('qanimal', '🐪', 'حيوانات في القرآن', null),
    ('choose', '🧭', 'اختر الطريق', null),
    ('series', '📚', 'سلاسل', null),
    ('occ', '🎉', 'المناسبات', null),
    ('truth', '🤝', 'الصدق والأمانة', RegExp(r'الصدق|الأمانة|الوفاء|الوعد')),
    ('share', '🎁', 'المشاركة والعطاء', RegExp(r'المشاركة|العطاء|التعاون|الكرم|ضيف|مساعدة|نصرة|التطوعي|الصدقة|العاملين|الإيثار')),
    ('mercy', '💗', 'الرحمة واللطف', RegExp(r'الرحمة|الرفق|اللطف|التسامح|المريض|الاعتذار')),
    ('brave', '🦁', 'الشجاعة والثقة', RegExp(r'الشجاعة|الثقة|المحاولة|الطموح|تقبّل')),
    ('patience', '🌱', 'الصبر', RegExp(r'الصبر|ضبط|الهدوء|التركيز|الطمأنينة')),
    ('faith', '🤲', 'الإيمان والعبادة', RegExp(r'الصلاة|العبادة|الشكر|الامتنان|رمضان|العيد')),
    ('know', '📚', 'العلم والمعرفة', RegExp(r'العلم|القراءة|تعلّم|التأمّل|التعليم|الخيال|الاستماع|التعلّم')),
    ('family', '🏠', 'العائلة', RegExp(r'الوالدين|العائلة|الكبار|الحب')),
    ('habits', '✨', 'العادات الجميلة',
        RegExp(r'النظافة|الترتيب|النوم|الأكل|الاستعداد|السلامة|الأمان|آداب|الاستئذان|السلام|إماطة|الأجهزة|الوقت|المسؤولية|المال|الادّخار|البيئة|النِّعَم|القناعة|البيت|الطعام|الدور')),
    ('manners', '🌟', 'أخلاق جميلة', null),
  ];

  static (String, String, String, RegExp?) catOf(Story s) {
    (String, String, String, RegExp?) by(String k) => cats.firstWhere((c) => c.$1 == k);
    if (s.isPro) return cats[0];
    if (s.isSah) return cats[1];
    if (s.category == 'saudi' || s.category == 'qanimal') return by(s.category);
    if (s.cat2 == 'choose') return by('choose');
    if (s.ser.isNotEmpty) return by('series');
    if (s.occ != null) return by('occ');
    for (final c in cats) {
      if (c.$4 != null && c.$4!.hasMatch(s.value)) return c;
    }
    return cats.last;
  }

  /// مستوى القصة حسب عمر الأبطال: ١ = ٣-٥ (نسخة قصيرة)
  static int level(List<Kid> hs) {
    final ag = hs.map((k) => k.age).where((a) => a > 0).toList();
    if (!Family.I.shortKids || ag.isEmpty) return 3;
    return ag.reduce((a, b) => a < b ? a : b);
  }

  /// في قصص الأنبياء: ما نرسم الأطفال إلا في الصفحات اللي هم فيها يسمعون
  static List<Kid> artHeroes(Story s, List<Kid> hs, [StoryPage? p]) => s.isNarr ? (p != null && p.kids ? hs : const []) : hs;
}

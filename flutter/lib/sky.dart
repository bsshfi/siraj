import 'dart:convert';

import 'package:flutter/services.dart';

import 'data.dart';
import 'family.dart';
import 'tonight_logic.dart';

/// سماء سراج: الكوكبات، الملصقات، الهدايا، لوحة الشرف — منقولة من play.js و honors.js و room.js
class Sky {
  static const consts = ['كوكبة الصدق', 'كوكبة الشجاعة', 'كوكبة الرحمة', 'كوكبة المشاركة', 'كوكبة الصبر', 'كوكبة العلم', 'كوكبة البرّ', 'كوكبة الأمانة', 'كوكبة اللطف', 'كوكبة التعاون', 'كوكبة الشكر', 'كوكبة الأحلام'];
  static const shapes = [
    [[40, 150], [80, 110], [130, 120], [160, 70], [200, 90], [240, 50], [270, 100]],
    [[60, 60], [100, 40], [150, 60], [150, 110], [110, 150], [70, 130], [190, 150]],
    [[150, 30], [110, 70], [190, 70], [80, 120], [220, 120], [120, 165], [180, 165]],
    [[40, 100], [90, 60], [140, 100], [190, 60], [240, 100], [140, 150], [140, 40]],
    [[150, 20], [150, 70], [100, 110], [200, 110], [70, 160], [150, 140], [230, 160]],
    [[60, 150], [60, 90], [110, 50], [170, 50], [220, 90], [220, 150], [140, 120]],
  ];

  static const stickC = ['🐱', '🐶', '🐰', '🐻', '🐼', '🐨', '🐸', '🐥', '🐢', '🐠', '🦋', '🐞', '🌻', '🌈', '🍉', '🍓', '🍩', '🎈', '⚽', '🪁', '🧸', '🚗', '🎨', '📚'];
  static const stickR = ['🦊', '🦒', '🐬', '🦜', '🐙', '🚀', '🏰', '🎡', '🌋'];
  static const stickL = ['🦄', '🐉', '👑'];
  static final allStickers = [...stickC.map((e) => (e, 'c')), ...stickR.map((e) => (e, 'r')), ...stickL.map((e) => (e, 'l'))];
  static const stNames = {
    '🐱': 'قطة', '🐶': 'كلب', '🐰': 'أرنب', '🐻': 'دبدوب', '🐼': 'باندا', '🐨': 'كوالا', '🐸': 'ضفدع', '🐥': 'صوص', '🐢': 'سلحفاة', '🐠': 'سمكة', '🦋': 'فراشة', '🐞': 'دعسوقة',
    '🌻': 'زهرة شمس', '🌈': 'قوس قزح', '🍉': 'بطيخ', '🍓': 'فراولة', '🍩': 'دونات', '🎈': 'بالون', '⚽': 'كورة', '🪁': 'طيارة ورق', '🧸': 'دبدوب قطني', '🚗': 'سيارة', '🎨': 'ألوان', '📚': 'كتب',
    '🦊': 'ثعلب', '🦒': 'زرافة', '🐬': 'دلفين', '🦜': 'ببغاء', '🐙': 'أخطبوط', '🚀': 'صاروخ', '🏰': 'قلعة', '🎡': 'دولاب الهوا', '🌋': 'بركان', '🦄': 'حصان وحيد القرن', '🐉': 'تنين', '👑': 'تاج ذهبي',
  };
  static const rarity = {'c': ('ملصق', ''), 'r': ('ملصق نادر', '🟣'), 'l': ('ملصق أسطوري', '🌟')};
  static const actName = {
    'color': 'لوّنت المشهد 🎨', 'puzzle': 'رتّبت الأحجية 🧩', 'quiz': 'جاوبت أسئلة القصة ❓', 'en': 'لعبت English 🔤', 'space': 'اكتشفت الفضاء 🪐', 'adhkar': 'قلت أذكار النوم 🤲',
    'trip': 'لعبت رحلة حول العالم ✈️', 'flags': 'لعبت لعبة الأعلام 🚩',
  };
  static const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  /// الهدايا (إكسسوارات الشخصية) من art.js
  static List<Map<String, dynamic>> acc = [];
  static List<Map<String, dynamic>> roomItems = []; // [id, name, stars, svg]
  static Map<String, String> roomBox = {};

  static Future<void> load() async {
    try {
      final a = jsonDecode(await rootBundle.loadString('assets/data/art.json')) as Map;
      acc = ((a['ACC'] as List?) ?? []).map((x) => Map<String, dynamic>.from(x as Map)).toList();
      final r = jsonDecode(await rootBundle.loadString('assets/data/room.json')) as Map;
      roomItems = ((r['ITEMS'] as List?) ?? []).map((x) => {'id': (x as List)[0], 'name': x[1], 'stars': x[2], 'svg': x[3]}).toList();
      roomBox = Map<String, String>.from((r['BOX'] as Map?) ?? {});
    } catch (_) {}
  }

  static (String, String) stickerFor(Map e, String kidId) {
    final v = Tonight.hash('${e['t']}:${e['s']}:$kidId');
    final r = (v % 1000) / 1000;
    String pick(List<String> a) => a[(v >> 10) % a.length];
    return r < .04 ? (pick(stickL), 'l') : r < .24 ? (pick(stickR), 'r') : (pick(stickC), 'c');
  }

  /// كل أحداث الطفل (قصص + أنشطة) مع ملصق كل حدث — الأقدم أول
  static List<Map<String, dynamic>> events(Kid k) {
    final f = Family.I, ev = <Map<String, dynamic>>[];
    for (final e in f.allLogs) {
      if (((e['k'] as List?) ?? []).contains(k.id)) ev.add({'t': e['t'], 's': e['s'], 'd': e['d'], 'type': 'story'});
    }
    for (final a in f.allActs) {
      if (((a['k'] as List?) ?? []).contains(k.id)) {
        ev.add({'t': a['t'], 's': '${a['s'] ?? 'undefined'}${a['a']}', 'd': Family.dateKey(DateTime.fromMillisecondsSinceEpoch(((a['t'] as num?) ?? 0).toInt())), 'type': a['a'], 'sid': a['s']});
      }
    }
    ev.sort((a, b) => ((a['t'] as num?) ?? 0).compareTo((b['t'] as num?) ?? 0));
    for (final e in ev) {
      e['st'] = stickerFor(e, k.id);
    }
    return ev;
  }

  static int kidStories(Kid k) => Family.I.allLogs.where((e) => ((e['k'] as List?) ?? []).contains(k.id)).map((e) => e['s']).toSet().length;

  /// (عدد القصص، الكوكبات المكتملة، نجوم الكوكبة الحالية)
  static (int, int, int) info(Kid k) {
    final n = kidStories(k);
    return (n, n ~/ 7, n % 7);
  }

  /* ---------------- لوحة الشرف والشارات (honors.js) ---------------- */
  static Map<String, dynamic> stats(Kid k, int from, [int? to]) {
    final f = Family.I, end = to ?? DateTime.now().millisecondsSinceEpoch;
    bool inR(Map e) => ((e['k'] as List?) ?? []).contains(k.id) && ((e['t'] as num?) ?? 0) >= from && ((e['t'] as num?) ?? 0) < end;
    final logs = f.allLogs.where(inR).toList(), acts = f.allActs.where(inR).toList();
    int cnt(bool Function(Map) p) => acts.where(p).length;
    return {
      'stories': logs.length,
      'nights': logs.map((e) => e['d']).toSet().length,
      'en': cnt((a) => a['a'] == 'en'),
      'space': cnt((a) => a['a'] == 'space'),
      'adhkar': acts.where((a) => a['a'] == 'adhkar').map((a) => Family.dateKey(DateTime.fromMillisecondsSinceEpoch(((a['t'] as num?) ?? 0).toInt()))).toSet().length,
      'play': cnt((a) => ['color', 'puzzle', 'quiz'].contains(a['a'])),
      'pro': logs.map((e) => e['s'].toString()).where((s) => RegExp(r'^p\d').hasMatch(s)).toSet().length,
      'logs': logs,
    };
  }

  static int weekStart() {
    final d = DateTime.now();
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday % 7)).millisecondsSinceEpoch;
  }

  static const titles = [
    ('nights', '📚', 'قارئ الأسبوع', 'قارئة الأسبوع', 3),
    ('adhkar', '🤲', 'صاحب الأذكار', 'صاحبة الأذكار', 3),
    ('en', '🔤', 'بطل الإنجليزي', 'بطلة الإنجليزي', 3),
    ('space', '🚀', 'رائد الفضاء', 'رائدة الفضاء', 1),
    ('play', '🎨', 'الفنان المبدع', 'الفنانة المبدعة', 3),
  ];

  /// ألقاب الأسبوع: تروح لأكثر واحد (ولو تعادلوا ياخذونها كلهم)
  static (Map<String, List<(String, String)>>, List<(Kid, Map<String, dynamic>)>) titlesFor(List<Kid> kids, int from) {
    final st = kids.map((k) => (k, stats(k, from))).toList();
    final out = <String, List<(String, String)>>{};
    for (final t in titles) {
      final best = st.fold<int>(0, (m, x) => (x.$2[t.$1] as int) > m ? x.$2[t.$1] as int : m);
      if (best >= t.$5) {
        for (final x in st.where((x) => x.$2[t.$1] == best)) {
          (out[x.$1.id] ??= []).add((t.$2, x.$1.isGirl ? t.$4 : t.$3));
        }
      }
    }
    return (out, st);
  }

  static List<(String, String, bool)> badgesOf(Kid k) {
    final t = stats(k, 0);
    final sk = Family.I.streakOf(k);
    return [
      ('📖', '١٠ قصص', (t['stories'] as int) >= 10),
      ('📚', '٢٥ قصة', (t['stories'] as int) >= 25),
      ('🏅', '٥٠ قصة', (t['stories'] as int) >= 50),
      ('🏆', '١٠٠ قصة', (t['stories'] as int) >= 100),
      ('🔥', '٧ ليالٍ متتالية', sk >= 7),
      ('🕌', '١٠ قصص أنبياء', (t['pro'] as int) >= 10),
      ('🤲', '٧ ليالٍ أذكار', (t['adhkar'] as int) >= 7),
      ('🔤', '٢٠ نشاط إنجليزي', (t['en'] as int) >= 20),
      ('🪐', 'مستكشف الفضاء', (t['space'] as int) >= 3),
    ];
  }

  /* ---------------- رسومات SVG (نفس الويب) ---------------- */
  static String skySvg(int idx, int lit) {
    final sh = shapes[idx % shapes.length];
    final b = StringBuffer();
    var s = idx * 97 + 13;
    double r() => (s = (s * 9301 + 49297) % 233280) / 233280;
    for (var i = 0; i < 40; i++) {
      b.write('<circle cx="${(r() * 300).toStringAsFixed(0)}" cy="${(r() * 200).toStringAsFixed(0)}" r="${(r() * 1.2 + .3).toStringAsFixed(1)}" fill="#fff" opacity="${(r() * .5 + .2).toStringAsFixed(2)}"/>');
    }
    for (var e = 0; e < 6; e++) {
      if (e + 1 < lit) b.write('<line x1="${sh[e][0]}" y1="${sh[e][1]}" x2="${sh[e + 1][0]}" y2="${sh[e + 1][1]}" stroke="#FFE27A" stroke-width="1.6" opacity=".6"/>');
    }
    for (var i = 0; i < sh.length; i++) {
      final x = sh[i][0], y = sh[i][1];
      b.write(i < lit
          ? '<circle cx="$x" cy="$y" r="11" fill="#FFD93D" opacity=".25"/><path d="M$x ${y - 9} l2.6 6 6.4 .6 -4.8 4.3 1.4 6.3 -5.6 -3.3 -5.6 3.3 1.4 -6.3 -4.8 -4.3 6.4 -.6z" fill="#FFD93D"/>'
          : '<circle cx="$x" cy="$y" r="4" fill="#ffffff" opacity=".25"/>');
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 200"><defs><radialGradient id="sky" cx=".5" cy=".3" r=".9"><stop offset="0" stop-color="#3B2A7A"/><stop offset="1" stop-color="#120F33"/></radialGradient></defs><rect width="300" height="200" rx="18" fill="url(#sky)"/>$b</svg>';
  }

  /// الغرفة بدون الطفل (الطفل نرسمه فوقها بالشخصية الحقيقية)
  static String roomSvg(int stars) {
    final on = roomItems.where((it) => stars >= (it['stars'] as num)).map((it) => it['svg']).join();
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 240"><defs><linearGradient id="rmW" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#EDE4FF"/><stop offset="1" stop-color="#F9E8F3"/></linearGradient><linearGradient id="rmF" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E7B98A"/><stop offset="1" stop-color="#D49A69"/></linearGradient></defs>'
        '<rect width="360" height="190" fill="url(#rmW)"/><g fill="#fff" opacity=".5"><circle cx="40" cy="20" r="2"/><circle cx="120" cy="12" r="2"/><circle cx="330" cy="30" r="2"/></g>'
        '<rect x="112" y="18" width="62" height="54" rx="8" fill="#2B2F6B" stroke="#F6E2C6" stroke-width="5"/><path d="M143 18v54M112 45h62" stroke="#F6E2C6" stroke-width="3"/><circle cx="130" cy="34" r="7" fill="#FFE27A"/><circle cx="133" cy="32" r="6" fill="#2B2F6B"/><g fill="#fff"><circle cx="160" cy="30" r="1.3"/><circle cx="125" cy="58" r="1.1"/><circle cx="162" cy="60" r="1.3"/></g>'
        '<rect x="226" y="24" width="98" height="56" rx="6" fill="#D9A877"/><rect x="230" y="28" width="90" height="48" rx="4" fill="#F3D9B8"/>'
        '<rect y="186" width="360" height="54" fill="url(#rmF)"/><rect y="184" width="360" height="5" fill="#C78B58"/>'
        '<g transform="translate(250 150)"><rect x="-8" y="30" width="110" height="12" rx="4" fill="#9B6A45"/><rect x="0" y="12" width="100" height="22" rx="8" fill="#B79BF5"/><rect x="0" y="12" width="34" height="16" rx="6" fill="#fff"/><rect x="-8" y="-6" width="12" height="48" rx="5" fill="#9B6A45"/></g>'
        '$on</svg>';
  }

  static String itemSvg(Map<String, dynamic> it) => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="${roomBox[it['id']] ?? '0 0 360 240'}">${it['svg']}</svg>';
}

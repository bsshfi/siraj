import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// محتوى أنا/اكتشف/العب وتعلّم — مصدّر من نسخة الويب (assets/data/learn.json)
class Learn {
  static Map<String, dynamic> d = {};

  static Future<void> load() async {
    try {
      d = Map<String, dynamic>.from(jsonDecode(await rootBundle.loadString('assets/data/learn.json')) as Map);
    } catch (_) {}
  }

  static List<List<String>> _rows(String k) => ((d[k] as List?) ?? []).map((r) => (r as List).map((x) => x.toString()).toList()).toList();
  static List<Map<String, dynamic>> _maps(String k) => ((d[k] as List?) ?? []).map((m) => Map<String, dynamic>.from(m as Map)).toList();

  /// [حرف، كلمة، معنى، إيموجي]
  static List<List<String>> get letters => _rows('letters');
  /// فئة → [[كلمة، معنى، إيموجي]]
  static Map<String, List<List<String>>> get words =>
      ((d['words'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), (v as List).map((r) => (r as List).map((x) => x.toString()).toList()).toList()));
  /// [جملة، معنى، إيموجي]
  static List<List<String>> get sentences => _rows('sentences');
  static List<String> get sight => ((d['sight'] as List?) ?? []).map((x) => x.toString()).toList();
  static List<List<String>> get mansions => _rows('mansions');
  static List<List<String>> get stars => _rows('stars');
  /// [سؤال، الصح، خطأ، خطأ]
  static List<List<String>> get spaceQuiz => _rows('spaceQuiz');
  static List<Map<String, dynamic>> get planets => _maps('planets');
  static List<Map<String, dynamic>> get adhkar => _maps('adhkar');
  static List<Map<String, dynamic>> get countries => _maps('countries');
  static List<List<String>> get regions => _rows('regions');
  static Map<String, dynamic>? info(String c) => (d['info'] as Map?)?[c] == null ? null : Map<String, dynamic>.from((d['info'] as Map)[c] as Map);

  static String flag(String c) => String.fromCharCodes(c.toUpperCase().codeUnits.map((x) => 0x1F1E6 + x - 65));
  static String ar(Object n) => n.toString().replaceAllMapped(RegExp(r'\d'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]);

  /* ---- القمر (نفس حسابات space.js) ---- */
  static const syn = 29.530588853;
  static double _jd(DateTime d) => d.millisecondsSinceEpoch / 864e5 + 2440587.5;
  static double moonAge([DateTime? d]) {
    var a = ((_jd(d ?? DateTime.now()) - 2451550.1) / syn) % 1;
    if (a < 0) a += 1;
    return a * syn;
  }

  static int illum(double age) => ((1 - math.cos(2 * math.pi * age / syn)) / 2 * 100).round();

  static (String, String) phase(double age) {
    for (final p in (d['phases'] as List?) ?? []) {
      final r = p as List;
      if (age < (r[0] as num)) return (r[1].toString(), r[2].toString());
    }
    return ('', '');
  }

  static int mansionIdx([DateTime? t]) {
    final n = _jd(t ?? DateTime.now()) - 2451545;
    final l = 218.316 + 13.176396 * n, m = (134.963 + 13.064993 * n) * math.pi / 180;
    final lon = ((l + 6.289 * math.sin(m)) % 360 + 360) % 360;
    return (((((lon - 24) % 360) + 360) % 360) / (360 / 28)).floor().clamp(0, 27);
  }
}

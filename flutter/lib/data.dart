import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صفحة من قصة. [choices] لصفحات "اختر الطريق": كل خيار = (النص، رقم الصفحة اللي يروح لها).
class StoryPage {
  final String text;
  final String scene;
  final String prop;
  final List<(String, int)> choices;
  final bool isEnd;

  StoryPage({required this.text, required this.scene, required this.prop, this.choices = const [], this.isEnd = false});

  factory StoryPage.fromJson(Map<String, dynamic> j, String fallbackScene) {
    final ch = <(String, int)>[];
    final raw = j['ch'];
    if (raw is List) {
      for (final c in raw) {
        if (c is List && c.length >= 2) ch.add((c[0].toString(), (c[1] as num).toInt()));
      }
    }
    return StoryPage(
      text: (j['t'] ?? '').toString(),
      scene: (j['s'] ?? fallbackScene).toString(),
      prop: (j['p'] ?? '').toString(),
      choices: ch,
      isEnd: j['end'] != null && j['end'] != 0 && j['end'] != false,
    );
  }
}

class Story {
  final String id;
  final String title;
  final String value;
  final String scene;
  final String question;
  final String category;
  final List<StoryPage> pages;

  Story({required this.id, required this.title, required this.value, required this.scene, required this.question, required this.category, required this.pages});

  factory Story.fromJson(Map<String, dynamic> j) {
    final scene = (j['scene'] ?? 'home').toString();
    return Story(
      id: j['id'].toString(),
      title: (j['title'] ?? '').toString(),
      value: (j['value'] ?? '').toString(),
      scene: scene,
      question: (j['q'] ?? '').toString(),
      category: (j['cat'] ?? '').toString(),
      pages: ((j['pages'] as List?) ?? []).map((p) => StoryPage.fromJson(Map<String, dynamic>.from(p as Map), scene)).toList(),
    );
  }
}

/// بطل القصة: الاسم + ولد/بنت ('m' أو 'f')
class Kid {
  final String name;
  final String gender;
  const Kid(this.name, this.gender);
  bool get isGirl => gender == 'f';
}

class Library {
  static List<Story> stories = [];

  static Future<void> load() async {
    if (stories.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/data/stories.json');
    final list = jsonDecode(raw) as List;
    stories = list.map((e) => Story.fromJson(Map<String, dynamic>.from(e as Map))).where((s) => s.pages.isNotEmpty).toList();
  }

  /// قصة الليلة: تتغير كل يوم، وثابتة طول اليوم.
  static Story tonight([DateTime? now]) {
    final d = now ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day).difference(DateTime(2024, 1, 1)).inDays;
    final pool = stories.where((s) => s.category.isEmpty && !s.id.startsWith('o')).toList();
    final list = pool.isEmpty ? stories : pool;
    return list[day % list.length];
  }
}

/// نفس محرّك القوالب في نسخة الويب (app.js → fill):
/// {n} الاسم، {أ|ب} ولد|بنت، [[...]] يظهر لو فيه مشاركين، {{أ|ب|ج}} حسب المشاركين، {fr} أسماء المشاركين، {dad} {mom}
String fillTemplate(String str, Kid hero, {List<Kid> friends = const [], String dad = 'بابا', String mom = 'ماما'}) {
  final g = hero.isGirl ? 1 : 0;
  final cg = friends.length > 1 ? 2 : friends.length == 1 ? (friends.first.isGirl ? 1 : 0) : 0;
  var s = str.replaceAllMapped(RegExp(r'\[\[([\s\S]*?)\]\]'), (m) => friends.isNotEmpty ? m[1]! : '');
  s = s.replaceAllMapped(RegExp(r'\{\{([^{}]*)\}\}'), (m) {
    final o = m[1]!.split('|');
    return cg < o.length ? o[cg] : o.last;
  });
  s = s.replaceAllMapped(RegExp(r'\{([^{}|]*)\|([^{}|]*)\}'), (m) => g == 1 ? m[2]! : m[1]!);
  final fr = friends.map((f) => f.name).toList();
  final frText = fr.isEmpty ? '' : fr.length == 1 ? fr.first : '${fr.sublist(0, fr.length - 1).join('، ')} و${fr.last}';
  return s.replaceAll('{n}', hero.name).replaceAll('{fr}', frText).replaceAll('{dad}', dad).replaceAll('{mom}', mom);
}

/// إعدادات بسيطة محفوظة على الجهاز (المرحلة ١). المرحلة ٢: الربط برمز العائلة والمزامنة.
class Profile {
  static const _kName = 'hero_name', _kGender = 'hero_gender', _kRate = 'tts_rate', _kDone = 'read_ids';
  static Kid? hero;
  static double rate = 0.45;
  static Set<String> done = {};

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getString(_kName);
    if (n != null && n.trim().isNotEmpty) hero = Kid(n, p.getString(_kGender) ?? 'm');
    rate = p.getDouble(_kRate) ?? 0.45;
    done = (p.getStringList(_kDone) ?? []).toSet();
  }

  static Future<void> saveHero(Kid h) async {
    hero = h;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, h.name);
    await p.setString(_kGender, h.gender);
  }

  static Future<void> saveRate(double r) async {
    rate = r;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kRate, r);
  }

  static Future<void> markDone(String id) async {
    done.add(id);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kDone, done.toList());
  }
}

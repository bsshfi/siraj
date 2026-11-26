import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'sync.dart';

/// حالة العائلة على هالجهاز (جهاز طفل) — متوافقة مع نسخة الويب:
/// نفس شكل سجل القراءة ونفس بيانات المزامنة، فلوحة الوالدين تشوف قراءات التطبيق عادي.
class Family extends ChangeNotifier {
  static final Family I = Family._();
  Family._();

  static const _k = 'family_v1';
  String code = '';
  String dev = '';
  int rev = 0;
  Map<String, dynamic> fam = {};
  List<String> devKids = []; // الأطفال اللي يستخدمون هالجهاز
  List<String> sel = []; // أبطال الليلة (أول واحد هو البطل)
  List<Map<String, dynamic>> log = [];
  List<Map<String, dynamic>> act = []; // أنشطة: en, space, adhkar, trip, flags…
  List<Map<String, dynamic>> remote = []; // تقدّم أجهزة العائلة الثانية
  Set<String> passport = {}; // الدول اللي زرناها
  bool _progDirty = false;
  bool syncing = false;

  bool get linked => code.isNotEmpty;
  String get dad => (fam['dad'] ?? 'بابا').toString();
  String get mom => (fam['mom'] ?? 'ماما').toString();
  String get bedtime => (fam['bedtime'] ?? '20:30').toString();

  List<Kid> get kids => ((fam['kids'] as List?) ?? [])
      .whereType<Map>()
      .map((m) => Kid.fromJson(Map<String, dynamic>.from(m)))
      .where((k) => k.name.isNotEmpty)
      .toList();

  /// أطفال هالجهاز (لو ما اختار أحد: الكل)
  List<Kid> get myKids {
    final all = kids;
    final mine = all.where((k) => devKids.contains(k.id)).toList();
    return mine.isEmpty ? all : mine;
  }

  /// أبطال الليلة بالترتيب
  List<Kid> get heroes {
    final mine = myKids;
    final picked = <Kid>[for (final id in sel) ...mine.where((k) => k.id == id).take(1)];
    return picked.isNotEmpty ? picked : mine.take(1).toList();
  }

  int starsOf(String kidId) => allLogs.where((e) => (e['k'] as List?)?.contains(kidId) ?? false).length;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_k);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map;
        code = (j['code'] ?? '').toString();
        dev = (j['dev'] ?? '').toString();
        rev = (j['rev'] as num?)?.toInt() ?? 0;
        fam = Map<String, dynamic>.from((j['fam'] as Map?) ?? {});
        devKids = List<String>.from((j['devKids'] as List?) ?? []);
        sel = List<String>.from((j['sel'] as List?) ?? []);
        log = ((j['log'] as List?) ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        act = ((j['act'] as List?) ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        remote = ((j['remote'] as List?) ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        passport = Set<String>.from((j['passport'] as List?) ?? []);
        _progDirty = j['progDirty'] == true;
      } catch (_) {}
    }
    if (dev.isEmpty) {
      const a = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final r = Random.secure();
      dev = List.generate(8, (_) => a[r.nextInt(a.length)]).join();
      await save();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k, jsonEncode({'code': code, 'dev': dev, 'rev': rev, 'fam': fam, 'devKids': devKids, 'sel': sel, 'log': log, 'act': act, 'remote': remote, 'passport': passport.toList(), 'progDirty': _progDirty}));
  }

  /// الربط برمز العائلة — يرجع رسالة خطأ أو null لو نجح
  Future<String?> join(String input) async {
    final c = Sync.norm(input);
    if (c.isEmpty) return 'الرمز ١٠ حروف وأرقام، مثل K7QPM-4XR2D';
    try {
      final (Map<String, dynamic>, int)? r;
      try {
        r = await Sync.pullFamily(c);
      } on FormatException {
        return 'الرمز صحيح الشكل بس ما قدرنا نفتح بيانات العائلة';
      } catch (e) {
        if (e.toString().contains('SecretBox') || e.toString().contains('MAC')) return 'الرمز ما يطابق بيانات العائلة، تأكد منه';
        return 'تعذّر الاتصال، تأكد من الإنترنت';
      }
      if (r == null) return 'ما لقينا عائلة بهذا الرمز';
      code = c;
      fam = r.$1;
      rev = r.$2;
      final all = kids;
      devKids = all.length == 1 ? [all.first.id] : [];
      sel = [];
      _progDirty = true;
      await save();
      notifyListeners();
      syncNow();
      return null;
    } catch (e) {
      return 'تعذّر الربط ($e)';
    }
  }

  Future<void> setDevKids(List<String> ids) async {
    devKids = ids;
    sel = sel.where(ids.contains).toList();
    _progDirty = true;
    await save();
    notifyListeners();
    syncNow();
  }

  Future<void> setHeroes(List<String> ids) async {
    sel = ids;
    await save();
    notifyListeners();
  }

  Future<void> unlink() async {
    code = '';
    fam = {};
    rev = 0;
    devKids = [];
    sel = [];
    remote = [];
    await save();
    notifyListeners();
  }

  /// تسجيل نشاط (نفس صيغة الويب: {a, s, k, t, sc})
  Future<void> logAct(String a, {String s = '', int score = 0, List<Kid>? who}) async {
    final ids = (who ?? currentHeroes()).map((k) => k.id).where((id) => id.isNotEmpty).toList();
    act.add({'a': a, 's': s, 'k': ids, 't': DateTime.now().millisecondsSinceEpoch, 'sc': score});
    if (act.length > 600) act = act.sublist(act.length - 600);
    _progDirty = true;
    await save();
    notifyListeners();
    if (linked) syncNow();
  }

  Future<void> stamp(String country) async {
    passport.add(country);
    await save();
    notifyListeners();
  }

  Future<void> clearMine() async {
    log = [];
    act = [];
    _progDirty = true;
    await save();
    notifyListeners();
    syncNow();
  }

  List<Map<String, dynamic>> _merge(String key) {
    final seen = <String>{}, out = <Map<String, dynamic>>[];
    void add(Map<String, dynamic> e) {
      final k = '${e['t']}${e['s']}${e['a'] ?? ''}';
      if (seen.add(k)) out.add(e);
    }
    for (final e in key == 'log' ? log : act) {
      add(e);
    }
    for (final p in remote) {
      for (final e in (p[key] as List? ?? []).whereType<Map>()) {
        add(Map<String, dynamic>.from(e));
      }
    }
    out.sort((a, b) => ((a['t'] as num?) ?? 0).compareTo((b['t'] as num?) ?? 0));
    return out;
  }

  /// كل القراءات والأنشطة من كل أجهزة العائلة
  List<Map<String, dynamic>> get allLogs => _merge('log');
  List<Map<String, dynamic>> get allActs => _merge('act');

  static bool _has(Map e, String id) => (e['k'] as List?)?.contains(id) ?? false;
  List<Map<String, dynamic>> logsOf(Kid k) => k.id.isEmpty ? log : allLogs.where((e) => _has(e, k.id)).toList();
  List<Map<String, dynamic>> actsOf(Kid k) => k.id.isEmpty ? act : allActs.where((e) => _has(e, k.id)).toList();

  /// ليالي متتالية فيها قراءة
  int streakOf(Kid k) {
    final days = logsOf(k).map((e) => e['d'].toString()).toSet();
    var d = DateTime.now();
    if (!days.contains(_dateKey(d))) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(_dateKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  static String dateKey(DateTime d) => _dateKey(d);
  static String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// تسجيل قراءة قصة (نفس صيغة الويب) + إشعار الوالدين
  Future<void> logStory(String storyId, List<Kid> hs) async {
    final ids = hs.map((k) => k.id).where((id) => id.isNotEmpty).toList();
    log.add({'s': storyId, 'd': _dateKey(DateTime.now()), 'k': ids, 't': DateTime.now().millisecondsSinceEpoch});
    if (log.length > 1500) log = log.sublist(log.length - 1500);
    _progDirty = true;
    await save();
    notifyListeners();
    if (linked) {
      Sync.event(code, dev, ids, storyId).catchError((_) {});
      syncNow();
    }
  }

  /// سحب تحديثات العائلة (أسماء، أشكال، وقت النوم) + رفع سجل هالجهاز
  Future<void> syncNow() async {
    if (!linked || syncing) return;
    syncing = true;
    try {
      final r = await Sync.pullFamily(code);
      if (r != null && r.$2 > rev) {
        fam = r.$1;
        rev = r.$2;
        notifyListeners();
      }
      if (_progDirty) {
        await Sync.pushProgress(code, dev, {
          'role': 'child',
          'log': log.length > 500 ? log.sublist(log.length - 500) : log,
          'fav': <String>[],
          'act': act.length > 300 ? act.sublist(act.length - 300) : act,
          'trips': <dynamic>[],
          'kids': devKids,
          'plat': 'android-app',
          'ver': '2.1.0',
          'notif': false,
          'seen': DateTime.now().millisecondsSinceEpoch,
        });
        _progDirty = false;
      }
      try {
        final all = await Sync.pullProgress(code);
        remote = all.where((p) => p['dev'] != dev).map((p) => {
              'dev': p['dev'], 'role': p['role'], 'plat': p['plat'], 'seen': p['seen'], 'updated': p['updated'], 'kids': p['kids'] ?? [],
              'log': p['log'] ?? [], 'act': p['act'] ?? [],
            }).toList();
        notifyListeners();
      } catch (_) {}
      await save();
    } catch (_) {
    } finally {
      syncing = false;
    }
  }
}

/// أبطال الحكاية الحاليين: من العائلة لو الجهاز مربوط، وإلا البطل المحلي
List<Kid> currentHeroes() {
  if (Family.I.linked && Family.I.kids.isNotEmpty) return Family.I.heroes;
  return [Profile.hero ?? const Kid('بطلنا', 'm')];
}

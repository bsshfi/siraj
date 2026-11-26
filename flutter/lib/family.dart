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

  int starsOf(String kidId) => log.where((e) => (e['k'] as List?)?.contains(kidId) ?? false).length;

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
    await p.setString(_k, jsonEncode({'code': code, 'dev': dev, 'rev': rev, 'fam': fam, 'devKids': devKids, 'sel': sel, 'log': log, 'progDirty': _progDirty}));
  }

  /// الربط برمز العائلة — يرجع رسالة خطأ أو null لو نجح
  Future<String?> join(String input) async {
    final c = Sync.norm(input);
    if (c.isEmpty) return 'الرمز ١٠ حروف وأرقام، مثل K7QPM-4XR2D';
    try {
      final r = await Sync.pullFamily(c);
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
    } catch (_) {
      return 'تعذّر الربط، تأكد من الإنترنت';
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
    await save();
    notifyListeners();
  }

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
          'act': <dynamic>[],
          'trips': <dynamic>[],
          'kids': devKids,
          'plat': 'android-app',
          'ver': '2.0.0',
          'notif': false,
          'seen': DateTime.now().millisecondsSinceEpoch,
        });
        _progDirty = false;
      }
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

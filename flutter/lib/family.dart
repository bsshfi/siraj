import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'sync.dart';

/// حالة سراج على هالجهاز — نفس بنية نسخة الويب (app.js → S) عشان الأجهزة تتفاهم:
/// role: 'parent' جوال وليّ الأمر، 'child' جهاز طفل، '' لسه ما اختار
class Family extends ChangeNotifier {
  static final Family I = Family._();
  Family._();

  static const _k = 'family_v1';
  static const dadOpts = ['بابا', 'يبه', 'أبوي', 'بابي'];
  static const momOpts = ['ماما', 'يمه', 'أمي', 'مامي'];

  String role = '';
  String code = '';
  String dev = '';
  int rev = 0;
  bool dirty = false;
  Map<String, dynamic> fam = freshFam();
  List<String> devKids = [];
  List<String> sel = [];
  List<Map<String, dynamic>> log = [];
  List<Map<String, dynamic>> act = [];
  List<String> fav = [];
  List<Map<String, dynamic>> remote = [];
  Set<String> passport = {};
  bool voice = true;
  Map<String, dynamic> kv = {}; // صوت كل طفل: {n, p, r}
  Map<String, dynamic>? resume; // {id, i, hist, at}
  String parentMode = 'view'; // جوال وليّ الأمر: 'view' معاينة، 'kids' أقرأ مع العيال
  String adkDay = '';
  int unlockUntil = 0;
  int forceSeen = 0;
  bool tourDone = false;
  int msgSeen = 0, msgFirstAt = 0, msgFirstShown = 0;
  bool _progDirty = false;
  bool syncing = false;
  int _beat = 0;

  /// يتنادى لما وليّ الأمر يطلب تحديث كل أجهزة العيال
  VoidCallback? onForceUpdate;

  static Map<String, dynamic> freshFam() => {
        'kids': <dynamic>[], 'pin': '', 'dad': 'بابا', 'mom': 'ماما', 'bedtime': '20:30', 'remind': true,
        'perNight': 1, 'shortKids': true, 'lockOn': true, 'lock': '21:30', 'extra': null,
      };

  bool get linked => code.isNotEmpty;
  bool get isParent => role == 'parent';
  bool get isChild => role == 'child';
  String get dad => (fam['dad'] ?? 'بابا').toString();
  String get mom => (fam['mom'] ?? 'ماما').toString();
  String get bedtime => (fam['bedtime'] ?? '20:30').toString();
  String get pin => (fam['pin'] ?? '').toString();
  int get perNight => (fam['perNight'] as num?)?.toInt() ?? 1;
  bool get shortKids => fam['shortKids'] != false;

  List<Map<String, dynamic>> get kidMaps => ((fam['kids'] as List?) ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  List<Kid> get kids => kidMaps.map(Kid.fromJson).where((k) => k.name.isNotEmpty).toList();
  Kid? kidById(String id) {
    for (final k in kids) {
      if (k.id == id) return k;
    }
    return null;
  }

  /// أطفال هالجهاز (جهاز الطفل: اللي اختارهم، وإلا الكل)
  List<Kid> get myKids {
    final all = kids;
    if (!isChild) return all;
    final mine = all.where((k) => devKids.contains(k.id)).toList();
    return mine.isEmpty ? all : mine;
  }

  /// أبطال الليلة بالترتيب (أول واحد البطل)
  List<Kid> get heroes {
    final mine = myKids;
    final picked = <Kid>[for (final id in sel) ...mine.where((k) => k.id == id).take(1)];
    return picked.isNotEmpty ? picked : mine.take(1).toList();
  }

  /// هل القراءة والألعاب تنحسب للعيال؟ (جوال وليّ الأمر في وضع المعاينة ما ينحسب)
  bool get counts => !isParent || parentMode == 'kids';

  /* ---------------- التخزين ---------------- */
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_k);
    if (raw != null) {
      try {
        final j = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        List<Map<String, dynamic>> maps(String k) => ((j[k] as List?) ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        code = (j['code'] ?? '').toString();
        dev = (j['dev'] ?? '').toString();
        rev = (j['rev'] as num?)?.toInt() ?? 0;
        fam = {...freshFam(), ...Map<String, dynamic>.from((j['fam'] as Map?) ?? {})};
        devKids = List<String>.from((j['devKids'] as List?) ?? []);
        sel = List<String>.from((j['sel'] as List?) ?? []);
        log = maps('log');
        act = maps('act');
        remote = maps('remote');
        fav = List<String>.from((j['fav'] as List?) ?? []);
        passport = Set<String>.from((j['passport'] as List?) ?? []);
        voice = j['voice'] != false;
        kv = Map<String, dynamic>.from((j['kv'] as Map?) ?? {});
        resume = j['resume'] is Map ? Map<String, dynamic>.from(j['resume'] as Map) : null;
        parentMode = (j['parentMode'] ?? 'view').toString();
        adkDay = (j['adkDay'] ?? '').toString();
        unlockUntil = (j['unlockUntil'] as num?)?.toInt() ?? 0;
        forceSeen = (j['forceSeen'] as num?)?.toInt() ?? 0;
        tourDone = j['tourDone'] == true;
        msgSeen = (j['msgSeen'] as num?)?.toInt() ?? 0;
        msgFirstAt = (j['msgFirstAt'] as num?)?.toInt() ?? 0;
        msgFirstShown = (j['msgFirstShown'] as num?)?.toInt() ?? 0;
        dirty = j['dirty'] == true;
        _progDirty = j['progDirty'] == true;
        _beat = (j['beat'] as num?)?.toInt() ?? 0;
        // النسخ السابقة من التطبيق كانت دايمًا جهاز طفل
        role = (j['role'] ?? (code.isNotEmpty ? 'child' : '')).toString();
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
    await p.setString(
        _k,
        jsonEncode({
          'role': role, 'code': code, 'dev': dev, 'rev': rev, 'dirty': dirty, 'fam': fam, 'devKids': devKids, 'sel': sel, 'log': log, 'act': act,
          'remote': remote, 'fav': fav, 'passport': passport.toList(), 'voice': voice, 'kv': kv, 'resume': resume, 'parentMode': parentMode,
          'adkDay': adkDay, 'unlockUntil': unlockUntil, 'forceSeen': forceSeen, 'tourDone': tourDone, 'msgSeen': msgSeen, 'msgFirstAt': msgFirstAt, 'msgFirstShown': msgFirstShown, 'progDirty': _progDirty, 'beat': _beat,
        }));
  }

  void _touch() {
    save();
    notifyListeners();
  }

  /// تعديل على بيانات العائلة: نحفظ ونرفع لكل الأجهزة
  void famChanged() {
    dirty = true;
    _touch();
    syncNow();
  }

  void setFam(String key, Object? value) {
    if (value == null) {
      fam.remove(key);
    } else {
      fam[key] = value;
    }
    famChanged();
  }

  /* ---------------- وليّ الأمر: إنشاء العائلة وتعديلها ---------------- */
  static String uid() {
    const a = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(8, (_) => a[r.nextInt(a.length)]).join();
  }

  Future<void> startParent() async {
    role = 'parent';
    _touch();
  }

  /// يكمّل إعداد العائلة: ينشئ رمز العائلة ويرفعها مشفّرة
  Future<void> finishSetup({required String pin, required String bedtime}) async {
    fam['pin'] = pin;
    fam['bedtime'] = bedtime;
    role = 'parent';
    if (code.isEmpty) code = Sync.newCode();
    if (sel.isEmpty && kids.isNotEmpty) sel = [kids.first.id];
    famChanged();
  }

  void saveKid(Map<String, dynamic> k) {
    final list = kidMaps;
    final i = list.indexWhere((x) => x['id'] == k['id']);
    if (i >= 0) {
      list[i] = k;
    } else {
      list.add(k);
    }
    fam['kids'] = list;
    if (sel.isEmpty) sel = [k['id'].toString()];
    linked ? famChanged() : _touch();
  }

  /// الطفل يغيّر شكله بنفسه من جهازه
  void saveKidLook(String id, Map<String, dynamic> av) {
    final list = kidMaps;
    for (final k in list) {
      if (k['id'] == id) {
        k['av'] = av;
        k['avAt'] = DateTime.now().millisecondsSinceEpoch;
      }
    }
    fam['kids'] = list;
    famChanged();
  }

  void delKid(String id) {
    fam['kids'] = kidMaps.where((k) => k['id'] != id).toList();
    sel = sel.where((x) => x != id).toList();
    famChanged();
  }

  /// شخصيات بابا وماما
  Map<String, dynamic> parentAv(String who, Map<String, dynamic> defaults) {
    final pav = (fam['pav'] as Map?) ?? {};
    if (pav[who] is Map) return Map<String, dynamic>.from(pav[who] as Map);
    final d = Map<String, dynamic>.from((defaults[who == 'dad' ? 'm' : 'f'] as Map?) ?? {});
    return who == 'dad' ? {...d, 'outfit': 'thobe', 'head': 'shmagh'} : {...d, 'head': 'hijab', 'hc': 3, 'outfit': 'dress', 'shirt': 8};
  }

  void saveParentAv(String who, Map<String, dynamic> av) {
    fam['pav'] = {...Map<String, dynamic>.from((fam['pav'] as Map?) ?? {}), who: av};
    fam['pavAt'] = {...Map<String, dynamic>.from((fam['pavAt'] as Map?) ?? {}), who: DateTime.now().millisecondsSinceEpoch};
    famChanged();
  }

  /* ---------------- ربط جهاز ---------------- */
  /// الربط برمز العائلة — role: 'child' جهاز طفل، 'parent' استرجاع العائلة. يرجع رسالة خطأ أو null
  Future<String?> join(String input, {String as = 'child'}) async {
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
      fam = {...freshFam(), ...r.$1};
      rev = r.$2;
      dirty = false;
      role = as;
      sel = [];
      final all = kids;
      devKids = as == 'child' && all.length == 1 ? [all.first.id] : [];
      try {
        final all = await Sync.pullProgress(c);
        remote = all.where((p) => p['dev'] != dev).map(_slim).toList();
        if (as == 'parent') {
          for (final p in remote) {
            for (final f in (p['fav'] as List? ?? [])) {
              if (!fav.contains(f)) fav.add(f.toString());
            }
          }
        }
      } catch (_) {}
      _progDirty = true;
      _touch();
      syncNow();
      return null;
    } catch (e) {
      return 'تعذّر الربط ($e)';
    }
  }

  Future<void> setDevKids(List<String> ids) async {
    devKids = ids;
    sel = ids.take(1).toList();
    _progDirty = true;
    _touch();
    syncNow();
  }

  Future<void> setHeroes(List<String> ids) async {
    sel = ids;
    _touch();
  }

  /// فك الربط: يمسح كل بيانات هالجهاز (بيانات العائلة تبقى في الرمز)
  Future<void> unlink() async {
    final keepDev = dev;
    role = '';
    code = '';
    fam = freshFam();
    rev = 0;
    dirty = false;
    devKids = [];
    sel = [];
    log = [];
    act = [];
    fav = [];
    remote = [];
    passport = {};
    resume = null;
    kv = {};
    dev = keepDev;
    await Profile.clearHero();
    _touch();
  }

  /* ---------------- القراءة والأنشطة ---------------- */
  static String dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _push(List<Map<String, dynamic>> list, Map<String, dynamic> e, int max) {
    list.add(e);
    if (list.length > max) list.removeRange(0, list.length - max);
  }

  /// تسجيل قراءة قصة (نفس صيغة الويب) + إشعار الوالدين
  Future<void> logStory(String storyId, List<Kid> hs) async {
    if (!counts) return;
    final ids = hs.map((k) => k.id).where((id) => id.isNotEmpty).toList();
    _push(log, {'s': storyId, 'd': dateKey(DateTime.now()), 'k': ids, 't': DateTime.now().millisecondsSinceEpoch}, 1500);
    _progDirty = true;
    _touch();
    if (linked) {
      Sync.event(code, dev, ids, storyId).catchError((_) {});
      syncNow();
    }
  }

  /// تسجيل نشاط (نفس صيغة الويب: {a, s, k, t, sc})
  Future<void> logAct(String a, {String s = '', int score = 0, List<Kid>? who}) async {
    if (a == 'adhkar') adkDay = dateKey(DateTime.now());
    if (!counts) {
      _touch();
      return;
    }
    final ids = (who ?? currentHeroes()).map((k) => k.id).where((id) => id.isNotEmpty).toList();
    _push(act, {'a': a, 's': s, 'k': ids, 't': DateTime.now().millisecondsSinceEpoch, 'sc': score}, 600);
    _progDirty = true;
    _touch();
    if (linked) syncNow();
  }

  void toggleFav(String id) {
    fav.contains(id) ? fav.remove(id) : fav.add(id);
    _progDirty = true;
    _touch();
  }

  void setResume(Map<String, dynamic>? r) {
    resume = r;
    save();
  }

  void setVoice(bool v) {
    voice = v;
    _touch();
  }

  void setKidVoice(String kidId, Map<String, dynamic> v) {
    kv = {...kv, kidId: v};
    _touch();
  }

  void setParentMode(String m) {
    parentMode = m;
    _touch();
  }

  void setUnlock(int until) {
    unlockUntil = until;
    _touch();
  }

  void markMsgShown(int at) {
    msgFirstAt = at;
    msgFirstShown = DateTime.now().millisecondsSinceEpoch;
    save();
  }

  void seeMsg(int at) {
    msgSeen = at;
    _touch();
  }

  void setTourDone() {
    tourDone = true;
    save();
  }

  Future<void> stamp(String country) async {
    passport.add(country);
    _touch();
  }

  Future<void> clearMine() async {
    log = [];
    act = [];
    _progDirty = true;
    _touch();
    syncNow();
  }

  void hideDevice(String d) {
    fam['hiddenDevs'] = {...((fam['hiddenDevs'] as List?) ?? []).map((x) => x.toString()), d}.toList();
    famChanged();
  }

  void refreshAll() {
    fam['forceAt'] = DateTime.now().millisecondsSinceEpoch;
    forceSeen = fam['forceAt'] as int;
    famChanged();
  }

  List<Map<String, dynamic>> _merge(String key) {
    final seen = <String>{}, out = <Map<String, dynamic>>[];
    void add(Map<String, dynamic> e, String d, String r) {
      final k = '${e['t']}${e['s']}${e['a'] ?? ''}';
      if (seen.add(k)) out.add({...e, 'dev': d, 'role': r});
    }

    for (final e in key == 'log' ? log : act) {
      add(e, dev, role);
    }
    for (final p in remote) {
      for (final e in (p[key] as List? ?? []).whereType<Map>()) {
        add(Map<String, dynamic>.from(e), (p['dev'] ?? '').toString(), (p['role'] ?? '').toString());
      }
    }
    out.sort((a, b) => ((b['t'] as num?) ?? 0).compareTo((a['t'] as num?) ?? 0));
    return out;
  }

  /// كل القراءات والأنشطة من كل أجهزة العائلة (الأحدث أول)
  List<Map<String, dynamic>> get allLogs => _merge('log');
  List<Map<String, dynamic>> get allActs => _merge('act');

  static bool _has(Map e, String id) => (e['k'] as List?)?.contains(id) ?? false;
  List<Map<String, dynamic>> logsOf(Kid k) => k.id.isEmpty ? log.reversed.toList() : allLogs.where((e) => _has(e, k.id)).toList();
  List<Map<String, dynamic>> actsOf(Kid k) => k.id.isEmpty ? act.reversed.toList() : allActs.where((e) => _has(e, k.id)).toList();
  int starsOf(String kidId) => allLogs.where((e) => _has(e, kidId)).length;

  /// ليالي متتالية فيها قراءة
  int streakOf(Kid k) {
    final days = logsOf(k).map((e) => e['d'].toString()).toSet();
    var d = DateTime.now();
    if (!days.contains(dateKey(d))) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(dateKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// ليالي القراءة هالشهر
  int monthNights(Kid k) {
    final mk = dateKey(DateTime.now()).substring(0, 7);
    return logsOf(k).map((e) => e['d'].toString()).where((d) => d.startsWith(mk)).toSet().length;
  }

  /// الأجهزة المربوطة (غير هالجهاز)
  List<Map<String, dynamic>> get devices {
    final hidden = ((fam['hiddenDevs'] as List?) ?? []).map((x) => x.toString()).toSet();
    final out = remote.where((p) => !hidden.contains(p['dev'])).map((p) => {...p, 'last': p['seen'] ?? p['updated'] ?? 0}).toList();
    out.sort((a, b) => ((b['last'] as num?) ?? 0).compareTo((a['last'] as num?) ?? 0));
    return out;
  }

  /* ---------------- الليل: وقت النوم، القفل، عدد قصص الليلة ---------------- */
  static int mins(String hm) {
    final p = hm.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  static const morning = 5 * 60;
  static bool inWindow(String from) {
    final d = DateTime.now(), n = d.hour * 60 + d.minute, f = mins(from);
    return f > morning ? (n >= f || n < morning) : (n >= f && n < morning);
  }

  bool get isNight => inWindow(bedtime);
  bool get isLocked {
    if (!isChild || fam['lockOn'] != true || !linked) return false;
    if (unlockUntil > DateTime.now().millisecondsSinceEpoch) return false;
    return inWindow((fam['lock'] ?? '21:30').toString());
  }

  String get nightKey {
    var d = DateTime.now();
    if (d.hour * 60 + d.minute < morning) d = d.subtract(const Duration(days: 1));
    return dateKey(d);
  }

  int get allowedTonight {
    final x = fam['extra'];
    return perNight + (x is Map && x['d'] == nightKey ? ((x['n'] as num?)?.toInt() ?? 0) : 0);
  }

  void giveExtra() {
    final x = fam['extra'];
    final n = x is Map && x['d'] == nightKey ? ((x['n'] as num?)?.toInt() ?? 0) : 0;
    fam['extra'] = {'d': nightKey, 'n': n + 1};
    famChanged();
  }

  /* ---------------- المزامنة ---------------- */
  Map<String, dynamic> _slim(Map<String, dynamic> p) => {
        'dev': p['dev'], 'role': p['role'], 'plat': p['plat'], 'ver': p['ver'], 'notif': p['notif'], 'seen': p['seen'], 'updated': p['updated'],
        'kids': p['kids'] ?? [], 'log': p['log'] ?? [], 'act': p['act'] ?? [], 'fav': p['fav'] ?? [],
      };

  /// دمج العائلة لو جهازين عدّلوا بنفس الوقت: كل شخصية تاخذ آخر تعديل لها
  Map<String, dynamic> _mergeFam(Map<String, dynamic> local, Map<String, dynamic> remoteFam) {
    final base = isParent ? jsonDecode(jsonEncode(local)) as Map<String, dynamic> : {...freshFam(), ...jsonDecode(jsonEncode(remoteFam)) as Map<String, dynamic>};
    final other = isParent ? remoteFam : local;
    final ok = ((other['kids'] as List?) ?? []).whereType<Map>().toList();
    for (final k in ((base['kids'] as List?) ?? []).whereType<Map>()) {
      for (final o in ok) {
        if (o['id'] == k['id'] && ((o['avAt'] as num?) ?? 0) > ((k['avAt'] as num?) ?? 0)) {
          k['av'] = o['av'];
          k['avAt'] = o['avAt'];
        }
      }
    }
    for (final w in ['dad', 'mom']) {
      final a = ((other['pavAt'] as Map?)?[w] as num?) ?? 0, b = ((base['pavAt'] as Map?)?[w] as num?) ?? 0;
      if (a > b) {
        base['pav'] = {...Map<String, dynamic>.from((base['pav'] as Map?) ?? {}), w: (other['pav'] as Map)[w]};
        base['pavAt'] = {...Map<String, dynamic>.from((base['pavAt'] as Map?) ?? {}), w: a};
      }
    }
    if (!isParent) {
      for (final k in ((local['kids'] as List?) ?? []).whereType<Map>()) {
        for (final b in ((base['kids'] as List?) ?? []).whereType<Map>()) {
          if (b['id'] == k['id'] && devKids.contains(k['id']) && ((k['avAt'] as num?) ?? 0) > ((b['avAt'] as num?) ?? 0)) {
            b['av'] = k['av'];
            b['avAt'] = k['avAt'];
          }
        }
      }
    }
    return base;
  }

  /// سحب تحديثات العائلة + رفع تعديلاتنا وسجل هالجهاز + سحب تقدّم الأجهزة الثانية
  Future<void> syncNow() async {
    if (!linked || syncing) return;
    syncing = true;
    notifyListeners();
    try {
      final r = await Sync.pullFamily(code);
      if (dirty) {
        if (r != null && r.$2 > rev) fam = _mergeFam(fam, r.$1);
        final nr = max(rev, r?.$2 ?? 0) + 1;
        if (await Sync.pushFamily(code, fam, nr)) {
          rev = nr;
          dirty = false;
        }
      } else if (r != null && r.$2 > rev) {
        fam = {...freshFam(), ...r.$1};
        rev = r.$2;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_progDirty || now - _beat > 6 * 3600000) {
        await Sync.pushProgress(code, dev, {
          'role': role.isEmpty ? 'child' : role,
          'log': log.length > 500 ? log.sublist(log.length - 500) : log,
          'fav': fav,
          'act': act.length > 300 ? act.sublist(act.length - 300) : act,
          'trips': <dynamic>[],
          'kids': devKids,
          'plat': 'تطبيق أندرويد',
          'ver': '2.2.0',
          'notif': false,
          'seen': now,
        });
        _progDirty = false;
        _beat = now;
      }
      try {
        final all = await Sync.pullProgress(code);
        remote = all.where((p) => p['dev'] != dev).map(_slim).toList();
      } catch (_) {}
      final fa = (fam['forceAt'] as num?)?.toInt() ?? 0;
      if (fa > forceSeen) {
        forceSeen = fa;
        onForceUpdate?.call();
      }
      await save();
    } catch (_) {
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}

/// أبطال الحكاية الحاليين: من العائلة لو الجهاز مربوط، وإلا البطل المحلي (النسخ القديمة)
List<Kid> currentHeroes() {
  if (Family.I.kids.isNotEmpty) return Family.I.heroes;
  return [Profile.hero ?? const Kid('بطلنا', 'm')];
}

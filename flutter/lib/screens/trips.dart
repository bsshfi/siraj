import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';
import 'kid_editor.dart';

/// رحلات حول العالم (trips.js): كل الرحلات تطلع من مطار الملك خالد الدولي بالرياض وترجع له
class Trips {
  static const days = ['', 'يوم واحد', 'يومين', '٣ أيام', '٤ أيام', '٥ أيام', '٦ أيام', 'أسبوع كامل'];
  static const dayN = ['', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع'];
  static const saudi = {'c': 'SA', 'n': 'السعودية', 'cap': 'الرياض', 'r': 'gcc', 'sc': 'desert'};
  static const rest = ['يوم راحة في الفندق والمسبح', 'home', '🏨'];
  static const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  static Map<String, dynamic>? byCode(String c) {
    if (c == 'SA') return saudi;
    for (final x in Learn.countries) {
      if (x['c'] == c) return x;
    }
    return null;
  }

  static String date(num t, {bool year = false}) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.toInt());
    return '${Learn.ar(d.day)} ${months[d.month - 1]}${year ? ' ${Learn.ar(d.year)}' : ''}';
  }

  static Kid kidOf(Map p) => Kid((p['n'] ?? p['name'] ?? '').toString(), p['g'] == 'f' ? 'f' : 'm', av: p['av'] is Map ? Map<String, dynamic>.from(p['av'] as Map) : null);

  /// العائلة + الشخصيات المضافة
  static List<Map<String, dynamic>> people() {
    final f = Family.I;
    return [
      if (f.kids.isNotEmpty) {'id': 'dad', 'n': f.dad, 'g': 'm', 'av': f.parentAv('dad', ArtOpts.allDefaults), 'parent': true},
      if (f.kids.isNotEmpty) {'id': 'mom', 'n': f.mom, 'g': 'f', 'av': f.parentAv('mom', ArtOpts.allDefaults), 'parent': true},
      for (final k in f.kidMaps) {'id': k['id'], 'n': k['name'], 'g': k['g'] == 'f' ? 'f' : 'm', 'av': k['av'] ?? ArtOpts.defaults(k['g'] == 'f' ? 'f' : 'm')},
      if (f.kids.isEmpty) {'id': 'me', 'n': currentHeroes().first.name, 'g': currentHeroes().first.gender, 'av': ArtOpts.defaults(currentHeroes().first.gender)},
      ...f.tripPeople,
    ];
  }

  static Map<String, dynamic> preset(String k) {
    final m = ArtOpts.defaults('m'), w = ArtOpts.defaults('f');
    return switch (k) {
      'girl' => w,
      'man' => {...m, 'outfit': 'thobe', 'head': 'shmagh'},
      'woman' => {...w, 'head': 'hijab', 'outfit': 'dress', 'shirt': 5},
      _ => m,
    };
  }

  /// أنشطة الدولة: معالمها + أكلها + أنشطة عامة
  static List<List<String>> options(Map cn) {
    final inf = Learn.info(cn['c'].toString());
    final sc = cn['sc'].toString();
    final nat = sc == 'desert'
        ? ['رحلة في الصحراء', 'desert', '🐪']
        : sc == 'sea'
            ? ['يوم على الشاطئ', 'sea', '🏖️']
            : sc == 'mountain'
                ? ['نطلع الجبال', 'mountain', '⛰️']
                : ['نتمشى في الطبيعة', 'garden', '🌳'];
    final gen = [
      ['جولة في العاصمة ${cn['cap']}', sc == 'sea' ? 'sea' : 'road', '🏙️'], nat, ['نزور المتحف الوطني', 'road', '🏛️'], ['نتسوّق من السوق الشعبي', 'souq', '🛍️'],
      ['نصلي في أكبر مساجد البلد', 'mosque', '🕌'], ['نلعب في حديقة ألعاب', 'park', '🎢'], ['نزور حديقة الحيوان', 'garden', '🦁'],
    ];
    final food = ['نجرّب ${inf?['food'] ?? 'أكل البلد'}', 'market', '🍽️'];
    final sights = ((inf?['sights'] as List?) ?? []).map((s) => (s as List).map((x) => x.toString()).toList()).toList();
    return inf != null ? [...sights, food, ...gen.sublist(1)] : [gen[0], food, ...gen.sublist(1)];
  }

  static List<Kid> heroes(List people) => people.map((p) => kidOf(p as Map)).toList();
}

/* ======================= تبويب الرحلات ======================= */
class TripsSection extends StatefulWidget {
  const TripsSection({super.key});
  @override
  State<TripsSection> createState() => _TripsSectionState();
}

class _TripsSectionState extends State<TripsSection> {
  void _game(String kind) {
    final f = Family.I, r = math.Random();
    final visited = f.allTrips.map((t) => t['c']).toSet();
    final all = Learn.countries;
    final easy = all.where((x) => Learn.info(x['c'].toString()) != null || visited.contains(x['c']) || x['r'] == 'gcc' || x['r'] == 'arab').toList()..shuffle(r);
    final hard = all.where((x) => !easy.contains(x)).toList()..shuffle(r);
    final pool = [...easy.take(7), ...hard.take(3)];
    final qs = pool.map((a) {
      final wrong = (all.where((x) => x['c'] != a['c'] && (x['r'] == a['r'] || r.nextDouble() < .3)).toList()..shuffle(r)).take(3);
      return QuizQ(
        prompt: kind == 'flag' ? 'علم أي دولة؟' : 'وش عاصمة ${a['n']}؟',
        answer: (kind == 'flag' ? a['n'] : a['cap']).toString(),
        wrong: wrong.map((x) => (kind == 'flag' ? x['n'] : x['cap']).toString()).toList(),
        big: Learn.flag(a['c'].toString()),
      );
    }).toList();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuizScreen(title: kind == 'flag' ? '🚩 لعبة الأعلام' : '🏛️ لعبة العواصم', questions: qs, onDone: (s, _) => Family.I.logAct('flags', s: 'flags-$kind', score: s))));
  }

  @override
  Widget build(BuildContext context) {
    final f = Family.I;
    final list = f.allTrips;
    final visited = {...list.map((t) => t['c'].toString()), ...f.passport};
    Widget stat(String e, String b, String s, VoidCallback onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onTap: onTap,
              child: Column(children: [
                Text(e, style: const TextStyle(fontSize: 28)),
                FittedBox(fit: BoxFit.scaleDown, child: Text(b, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                Text(s, style: const TextStyle(color: C.soft, fontSize: 12)),
              ]),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2D6AA6), Color(0xFF4FA3EC)]), borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('✈️', textAlign: TextAlign.center, style: TextStyle(fontSize: 46)),
          const Text('رحلات حول العالم', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(f.isParent ? 'هنا كل الرحلات اللي سافرها العيال مع العائلة 🌍' : 'اختر مين يسافر معك، وين تروحون، وكم يوم… ويلا! 🌍',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const Text('🛫 كل الرحلات تطلع من مطار الملك خالد الدولي بالرياض', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 12),
          BigButton(
            label: '✈️ رحلة جديدة',
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripWizard()));
              if (mounted) setState(() {});
            },
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        stat('🛂', Learn.ar(visited.length), 'جوازي · ختم', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PassportScreen()))),
        stat('🚩', 'الأعلام', 'لعبة', () => _game('flag')),
        stat('🏛️', 'العواصم', 'لعبة', () => _game('cap')),
      ]),
      const SizedBox(height: 12),
      SoftCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('🧳 ${f.isParent ? 'سجل رحلات العيال' : 'رحلاتي'}  (${Learn.ar(list.length)} رحلة)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.all(14), child: Text('ما فيه رحلات للحين… أول رحلة وين بتكون؟ 🤔', textAlign: TextAlign.center, style: TextStyle(color: C.soft)))
          else
            for (final t in list.take(40))
              () {
                final cn = Trips.byCode(t['c'].toString()) ?? {'n': t['c']};
                final ret = t['ret'] == 1 || t['ret'] == true;
                final fr = ret ? (Trips.byCode(t['from'].toString()) ?? {'n': t['from']}) : null;
                final who = ((t['k'] as List?) ?? []).map((id) => f.kidById(id.toString())?.name).whereType<String>().toList();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumScreen(trip: t))),
                  leading: Text(Learn.flag(t['c'].toString()), style: const TextStyle(fontSize: 32)),
                  title: Text(ret ? 'العودة للسعودية 💚' : cn['n'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      '${ret ? 'من ${fr!['n']} ${Learn.flag(t['from'].toString())}' : Trips.days[((t['days'] as num?) ?? 0).toInt().clamp(0, 7)]} · ${Trips.date((t['at'] as num?) ?? 0)}${who.isNotEmpty && f.isParent ? ' · رحلة ${who.join(' و')}' : ''}'),
                  trailing: SizedBox(
                    width: 70,
                    height: 40,
                    child: Stack(children: [
                      for (var i = 0; i < math.min(3, ((t['people'] as List?) ?? []).length); i++)
                        Positioned(left: i * 18.0, child: KidFace(kid: Trips.kidOf((t['people'] as List)[i] as Map), size: 32)),
                    ]),
                  ),
                );
              }(),
        ]),
      ),
    ]);
  }
}

/* ======================= معالج الرحلة ======================= */
class TripWizard extends StatefulWidget {
  const TripWizard({super.key});
  @override
  State<TripWizard> createState() => _TripWizardState();
}

class _TripWizardState extends State<TripWizard> {
  // mode → 0 people → 1 place → 2 days → 3 airport → 4 arrive → 5 day → 6 home → 7 welcome
  int step = -1, nDays = 3, d = 0;
  bool ret = false, flying = false, postcard = false;
  String? c;
  final sel = <String>{};
  final picks = <List<String>>[];
  List<List<String>> ops = [];
  String region = 'all', q = '', say = '';
  Map<String, dynamic>? saved;
  bool first = false;

  @override
  void initState() {
    super.initState();
    if (Family.I.isChild) sel.addAll(Family.I.myKids.map((k) => k.id));
  }

  List<Map<String, dynamic>> get travelers => Trips.people().where((p) => sel.contains(p['id'])).toList();
  List<Kid> get hs => Trips.heroes(travelers);
  Map<String, dynamic> get cn => Trips.byCode(c ?? 'SA')!;

  void go(int n) => setState(() {
        step = n;
        postcard = false;
        if (n == 5) _prepDay();
      });

  void _prepDay() {
    final used = picks.map((p) => p[0]).toSet();
    var o = Trips.options(cn).where((x) => !used.contains(x[0])).toList();
    if (o.isEmpty) o = Trips.options(cn);
    ops = [...o.take(6), Trips.rest];
  }

  Future<void> _fly() async {
    setState(() => flying = true);
    final says = ret ? ['الطيارة طارت فوق ${cn['cap']} 🌆', 'فوق الغيوم ☁️☁️', 'بانت أنوار الرياض! 👀'] : ['الطيارة طارت فوق الرياض 🌆', 'فوق الغيوم ☁️☁️', 'شوي ونوصل… 👀'];
    for (final s in says) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => say = s);
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    flying = false;
    if (ret) {
      _save();
      go(7);
    } else {
      d = 1;
      go(4);
    }
  }

  void _save() {
    final f = Family.I;
    final kidsIn = travelers.where((p) => p['parent'] != true && !p['id'].toString().startsWith('x')).map((p) => p['id']).toList();
    final k = f.isChild ? f.myKids.map((x) => x.id).toList() : kidsIn;
    first = !f.allTrips.any((t) => t['c'] == (ret ? 'SA' : c));
    final t = <String, dynamic>{
      'id': 't${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      'c': ret ? 'SA' : c,
      if (ret) 'from': c,
      if (ret) 'ret': 1,
      'days': ret ? 0 : picks.length,
      'at': DateTime.now().millisecondsSinceEpoch,
      'k': k,
      'people': travelers.map((p) => {'n': p['n'], 'g': p['g'], 'av': p['av']}).toList(),
      'picks': picks,
    };
    saved = t;
    f.addTrip(t);
    f.logAct('trip', s: 'trip-${t['c']}', who: f.kids.where((x) => k.contains(x.id)).toList());
    HapticFeedback.mediumImpact();
  }

  Widget _dots() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: i <= math.min(step, 3) ? Colors.white : Colors.white38),
            child: Text(['👨‍👩‍👧‍👦', '🌍', '🗓️', '🛫'][i], style: const TextStyle(fontSize: 18)),
          ),
      ]);

  Widget _h(String t, [String? s]) => Column(children: [
        Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
        if (s != null) Text(s, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34406E), fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
      ]);

  Widget _pass({bool back = false}) {
    final inf = Learn.info(c!);
    final tr = travelers;
    final fromC = back ? Learn.flag(c!) : 'RUH', fromN = back ? '${cn['cap']}، ${cn['n']}' : 'الرياض 🇸🇦';
    final toC = back ? 'RUH' : Learn.flag(c!), toN = back ? 'الرياض 🇸🇦' : '${cn['cap']}، ${cn['n']}';
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x2250628A), blurRadius: 16)]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(color: Color(0xFF2D6AA6), borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
          child: const Row(children: [
            Text('✈️ سراج للطيران', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            Spacer(),
            Text('بطاقة صعود', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(children: [const Text('من', style: TextStyle(color: C.soft)), Text(fromC, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), Text(fromN, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5))])),
              const Text('- - ✈️ - -', style: TextStyle(color: C.soft)),
              Expanded(child: Column(children: [const Text('إلى', style: TextStyle(color: C.soft)), Text(toC, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), Text(toN, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5))])),
            ]),
            const Divider(height: 22),
            Wrap(spacing: 10, runSpacing: 6, alignment: WrapAlignment.center, children: [
              if (!back) Text('🗓️ ${Trips.days[nDays]}', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (inf?['h'] != null) Text('⏱️ ${Learn.ar(inf!['h']).replaceAll('.', '٫')} ساعة طيران تقريبًا', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('👥 ${Learn.ar(tr.length)} ${tr.length == 1 ? 'مسافر' : 'مسافرين'}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final p in tr) Column(children: [KidFace(kid: Trips.kidOf(p), size: 40), Text(p['n'].toString(), style: const TextStyle(fontSize: 12))]),
            ]),
          ]),
        ),
      ]),
    );
  }

  Future<void> _addPerson() async {
    final name = TextEditingController();
    var type = 'boy';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('➕ شخصية جديدة', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const Text('جدّو، تيتة، خالو، صديق…', textAlign: TextAlign.center, style: TextStyle(color: C.soft)),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              maxLength: 16,
              decoration: InputDecoration(counterText: '', hintText: 'الاسم', filled: true, fillColor: const Color(0xFFF4F7FC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              for (final t in [('boy', 'ولد'), ('girl', 'بنت'), ('man', 'رجل'), ('woman', 'امرأة')])
                Expanded(
                  child: GestureDetector(
                    onTap: () => ss(() => type = t.$1),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: type == t.$1 ? C.orange : const Color(0xFFE6EAF2), width: 2)),
                      child: Column(children: [
                        SizedBox(height: 70, child: KidAvatar(kid: Kid(t.$2, RegExp('girl|woman').hasMatch(t.$1) ? 'f' : 'm', av: Trips.preset(t.$1)))),
                        Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            BigButton(
              label: 'أضفها ✓',
              onTap: () {
                final n = name.text.trim();
                if (n.isEmpty) return;
                final p = {'id': 'x${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}', 'n': n, 'g': RegExp('girl|woman').hasMatch(type) ? 'f' : 'm', 'av': Trips.preset(type)};
                Family.I.saveTripPeople([...Family.I.tripPeople, p]);
                sel.add(p['id'].toString());
                Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _body() {
    switch (step) {
      case -1:
        Widget m(String e, String t, String s, bool r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                padding: const EdgeInsets.all(18),
                onTap: () {
                  ret = r;
                  go(0);
                },
                child: Row(children: [
                  Text(e, style: const TextStyle(fontSize: 42)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(s, style: const TextStyle(color: C.soft))])),
                ]),
              ),
            );
        return Column(children: [
          _h('وش نوع الرحلة؟ ✈️', 'اختر وحدة'),
          m('🛫', 'رحلة من الرياض', 'نسافر لأي دولة في العالم 🌍', false),
          m('🇸🇦', 'راجعين للسعودية', 'كنا مسافرين برّا… ونرجع لبلدنا 💚', true),
        ]);
      case 0:
        final ps = Trips.people();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _dots(),
          const SizedBox(height: 10),
          _h('مين بيسافر؟ 🧳', 'اختر المسافرين (تقدر تضيف شخصيات)'),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            for (final p in ps)
              GestureDetector(
                onTap: () => setState(() => sel.contains(p['id']) ? sel.remove(p['id']) : sel.add(p['id'].toString())),
                child: Container(
                  width: 92,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: sel.contains(p['id']) ? const Color(0xFFFFF1E2) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel.contains(p['id']) ? C.orange : Colors.white, width: 2.5),
                  ),
                  child: Stack(children: [
                    Column(children: [
                      SizedBox(height: 86, child: KidAvatar(kid: Trips.kidOf(p))),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(p['n'].toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                    ]),
                    if (p['id'].toString().startsWith('x'))
                      Positioned(
                        top: 0,
                        left: 0,
                        child: GestureDetector(
                          onTap: () {
                            Family.I.saveTripPeople(Family.I.tripPeople.where((x) => x['id'] != p['id']).toList());
                            setState(() => sel.remove(p['id']));
                          },
                          child: const Text('✕', style: TextStyle(color: Color(0xFFD33A3A), fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ]),
                ),
              ),
            GestureDetector(
              onTap: _addPerson,
              child: Container(
                width: 92,
                height: 118,
                decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('➕', style: TextStyle(fontSize: 30)), Text('شخصية', style: TextStyle(fontWeight: FontWeight.w800))]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Opacity(opacity: sel.isEmpty ? .5 : 1, child: BigButton(label: 'التالي: وين نروح؟ 🌍', onTap: () {
            if (sel.isNotEmpty) go(1);
          })),
        ]);
      case 1:
        final qq = q.trim();
        final list = Learn.countries.where((x) => (region == 'all' || x['r'] == region) && (qq.isEmpty || x['n'].toString().contains(qq) || x['cap'].toString().contains(qq))).toList()
          ..sort((a, b) => (Learn.info(b['c'].toString()) != null ? 1 : 0) - (Learn.info(a['c'].toString()) != null ? 1 : 0));
        final regs = Learn.regions;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _dots(),
          const SizedBox(height: 10),
          _h(ret ? 'من وين راجعين؟ 🌍' : 'وين نروح؟ 🌍'),
          TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: '🔍 دوّر على دولة…',
              hintStyle: const TextStyle(color: Color(0xFFB3BBCB)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          Pills(items: regs.map((r) => r[1]).toList(), index: math.max(0, regs.indexWhere((r) => r[0] == region)), onTap: (i) => setState(() => region = regs[i][0])),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .95,
            children: [
              for (final x in list)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      c = x['c'].toString();
                      go(2);
                    },
                    child: Stack(children: [
                      Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(Learn.flag(x['c'].toString()), style: const TextStyle(fontSize: 36)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(x['n'].toString(), textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))),
                        ]),
                      ),
                      if (Learn.info(x['c'].toString()) != null) const Positioned(top: 4, left: 6, child: Text('⭐', style: TextStyle(fontSize: 12))),
                    ]),
                  ),
                ),
            ],
          ),
          if (list.isEmpty) const Text('ما لقيت شي 🤔', textAlign: TextAlign.center),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _dots(),
          const SizedBox(height: 10),
          if (ret) _h('بطاقة العودة 🇸🇦', 'راجعين لبلدنا 💚') else _h('كم يوم؟ 🗓️'),
          if (!ret)
            Row(children: [
              for (var n = 1; n <= 7; n++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => nDays = n),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: nDays == n ? C.orange : Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Text(Learn.ar(n), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: nDays == n ? Colors.white : C.ink)),
                    ),
                  ),
                ),
            ]),
          const SizedBox(height: 12),
          _pass(back: ret),
          const SizedBox(height: 14),
          BigButton(label: 'للمطار 🛫', onTap: () => go(3)),
          TextButton(onPressed: () => go(1), child: const Text('غيّر الدولة', style: TextStyle(fontWeight: FontWeight.w800))),
        ]);
      case 3:
        final no = Learn.ar(100 + (ret ? (c!.codeUnitAt(1) * 7 + c!.codeUnitAt(0)) : (c!.codeUnitAt(0) * 7 + c!.codeUnitAt(1))) % 900);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _h(ret ? '🛫 مطار ${cn['cap']}' : '🛫 مطار الملك خالد الدولي', ret ? '${cn['n']} · رحلة رقم SJ$no إلى الرياض' : 'الرياض · رحلة رقم SJ$no إلى ${cn['n']}'),
          SceneArt(scene: 'road', prop: '🛫', heroes: hs, radius: 22),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (_, box) {
            return SizedBox(
              height: 70,
              child: Stack(children: [
                Positioned(left: 0, right: 0, top: 30, child: Container(height: 3, color: Colors.white70)),
                Positioned(right: 0, top: 6, child: Column(children: [Text(ret ? Learn.flag(c!) : '🇸🇦', style: const TextStyle(fontSize: 26)), Text(ret ? cn['cap'].toString() : 'الرياض', style: const TextStyle(fontSize: 12))])),
                Positioned(left: 0, top: 6, child: Column(children: [Text(ret ? '🇸🇦' : Learn.flag(c!), style: const TextStyle(fontSize: 26)), Text(ret ? 'الرياض' : cn['cap'].toString(), style: const TextStyle(fontSize: 12))])),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 3400),
                  curve: Curves.easeInOut,
                  right: flying ? box.maxWidth - 80 : 40,
                  top: flying ? 0 : 14,
                  child: Transform.flip(flipX: true, child: const Text('✈️', style: TextStyle(fontSize: 30))),
                ),
              ]),
            );
          }),
          const SizedBox(height: 10),
          Text(say.isEmpty ? (ret ? 'اربطوا الأحزمة… راجعين لبلدنا 💚' : 'اربطوا الأحزمة… ونقول دعاء السفر 🤲') : say,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
          const SizedBox(height: 14),
          Opacity(opacity: flying ? .5 : 1, child: BigButton(label: 'انطلق ✈️', onTap: () {
            if (!flying) _fly();
          })),
        ]);
      case 4:
        final inf = Learn.info(c!);
        Widget fact(String e, String l, String v) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [Text(e, style: const TextStyle(fontSize: 24)), Text(l, style: const TextStyle(color: C.soft, fontSize: 12)), Text(v, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))]),
            );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(Learn.flag(c!), textAlign: TextAlign.center, style: const TextStyle(fontSize: 80)),
          _h('وصلنا ${cn['n']}! 🎉', inf != null ? 'يقولون هنا: ${inf['hi']}' : null),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              fact('🏛️', 'العاصمة', cn['cap'].toString()),
              if (inf != null) ...[fact('🗣️', 'اللغة', inf['lang'].toString()), fact('💰', 'العملة', inf['cur'].toString()), fact('🍽️', 'أكلة مشهورة', inf['food'].toString())]
              else fact('🌍', 'القارة', Learn.regions.firstWhere((r) => r[0] == cn['r'], orElse: () => ['', '']).elementAt(1)),
            ],
          ),
          if (inf?['fact'] != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF6D6), borderRadius: BorderRadius.circular(16)),
              child: Text('💡 هل تعرف؟ ${inf!['fact']}', style: const TextStyle(fontWeight: FontWeight.w600, height: 1.6)),
            ),
          const SizedBox(height: 14),
          BigButton(label: 'نبدأ اليوم ${Trips.dayN[1]} ☀️', onTap: () => go(5)),
        ]);
      case 5:
        if (postcard) {
          final o = picks.last, last = d >= nDays;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Stack(children: [
              SceneArt(scene: o[1], prop: o[2], heroes: hs, radius: 22),
              Positioned(top: 8, left: 10, child: Transform.rotate(angle: -.2, child: Text(Learn.flag(c!), style: const TextStyle(fontSize: 34)))),
            ]),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Text('اليوم ${Trips.dayN[d]}: ${o[0]} ${o[2]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text('${travelers.map((p) => p['n']).join(' و')} · ${cn['n']}', style: const TextStyle(color: C.soft)),
              ]),
            ),
            const SizedBox(height: 14),
            BigButton(
              label: last ? 'نرجع الرياض 🛬🇸🇦' : 'اليوم ${Trips.dayN[d + 1]} ☀️',
              onTap: () {
                if (last) {
                  _save();
                  go(6);
                } else {
                  d++;
                  go(5);
                }
              },
            ),
            if (!last)
              TextButton(
                onPressed: () {
                  nDays = picks.length;
                  _save();
                  go(6);
                },
                child: const Text('🛬 نرجع الرياض الحين', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _h('☀️ اليوم ${Trips.dayN[d]} في ${cn['n']}', 'وش نسوي اليوم؟ (باقي ${Learn.ar(nDays - d + 1)} ${nDays - d + 1 == 1 ? 'يوم' : 'أيام'})'),
          for (final o in ops)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                padding: const EdgeInsets.all(14),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    picks.add(o);
                    postcard = true;
                  });
                },
                child: Row(children: [Text(o[2], style: const TextStyle(fontSize: 30)), const SizedBox(width: 12), Expanded(child: Text(o[0], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))]),
              ),
            ),
          if (d > 1)
            TextButton(
              onPressed: () {
                nDays = picks.length;
                _save();
                go(6);
              },
              child: const Text('🛬 نرجع الرياض الحين', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
        ]);
      case 6:
      case 7:
        final home = step == 6;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!home) const Text('🇸🇦', textAlign: TextAlign.center, style: TextStyle(fontSize: 70)),
          SceneArt(scene: home ? 'road' : 'desert', prop: home ? '🛬' : '🇸🇦', heroes: hs, radius: 22),
          const SizedBox(height: 12),
          _h(home ? 'الحمد لله على السلامة 🇸🇦' : 'أهلًا بكم في بلدكم 💚', home ? 'رجعنا الرياض من ${cn['n']} ${Learn.flag(c!)}' : 'الحمد لله على السلامة، رجعنا من ${cn['n']} ${Learn.flag(c!)}'),
          Center(
            child: Transform.rotate(
              angle: -.08,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: home ? const Color(0xFFD33A3A) : const Color(0xFF1E8E4A), width: 3), borderRadius: BorderRadius.circular(14), color: Colors.white),
                child: Column(children: [
                  Text(home ? Learn.flag(c!) : '🇸🇦', style: const TextStyle(fontSize: 34)),
                  Text(home ? cn['n'].toString() : 'السعودية', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(Trips.date(DateTime.now().millisecondsSinceEpoch, year: true), style: const TextStyle(fontSize: 12, color: C.soft)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('${first ? (home ? 'ختم جديد في جوازك! 📕' : 'ختم السعودية دخل جوازك! 📕') : 'ختم جديد في جوازك 📕'} وانحفظت الرحلة في سجل الرحلات 🧳', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34406E))),
          const SizedBox(height: 14),
          if (home && saved != null)
            BigButton(label: '📸 ألبوم الرحلة', onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AlbumScreen(trip: saved!)))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام 💚', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        ]);
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4FA3EC), C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: ListView(padding: EdgeInsets.fromLTRB(16, top + 8, 16, bottom + 30), children: [
          Row(children: [
            IconButton.filledTonal(
              onPressed: () {
                if (step <= -1 || step >= 6 || step == 4 || step == 5) {
                  Navigator.pop(context);
                } else {
                  go(step - 1);
                }
              },
              icon: Icon(step <= -1 || step >= 4 ? Icons.close_rounded : Icons.arrow_back_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.white70),
            ),
            const SizedBox(width: 10),
            const Text('✈️ رحلة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
          const SizedBox(height: 12),
          AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: KeyedSubtree(key: ValueKey('$step$postcard$d'), child: _body())),
        ]),
      ),
    );
  }
}

/* ======================= الألبوم والجواز ======================= */
class AlbumScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  const AlbumScreen({super.key, required this.trip});
  @override
  Widget build(BuildContext context) {
    final t = trip, top = MediaQuery.of(context).padding.top;
    final ret = t['ret'] == 1 || t['ret'] == true;
    final cn = Trips.byCode(t['c'].toString()) ?? {'n': t['c']};
    final ppl = (t['people'] as List?) ?? [];
    final hs = Trips.heroes(ppl);
    final picks = ((t['picks'] as List?) ?? []).map((p) => (p as List).map((x) => x.toString()).toList()).toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: ListView(padding: EdgeInsets.fromLTRB(16, top + 8, 16, 30), children: [
          Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
            const SizedBox(width: 10),
            Expanded(child: Text(ret ? '🇸🇦 العودة للسعودية' : '${Learn.flag(t['c'].toString())} رحلة ${cn['n']}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF26305A)))),
          ]),
          Text('${ret ? 'من ${(Trips.byCode(t['from'].toString()) ?? {'n': t['from']})['n']} ${Learn.flag(t['from'].toString())}' : Trips.days[((t['days'] as num?) ?? 0).toInt().clamp(0, 7)]} · ${Trips.date((t['at'] as num?) ?? 0, year: true)}',
              textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34406E), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final p in ppl) Column(children: [KidFace(kid: Trips.kidOf(p as Map), size: 44), Text(p['n'].toString(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))]),
          ]),
          const SizedBox(height: 12),
          if (ret)
            _card(SceneArt(scene: 'desert', prop: '🇸🇦', heroes: hs, radius: 18), 'أهلًا بكم في بلدكم 💚', '🇸🇦')
          else
            for (var i = 0; i < picks.length; i++) _card(SceneArt(scene: picks[i][1], prop: picks[i][2], heroes: hs, radius: 18), 'اليوم ${i + 1 < Trips.dayN.length ? Trips.dayN[i + 1] : Learn.ar(i + 1)}: ${picks[i][0]} ${picks[i][2]}', null),
        ]),
      ),
    );
  }

  Widget _card(Widget art, String t, String? stamp) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Stack(children: [art, if (stamp != null) Positioned(top: 6, left: 8, child: Text(stamp, style: const TextStyle(fontSize: 30)))]),
            Padding(padding: const EdgeInsets.all(8), child: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
          ]),
        ),
      );
}

class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final map = <String, (int, num)>{};
    for (final t in Family.I.allTrips) {
      final c = t['c'].toString(), at = (t['at'] as num?) ?? 0;
      final o = map[c];
      map[c] = o == null ? (1, at) : (o.$1 + 1, math.min(o.$2, at));
    }
    for (final c in Family.I.passport) {
      map.putIfAbsent(c, () => (1, 0));
    }
    final codes = map.keys.toList()..sort((a, b) => map[a]!.$2.compareTo(map[b]!.$2));
    final total = Learn.countries.length + 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0E5A34), Color(0xFF167A47), C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .3, .7])),
        child: ListView(padding: EdgeInsets.fromLTRB(18, top + 10, 18, 30), children: [
          Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
            const SizedBox(width: 10),
            const Text('🇸🇦 جواز سفر سراج', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
          const SizedBox(height: 8),
          Text('زرت ${Learn.ar(codes.length)} من ${Learn.ar(total)} دولة', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: math.max(.02, codes.length / total), minHeight: 10, color: const Color(0xFFFFD23F), backgroundColor: Colors.white24)),
          const SizedBox(height: 16),
          if (codes.isEmpty)
            const SoftCard(padding: EdgeInsets.all(26), child: Text('الجواز فاضي… سافر وخذ أول ختم ✈️', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (var i = 0; i < codes.length; i++)
                  Transform.rotate(
                    angle: (((i * 37) % 24) - 12) * math.pi / 180,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD33A3A).withValues(alpha: .6), width: 2.5)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(Learn.flag(codes[i]), style: const TextStyle(fontSize: 34)),
                        FittedBox(fit: BoxFit.scaleDown, child: Text((Trips.byCode(codes[i]) ?? {'n': codes[i]})['n'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                        Text(map[codes[i]]!.$1 > 1 ? '×${Learn.ar(map[codes[i]]!.$1)}' : (map[codes[i]]!.$2 > 0 ? Trips.date(map[codes[i]]!.$2) : ''), style: const TextStyle(fontSize: 11, color: C.soft)),
                      ]),
                    ),
                  ),
              ],
            ),
        ]),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets/common.dart';
import '../widgets/stk.dart';

/// الإنجليزي كامل (english.js + english-2.js + english-3.js):
/// حروف (٣-٥)، كلمات (٦-٨)، جمل (٦-٩)، متقدّم (٩-١٢): قراءة، نطق، مفردات، قواعد، محادثات، إملاء
class En {
  static Map<String, dynamic> get adv => Map<String, dynamic>.from((Learn.d['adv'] as Map?) ?? {});
  static List<Map<String, dynamic>> get read => ((adv['READ'] as List?) ?? []).map((x) => Map<String, dynamic>.from(x as Map)).toList();
  static Map<String, List<List<String>>> get vocab =>
      ((adv['VOCAB'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), (v as List).map((r) => (r as List).map((x) => x.toString()).toList()).toList()));
  static List<Map<String, dynamic>> get gram => ((adv['GRAM'] as List?) ?? []).map((x) => Map<String, dynamic>.from(x as Map)).toList();
  static List<Map<String, dynamic>> get dlg => ((adv['DLG'] as List?) ?? []).map((x) => Map<String, dynamic>.from(x as Map)).toList();
  static Map<String, String> get snd => ((Learn.d['snd'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), v.toString()));
  static Map<String, List<String>> get ex => ((Learn.d['ex'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), (v as List).map((x) => x.toString()).toList()));
  static Map<String, List<List<String>>> get fam =>
      ((Learn.d['fam'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), (v as List).map((r) => (r as List).map((x) => x.toString()).toList()).toList()));

  static String get name => currentHeroes().isNotEmpty ? currentHeroes().first.name : 'Sara';
  static String nm(String s) => s.replaceAll('{n}', name);
  static void say(String t, {double rate = .42}) => Voice.stop().then((_) => Voice.speak(t, rate, en: true));
  static List<T> shuf<T>(Iterable<T> a) => a.toList()..shuffle(math.Random());
  static List<String> sents(String t) => RegExp(r'[^.!?]+[.!?]+["”]?').allMatches(t).map((m) => m[0]!.trim()).toList().ifEmpty(t);
  static void log(String id, int score) => Family.I.logAct('en', s: id, score: score);
}

extension _E on List<String> {
  List<String> ifEmpty(String t) => isEmpty ? [t] : this;
}

void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

/// صفحة فرعية بخلفية سماء وعنوان
class EnPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const EnPage({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: SkyBg.gradient),
        child: ListView(padding: EdgeInsets.fromLTRB(16, top + 8, 16, bottom + 30), children: [
          Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF26305A)))),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }
}

Widget _btn(String t, VoidCallback onTap, {bool alt = false}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: alt
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            )
          : BigButton(label: t, onTap: onTap),
    );

Widget _row2(Widget a, Widget b) => Row(children: [Expanded(child: a), const SizedBox(width: 8), Expanded(child: b)]);

Widget _tile(Widget child, VoidCallback onTap, {Color? color}) => Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: child),
    );

TextStyle _en(double s, {FontWeight w = FontWeight.w800, Color? c}) => TextStyle(fontSize: s, fontWeight: w, fontFamily: 'sans-serif', color: c);

/// بطاقة كبيرة تنفتح لما يضغط حرف/كلمة/جملة
void _show(BuildContext context, List<Widget> body, {VoidCallback? again}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ...body,
            if (again != null) _btn('🔊 اسمع مرة ثانية', again, alt: true),
          ]),
        ),
      ),
    ),
  ).whenComplete(Voice.stop);
}

/* ======================= الشاشة الرئيسية للإنجليزي ======================= */
class EnglishSection extends StatefulWidget {
  const EnglishSection({super.key});
  @override
  State<EnglishSection> createState() => _EnglishSectionState();
}

class _EnglishSectionState extends State<EnglishSection> {
  static String? _level;
  static String _cat = '', _sub = 'read', _vcat = '';

  String _defLevel() {
    final k = currentHeroes().isNotEmpty ? currentHeroes().first : null;
    if (k == null || k.age == 0) return 'words';
    return k.age >= 3 ? 'adv' : k.age == 2 ? 'words' : 'letters';
  }

  @override
  Widget build(BuildContext context) {
    if (Family.I.isNight) {
      return const SoftCard(
        padding: EdgeInsets.all(22),
        child: Column(children: [
          Text('😴', style: TextStyle(fontSize: 60)),
          Text('Good night!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          Text('الإنجليزي نام، ويرجع الصبح ☀️', style: TextStyle(color: C.soft, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    _level ??= _defLevel();
    const lv = [('letters', '🔤', 'حروف', '٣-٥'), ('words', '🧩', 'كلمات', '٦-٨'), ('sent', '💬', 'جمل', '٦-٩'), ('adv', '🚀', 'متقدّم', '٩-١٢')];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        for (final l in lv)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _level = l.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: _level == l.$1 ? C.orange : Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  Text(l.$2, style: const TextStyle(fontSize: 22)),
                  Text(l.$3, style: TextStyle(fontWeight: FontWeight.w800, color: _level == l.$1 ? Colors.white : C.ink)),
                  Text(l.$4, style: TextStyle(fontSize: 11.5, color: _level == l.$1 ? Colors.white70 : C.soft)),
                ]),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      if (_level != 'letters') ...[_weekly(context), const SizedBox(height: 12)],
      if (_level == 'letters') _letters(context),
      if (_level == 'words') _words(context),
      if (_level == 'sent') _sent(context),
      if (_level == 'adv') _adv(context),
    ]);
  }

  Widget _weekly(BuildContext context) {
    final r = En.read;
    if (r.isEmpty) return const SizedBox();
    final i = ((DateTime.now().millisecondsSinceEpoch / 864e5 + 4) / 7).floor() % r.length;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _push(context, ReadingScreen(i: i)),
      child: Row(children: [
        Text(r[i]['e'].toString(), style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🌙 قصة الأسبوع بالإنجليزي', style: TextStyle(fontSize: 12.5, color: C.purple, fontWeight: FontWeight.w800)),
            Text(r[i]['t'].toString(), textDirection: TextDirection.ltr, style: _en(17)),
            Text('اقرأها مع ${Family.I.dad} قبل النوم، ومعها الترجمة', style: const TextStyle(fontSize: 12.5, color: C.soft)),
          ]),
        ),
      ]),
    );
  }

  Widget _letters(BuildContext context) {
    final l = Learn.letters;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('حروف الإنجليزي 🔤', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const Text('اضغط الحرف واسمعه', style: TextStyle(color: C.soft)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: .95,
          children: [
            for (final r in l)
              _tile(
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${r[0]}${r[0].toLowerCase()}', style: _en(22, c: C.orange)),
                  Text(r[3], style: const TextStyle(fontSize: 24)),
                ]),
                () {
                  En.say('${r[0]}. ${r[1]}');
                  _show(context, [
                    Text('${r[0]} ${r[0].toLowerCase()}', textAlign: TextAlign.center, style: _en(56, c: C.orange)),
                    Text(r[3], textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
                    Text(r[1], textAlign: TextAlign.center, style: _en(26)),
                    Text(r[2], textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontSize: 17)),
                  ], again: () => En.say('${r[0]}. ${r[1]}'));
                },
                color: const Color(0xFFF7F9FD),
              ),
          ],
        ),
        _btn('🎯 لعبة: وين الحرف؟', () => _push(context, EnGame.letters())),
        _row2(_btn('🗣️ أصوات الحروف', () => _push(context, const PhonicsScreen()), alt: true), _btn('✍️ تتبّع الحرف', () => _push(context, const TraceScreen()), alt: true)),
      ]),
    );
  }

  Widget _words(BuildContext context) {
    final w = Learn.words;
    if (w.isEmpty) return const SizedBox();
    if (!w.containsKey(_cat)) _cat = w.keys.first;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('كلمات إنجليزي 🧩', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Pills(items: w.keys.toList(), index: w.keys.toList().indexOf(_cat), onTap: (i) => setState(() => _cat = w.keys.elementAt(i))),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: .95,
          children: [
            for (final r in w[_cat]!)
              _tile(
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(r[2], style: const TextStyle(fontSize: 32)),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(r[0], style: _en(16))),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(r[1], style: const TextStyle(fontSize: 12.5, color: C.soft))),
                ]),
                () {
                  En.say(r[0]);
                  _show(context, [
                    Text(r[2], textAlign: TextAlign.center, style: const TextStyle(fontSize: 70)),
                    Text(r[0], textAlign: TextAlign.center, style: _en(30)),
                    Text(r[1], textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontSize: 18)),
                  ], again: () => En.say(r[0]));
                },
                color: const Color(0xFFF7F9FD),
              ),
          ],
        ),
        _btn('🎧 لعبة: اسمع واختار', () => _push(context, EnGame.words(_cat))),
        _row2(_btn('👪 عائلات الكلمات', () => _push(context, const FamiliesScreen()), alt: true), _btn('👀 كلمات سريعة', () => _push(context, const SightScreen()), alt: true)),
        _row2(_btn('✍️ تتبّع الحرف', () => _push(context, const TraceScreen()), alt: true), _btn('🗣️ أصوات الحروف', () => _push(context, const PhonicsScreen()), alt: true)),
      ]),
    );
  }

  Widget _sent(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('جمل إنجليزي 💬', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const Text('اضغط الجملة واسمعها', style: TextStyle(color: C.soft)),
        const SizedBox(height: 8),
        for (final r in Learn.sentences)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _tile(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Text(r[2], style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Directionality(textDirection: TextDirection.ltr, child: Text(En.nm(r[0]), style: _en(16.5))),
                      Text(En.nm(r[1]), style: const TextStyle(color: C.soft, fontSize: 13.5)),
                    ]),
                  ),
                ]),
              ),
              () {
                En.say(En.nm(r[0]));
                _show(context, [
                  Text(r[2], textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
                  Text(En.nm(r[0]), textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: _en(24)),
                  Text(En.nm(r[1]), textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontSize: 17)),
                ], again: () => En.say(En.nm(r[0])));
              },
              color: const Color(0xFFF7F9FD),
            ),
          ),
        _row2(_btn('❓ وش معناها؟', () => _push(context, EnGame.mean())), _btn('🧱 رتّب الجملة', () => _push(context, EnGame.build()), alt: true)),
      ]),
    );
  }

  Widget _adv(BuildContext context) {
    const subs = [('read', '📖 قراءة'), ('speak', '🎤 نطق'), ('vocab', '🧠 مفردات'), ('gram', '📐 قواعد'), ('dlg', '💬 محادثات'), ('spell', '🎧 إملاء')];
    final v = En.vocab;
    if (v.isNotEmpty && !v.containsKey(_vcat)) _vcat = v.keys.first;
    const lvS = ['', '⭐', '⭐⭐', '⭐⭐⭐'];
    Widget body;
    switch (_sub) {
      case 'read':
        body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('اقرأ القصة، اضغط أي جملة واسمعها، وبعدين جاوب الأسئلة', style: TextStyle(color: C.soft)),
          const SizedBox(height: 8),
          for (var i = 0; i < En.read.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tile(
                ListTile(
                  leading: Text(En.read[i]['e'].toString(), style: const TextStyle(fontSize: 30)),
                  title: Text(En.read[i]['t'].toString(), textDirection: TextDirection.ltr, style: _en(16)),
                  subtitle: Text('${lvS[(En.read[i]['lv'] as num?)?.toInt() ?? 1]} · ${Learn.ar(En.read[i]['en'].toString().split(' ').length)} كلمة'),
                ),
                () => _push(context, ReadingScreen(i: i)),
                color: const Color(0xFFF7F9FD),
              ),
            ),
        ]);
      case 'speak':
        final pool = En.vocab.values.expand((e) => e).map((w) => w[3]).where((x) => x.split(' ').length <= 8).toList();
        final list = En.shuf(pool).take(8).toList();
        body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('اضغط 🎤 واقرأ الجملة بصوت واضح، والتطبيق يقول لك كم نطقك صح ✨', style: TextStyle(color: C.soft)),
          const SizedBox(height: 8),
          for (final s in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tile(
                ListTile(leading: const Text('🎤', style: TextStyle(fontSize: 26)), title: Text(s, textDirection: TextDirection.ltr, style: _en(15.5))),
                () => _push(context, SpeakScreen(target: s)),
                color: const Color(0xFFF7F9FD),
              ),
            ),
        ]);
      case 'vocab':
        body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Pills(items: v.keys.toList(), index: v.keys.toList().indexOf(_vcat), onTap: (i) => setState(() => _vcat = v.keys.elementAt(i))),
          const SizedBox(height: 8),
          for (final w in v[_vcat] ?? <List<String>>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tile(
                ListTile(
                  leading: Text(w[2], style: const TextStyle(fontSize: 28)),
                  title: Row(children: [Text(w[0], style: _en(16.5)), const SizedBox(width: 8), Text(w[1], style: const TextStyle(color: C.purple, fontWeight: FontWeight.w800))]),
                  subtitle: Text(w[3], textDirection: TextDirection.ltr, style: _en(13, w: FontWeight.w500)),
                ),
                () {
                  En.say('${w[0]}. ${w[3]}');
                  _show(context, [
                    Text(w[2], textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
                    Text(w[0], textAlign: TextAlign.center, style: _en(28)),
                    Text(w[1], textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(w[3], textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: _en(18, w: FontWeight.w600, c: C.purple)),
                  ], again: () => En.say('${w[0]}. ${w[3]}'));
                },
                color: const Color(0xFFF7F9FD),
              ),
            ),
          _row2(_btn('❓ وش معناها؟', () => _push(context, EnGame.vocab(_vcat))), _btn('🧱 رتّب الجملة', () => _push(context, EnGame.abuild(_vcat)), alt: true)),
        ]);
      case 'gram':
        final g = En.gram;
        body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < g.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF7F9FD), borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: '${g[i]['a']}  ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  TextSpan(text: g[i]['t'].toString(), style: _en(13, c: C.soft)),
                ])),
                Text(g[i]['r'].toString(), style: const TextStyle(height: 1.6)),
                for (final e in (g[i]['ex'] as List? ?? []))
                  InkWell(
                    onTap: () => En.say((e as List)[0].toString()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('🔊 ${(e as List)[0]}', textDirection: TextDirection.ltr, style: _en(15, w: FontWeight.w600)),
                        Text(e[1].toString(), style: const TextStyle(color: C.soft, fontSize: 13)),
                      ]),
                    ),
                  ),
                _btn('✏️ تمرين (٥ أسئلة)', () => _push(context, EnGame.gram(i)), alt: true),
              ]),
            ),
          _btn('🏆 اختبار شامل في القواعد', () => _push(context, EnGame.gram(-1))),
        ]);
      case 'dlg':
        final girl = currentHeroes().isNotEmpty && currentHeroes().first.isGirl;
        body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('محادثات يومية، و${girl ? 'أنتِ' : 'أنت'} أحد الشخصيات! اضغط أي جملة واسمعها', style: const TextStyle(color: C.soft)),
          const SizedBox(height: 8),
          for (var i = 0; i < En.dlg.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tile(
                ListTile(
                  leading: Text(En.dlg[i]['e'].toString(), style: const TextStyle(fontSize: 30)),
                  title: Text(En.dlg[i]['t'].toString(), textDirection: TextDirection.ltr, style: _en(16)),
                  subtitle: Text('${Learn.ar((En.dlg[i]['l'] as List).length)} جمل'),
                ),
                () => _push(context, DialogScreen(i: i)),
                color: const Color(0xFFF7F9FD),
              ),
            ),
        ]);
      default:
        body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('تسمع الكلمة وتكتبها بالإنجليزي. فيه تلميح لو احتجت 💡', style: TextStyle(color: C.soft)),
          _btn('🎧 ابدأ الإملاء', () => _push(context, EnGame.spell())),
        ]);
    }
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('إنجليزي متقدّم 🚀', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Pills(items: subs.map((s) => s.$2).toList(), index: subs.indexWhere((s) => s.$1 == _sub), onTap: (i) => setState(() => _sub = subs[i].$1)),
        const SizedBox(height: 12),
        body,
      ]),
    );
  }
}

/* ======================= محرك ألعاب الإنجليزي ======================= */
class EnQ {
  final String kind; // mcq | build | spell
  final String q, say, a;
  final String? show, gq, hint;
  final List<String> o, words;
  final bool big, en, mute;
  final String ar;
  EnQ({this.kind = 'mcq', this.q = '', required this.say, this.a = '', this.show, this.gq, this.hint, this.o = const [], this.words = const [], this.big = false, this.en = false, this.mute = false, this.ar = ''});
}

class EnGame extends StatefulWidget {
  final String id, title;
  final List<EnQ> qs;
  const EnGame({super.key, required this.id, required this.title, required this.qs});

  static List<String> _opts(String a, Iterable<String> pool, int n) => En.shuf([a, ...En.shuf(pool.where((x) => x != a).toSet()).take(n)]);

  factory EnGame.letters() {
    final l = Learn.letters;
    return EnGame(
        id: 'en-letters',
        title: '🎯 وين الحرف؟',
        qs: En.shuf(l).take(5).map((r) => EnQ(q: 'اسمع الحرف، ووين هو؟', say: r[0], a: r[0], o: _opts(r[0], l.map((x) => x[0]), 2), big: true)).toList());
  }
  factory EnGame.words(String cat) {
    final all = Learn.words.values.expand((e) => e).toList();
    return EnGame(
        id: 'en-words',
        title: '🎧 اسمع واختار',
        qs: En.shuf(Learn.words[cat] ?? all).take(5).map((w) => EnQ(q: 'اسمع الكلمة، ووين صورتها؟', say: w[0], a: w[2], o: _opts(w[2], all.map((x) => x[2]), 2), big: true)).toList());
  }
  factory EnGame.mean() {
    final s = Learn.sentences;
    return EnGame(
        id: 'en-mean',
        title: '❓ وش معناها؟',
        qs: En.shuf(s).take(5).map((x) => EnQ(q: 'وش معنى الجملة؟', say: En.nm(x[0]), show: En.nm(x[0]), a: En.nm(x[1]), o: _opts(En.nm(x[1]), s.map((y) => En.nm(y[1])), 2))).toList());
  }
  factory EnGame.build() => EnGame(
      id: 'en-build',
      title: '🧱 رتّب الجملة',
      qs: En.shuf(Learn.sentences.where((x) => x[0].split(' ').length <= 5)).take(5).map((x) => EnQ(kind: 'build', words: En.nm(x[0]).split(' '), ar: En.nm(x[1]), say: En.nm(x[0]))).toList());
  factory EnGame.vocab(String cat) {
    final all = En.vocab.values.expand((e) => e).toList();
    return EnGame(
        id: 'en-vocab',
        title: '🧠 وش معناها؟',
        qs: En.shuf(En.vocab[cat] ?? all).take(6).map((w) => EnQ(q: 'وش معنى الكلمة؟', say: w[0], show: w[0], a: w[1], o: _opts(w[1], all.map((x) => x[1]), 3))).toList());
  }
  factory EnGame.abuild(String cat) => EnGame(
      id: 'en-abuild',
      title: '🧱 رتّب الجملة',
      qs: En.shuf((En.vocab[cat] ?? []).where((w) => w[3].split(' ').length <= 8)).take(5).map((w) => EnQ(kind: 'build', words: w[3].split(' '), ar: '${w[2]} ${w[1]}', say: w[3])).toList());
  factory EnGame.gram(int i) {
    final g = En.gram;
    final src = i >= 0 ? (g[i]['quiz'] as List) : En.shuf(g.expand((x) => x['quiz'] as List)).take(8).toList();
    return EnGame(
        id: i >= 0 ? 'en-gram-$i' : 'en-gram',
        title: '📐 تمرين قواعد',
        qs: src.map((r) {
          final x = (r as List).map((e) => e.toString()).toList();
          return EnQ(q: 'اختر الكلمة الصحيحة', gq: x[0], say: x[0].replaceAll('___', x[1]), a: x[1], o: En.shuf(x.sublist(1)), en: true, mute: true);
        }).toList());
  }
  factory EnGame.read(int i) {
    final r = En.read[i];
    return EnGame(
        id: 'en-read-$i',
        title: '📖 فهم المقروء',
        qs: ((r['q'] as List?) ?? []).map((q) {
          final x = (q as List).map((e) => e.toString()).toList();
          return EnQ(q: '${r['e']} ${r['t']}', show: x[0], say: x[0], a: x[1], o: En.shuf(x.sublist(1)), en: true);
        }).toList());
  }
  factory EnGame.spell() {
    final all = En.vocab.values.expand((e) => e).where((w) => RegExp(r'^[a-z]{4,10}$').hasMatch(w[0])).toList();
    return EnGame(id: 'en-spell', title: '🎧 إملاء', qs: En.shuf(all).take(6).map((w) => EnQ(kind: 'spell', a: w[0], say: w[0], hint: '${w[2]} ${w[1]}')).toList());
  }
  factory EnGame.fam() {
    final f = En.fam;
    final all = f.values.expand((e) => e).toList();
    return EnGame(
        id: 'en-fam',
        title: '👪 اسمع واختار',
        qs: En.shuf(all).take(6).map((w) {
          final fam = f.values.firstWhere((l) => l.any((x) => x[0] == w[0]));
          return EnQ(q: 'وين الكلمة اللي سمعتها؟', say: w[0], a: '${w[1]} ${w[0]}', o: En.shuf(['${w[1]} ${w[0]}', ...En.shuf(fam.where((x) => x[0] != w[0])).take(2).map((x) => '${x[1]} ${x[0]}')]), en: true, big: true);
        }).toList());
  }
  factory EnGame.sight() {
    final s = Learn.sight;
    return EnGame(id: 'en-sight', title: '👀 كلمات سريعة', qs: En.shuf(s).take(8).map((w) => EnQ(q: 'وين الكلمة اللي سمعتها؟', say: w, a: w, o: _opts(w, s, 3), en: true, big: true)).toList());
  }

  @override
  State<EnGame> createState() => _EnGameState();
}

class _EnGameState extends State<EnGame> {
  int i = 0, score = 0;
  int? picked;
  final built = <int>[];
  List<int> pool = [];
  String? typed;
  bool hint = false;
  final _in = TextEditingController();

  EnQ? get it => i < widget.qs.length ? widget.qs[i] : null;

  @override
  void initState() {
    super.initState();
    _prep();
  }

  void _prep() {
    final q = it;
    picked = null;
    built.clear();
    typed = null;
    hint = false;
    _in.clear();
    if (q == null) {
      En.log(widget.id, widget.qs.isEmpty ? 0 : (score * 5 / widget.qs.length).round());
      return;
    }
    if (q.kind == 'build') pool = En.shuf(List.generate(q.words.length, (k) => k));
    if (!q.mute && q.kind != 'build') Future.delayed(const Duration(milliseconds: 300), () => En.say(q.say));
  }

  void _next([int add = 0]) => setState(() {
        score += add;
        i++;
        _prep();
      });

  @override
  void dispose() {
    Voice.stop();
    super.dispose();
  }

  Widget _opt(String o, int k, EnQ q) {
    final ans = picked != null;
    final ok = o == q.a, mine = k == picked;
    final bg = ans && ok ? const Color(0xFFDDF7E8) : ans && mine ? const Color(0xFFFFE3E3) : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: ans
              ? null
              : () {
                  setState(() {
                    picked = k;
                    if (ok) score++;
                  });
                  ok ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
                  if (q.mute) En.say(q.say);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Text(o, textAlign: TextAlign.center, textDirection: q.en ? TextDirection.ltr : null, style: q.big ? const TextStyle(fontSize: 32) : _en(17, c: C.ink)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = it;
    final n = widget.qs.length;
    if (q == null) {
      return EnPage(title: '🎉 Great job!', children: [
        SoftCard(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text('${'⭐' * score}${'☆' * (n - score).clamp(0, 99)}', style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(score >= n * .8 ? 'Excellent! ممتاز 🏆' : score >= n * .4 ? 'Good! زين، كمّل 👏' : 'Try again! جرّب مرة ثانية 💪', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            BigButton(label: 'تمام', onTap: () => Navigator.pop(context)),
          ]),
        ),
      ]);
    }
    final head = '${widget.title}  ${Learn.ar(i + 1)}/${Learn.ar(n)}';
    if (q.kind == 'spell') {
      final done = typed != null, ok = done && typed == q.a;
      return EnPage(title: head, children: [
        SoftCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('اسمع الكلمة واكتبها', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            _btn('🔊 اسمع', () => En.say(q.say), alt: true),
            if (hint) Padding(padding: const EdgeInsets.only(top: 10), child: Text('💡 ${q.hint} · تبدأ بـ ${q.a[0]} · ${Learn.ar(q.a.length)} حروف', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _in,
                enabled: !done,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                textAlign: TextAlign.center,
                style: _en(24),
                onSubmitted: (_) => _check(),
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF4F7FC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
            ),
            if (done) ...[
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(ok ? '✅ Perfect! صح' : '💡 الصحيح: ${q.a}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              _btn('التالي ←', () => _next()),
            ] else
              _row2(_btn('تحقّق ✓', _check), hint ? const SizedBox() : _btn('💡 تلميح', () => setState(() => hint = true), alt: true)),
          ]),
        ),
      ]);
    }
    if (q.kind == 'build') {
      final done = built.length == q.words.length;
      final ok = done && built.map((k) => q.words[k]).join(' ') == q.words.join(' ');
      Widget w(int k, bool on) => Padding(
            padding: const EdgeInsets.all(4),
            child: ActionChip(
              label: Text(q.words[k], style: _en(16, c: on ? Colors.white : C.ink)),
              backgroundColor: on ? C.orange : Colors.white,
              side: BorderSide(color: on ? C.orange : const Color(0xFFDDE3EE)),
              onPressed: done
                  ? null
                  : () => setState(() {
                        on ? built.remove(k) : built.add(k);
                        if (built.length == q.words.length) En.say(q.say);
                      }),
            ),
          );
      return EnPage(title: head, children: [
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(q.ar, textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(16)),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: built.isEmpty
                    ? const Center(child: Text('اضغط الكلمات بالترتيب…', style: TextStyle(color: C.soft)))
                    : Wrap(children: [for (final k in built) w(k, true)]),
              ),
            ),
            const SizedBox(height: 10),
            Directionality(textDirection: TextDirection.ltr, child: Wrap(alignment: WrapAlignment.center, children: [for (final k in pool) if (!built.contains(k)) w(k, false)])),
            if (done) ...[
              Padding(padding: const EdgeInsets.only(top: 10), child: Text('${ok ? '✅ صح! ' : '💡 الصحيح: '}${q.words.join(' ')}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              _btn('التالي ←', () => _next(ok ? 1 : 0)),
            ] else
              _btn('🔊 اسمع الجملة', () => En.say(q.say), alt: true),
          ]),
        ),
      ]);
    }
    final ans = picked != null;
    return EnPage(title: head, children: [
      SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(q.q, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (q.gq != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(ans ? q.say : q.gq!, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: _en(21, c: C.purple))),
          if (q.gq == null && q.show != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(q.show!, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: _en(21))),
          if (!q.mute || ans) _btn('🔊 اسمع', () => En.say(q.say), alt: true),
          for (var k = 0; k < q.o.length; k++) _opt(q.o[k], k, q),
          if (ans) ...[
            Padding(padding: const EdgeInsets.only(top: 10), child: Text(q.o[picked!] == q.a ? '✅ Yes! صح' : '💡 الجواب: ${q.a}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            _btn('التالي ←', () => _next()),
          ],
        ]),
      ),
    ]);
  }

  void _check() {
    final v = _in.text.trim().toLowerCase();
    if (v.isEmpty) return;
    setState(() {
      typed = v;
      if (v == it!.a) score++;
    });
  }
}

/* ======================= القراءة والمحادثات ======================= */
class ReadingScreen extends StatefulWidget {
  final int i;
  const ReadingScreen({super.key, required this.i});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int on = -1;
  bool tr = false;
  @override
  void dispose() {
    Voice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = En.read[widget.i];
    final ss = En.sents(r['en'].toString());
    return EnPage(title: '📖 ${r['t']}', children: [
      SoftCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(r['e'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
          Text(r['t'].toString(), textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: _en(22)),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(children: [
              for (var k = 0; k < ss.length; k++)
                GestureDetector(
                  onTap: () {
                    setState(() => on = k);
                    En.say(ss[k]);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 4, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(color: on == k ? const Color(0xFFFFF1C9) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                    child: Text(ss[k], style: _en(17, w: FontWeight.w600).copyWith(height: 1.7)),
                  ),
                ),
            ]),
          ),
          if (tr)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(14)),
              child: Text(r['ar'].toString(), style: const TextStyle(fontSize: 16, height: 1.8)),
            ),
          _row2(_btn('🔊 اسمع القصة', () => En.say(r['en'].toString(), rate: .4), alt: true), _btn(tr ? '🙈 أخفِ الترجمة' : '🇸🇦 الترجمة', () => setState(() => tr = !tr), alt: true)),
          _btn('❓ جاوب الأسئلة', () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EnGame.read(widget.i)))),
        ]),
      ),
    ]);
  }
}

class DialogScreen extends StatefulWidget {
  final int i;
  const DialogScreen({super.key, required this.i});
  @override
  State<DialogScreen> createState() => _DialogScreenState();
}

class _DialogScreenState extends State<DialogScreen> {
  bool playing = false;
  @override
  void dispose() {
    playing = false;
    Voice.stop();
    super.dispose();
  }

  Future<void> _all(List l) async {
    setState(() => playing = true);
    for (final x in l) {
      if (!mounted || !playing) break;
      await Voice.speak(En.nm((x as List)[1].toString()), .42, en: true);
    }
    if (mounted) setState(() => playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = En.dlg[widget.i];
    final l = (d['l'] as List?) ?? [];
    return EnPage(title: '💬 ${d['t']}', children: [
      Text(d['e'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
      for (final x in l)
        Align(
          alignment: (x as List)[0] == 'a' ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: GestureDetector(
            onTap: () => En.say(En.nm(x[1].toString())),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: x[0] == 'a' ? const Color(0xFFFFF1E2) : Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x[0] == 'a' ? En.name : d['b'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: C.purple)),
                Text(En.nm(x[1].toString()), textDirection: TextDirection.ltr, style: _en(16, w: FontWeight.w600)),
                Text(En.nm(x[2].toString()), style: const TextStyle(color: C.soft, fontSize: 13)),
              ]),
            ),
          ),
        ),
      _btn(playing ? '⏹ إيقاف' : '▶ شغّل المحادثة كاملة', () {
        if (playing) {
          setState(() => playing = false);
          Voice.stop();
        } else {
          _all(l);
        }
      }),
    ]);
  }
}

/* ======================= أصوات الحروف، العائلات، الكلمات السريعة ======================= */
class PhonicsScreen extends StatefulWidget {
  const PhonicsScreen({super.key});
  @override
  State<PhonicsScreen> createState() => _PhonicsScreenState();
}

class _PhonicsScreenState extends State<PhonicsScreen> {
  String? cur;
  @override
  Widget build(BuildContext context) {
    final snd = En.snd, ex = En.ex;
    final L = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    return EnPage(title: '🗣️ أصوات الحروف', children: [
      const Text('كل حرف له صوت! اضغط واسمع', style: TextStyle(color: Color(0xFF34406E), fontWeight: FontWeight.w700)),
      if (cur != null)
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text('$cur${cur!.toLowerCase()}', style: _en(54, c: C.orange)),
            Text(ex[cur]?[1] ?? '', style: const TextStyle(fontSize: 52)),
            Text('${cur!.toLowerCase()} says “${snd[cur]}” as in ${ex[cur]?[0]}', textDirection: TextDirection.ltr, style: _en(18, w: FontWeight.w600)),
          ]),
        ),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final l in L)
            _tile(
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$l${l.toLowerCase()}', style: _en(20, c: C.orange)), Text(ex[l]?[1] ?? '', style: const TextStyle(fontSize: 24))]),
              () {
                setState(() => cur = l);
                En.say('${snd[l]}. ${snd[l]}. ${ex[l]?[0]}', rate: .38);
              },
            ),
        ],
      ),
    ]);
  }
}

class FamiliesScreen extends StatelessWidget {
  const FamiliesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return EnPage(title: '👪 عائلات الكلمات', children: [
      const Text('كلمات تنتهي بنفس الصوت. اضغط واسمع', style: TextStyle(color: Color(0xFF34406E), fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      for (final e in En.fam.entries)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              SizedBox(width: 48, child: Text(e.key, style: _en(18, c: C.purple))),
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final w in e.value)
                    ActionChip(
                      onPressed: () => En.say(w[0]),
                      label: Text('${w[1]} ${w[0]}', style: _en(15)),
                      backgroundColor: const Color(0xFFF7F9FD),
                      side: BorderSide.none,
                    ),
                ]),
              ),
            ]),
          ),
        ),
      _btn('🎧 لعبة: اسمع واختار', () => _push(context, EnGame.fam())),
    ]);
  }
}

class SightScreen extends StatelessWidget {
  const SightScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return EnPage(title: '👀 كلمات سريعة', children: [
      const Text('كلمات نشوفها كثير في القراءة. احفظها بالشكل!', style: TextStyle(color: Color(0xFF34406E), fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final w in Learn.sight)
            ActionChip(onPressed: () => En.say(w), label: Text(w, style: _en(18)), backgroundColor: Colors.white, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ]),
      ),
      _btn('🎯 لعبة: اسمع واختار', () => _push(context, EnGame.sight())),
    ]);
  }
}

/* ======================= تتبّع الحرف بالإصبع ======================= */
class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});
  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  int i = 0;
  bool low = false, done = false;
  final strokes = <List<Offset>>[];
  List<Offset> mask = []; // نقاط داخل شكل الحرف (لوحة ٣٠٠×٣٠٠)
  String fb = '';

  String get ch => low ? 'abcdefghijklmnopqrstuvwxyz'[i] : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[i];

  @override
  void initState() {
    super.initState();
    _load();
  }

  TextPainter _tp(Color c) => TextPainter(
        text: TextSpan(text: ch, style: TextStyle(fontSize: 250, fontWeight: FontWeight.w900, color: c, fontFamily: 'sans-serif', height: 1)),
        textDirection: TextDirection.ltr,
      )..layout();

  Future<void> _load() async {
    strokes.clear();
    done = false;
    fb = '';
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final tp = _tp(Colors.black);
    tp.paint(c, Offset(150 - tp.width / 2, 150 - tp.height / 2));
    final img = await rec.endRecording().toImage(300, 300);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pts = <Offset>[];
    if (data != null) {
      for (var y = 0; y < 300; y += 6) {
        for (var x = 0; x < 300; x += 6) {
          if (data.getUint8((y * 300 + x) * 4 + 3) > 100) pts.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }
    if (mounted) setState(() => mask = pts);
    En.say(ch);
  }

  void _check() {
    if (done || mask.isEmpty) return;
    final all = strokes.expand((s) => s).toList();
    if (all.isEmpty) return;
    bool near(Offset p, List<Offset> l) => l.any((q) => (q - p).distanceSquared < 15 * 15);
    final hit = mask.where((m) => near(m, all)).length;
    final cov = hit / mask.length;
    final out = all.where((p) => !near(p, mask)).length / all.length;
    setState(() {
      if (cov > .62 && out < .55) {
        done = true;
        fb = '🌟 أحسنت! كتبت الحرف صح';
        HapticFeedback.mediumImpact();
        En.say('Great job!');
        En.log('en-trace', 5);
      } else {
        fb = cov > .3 ? 'كمّل… باقي شوي ✍️' : '';
      }
    });
  }

  void _go(int d) {
    i = (i + d + 26) % 26;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return EnPage(title: '✍️ تتبّع الحرف', children: [
      const Text('مرّر إصبعك فوق الحرف الباهت', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF34406E), fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: GestureDetector(
            onPanStart: (d) => setState(() => strokes.add([d.localPosition])),
            onPanUpdate: (d) => setState(() => strokes.last.add(d.localPosition)),
            onPanEnd: (_) => _check(),
            child: CustomPaint(painter: _TracePainter(_tp(const Color(0xFFE6E0F5)), strokes), size: const Size(300, 300)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(fb, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
      Row(children: [
        Expanded(child: _btn('→', () => _go(-1), alt: true)),
        const SizedBox(width: 6),
        Expanded(child: _btn(low ? 'ABC' : 'abc', () {
          low = !low;
          _load();
        }, alt: true)),
        const SizedBox(width: 6),
        Expanded(child: _btn('🧽 امسح', _load, alt: true)),
        const SizedBox(width: 6),
        Expanded(child: _btn('←', () => _go(1), alt: true)),
      ]),
    ]);
  }
}

class _TracePainter extends CustomPainter {
  final TextPainter tp;
  final List<List<Offset>> strokes;
  _TracePainter(this.tp, this.strokes);
  @override
  void paint(Canvas c, Size s) {
    tp.paint(c, Offset(150 - tp.width / 2, 150 - tp.height / 2));
    final p = Paint()
      ..color = C.orange
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final st in strokes) {
      if (st.length == 1) {
        c.drawCircle(st.first, 13, Paint()..color = C.orange);
        continue;
      }
      final path = Path()..moveTo(st.first.dx, st.first.dy);
      for (final o in st.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/* ======================= النطق بالمايك ======================= */
class SpeakScreen extends StatefulWidget {
  final String target;
  const SpeakScreen({super.key, required this.target});
  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  final _stt = SpeechToText();
  bool listening = false;
  String msg = 'اضغط المايك وتكلّم', heard = '';
  int pct = -1;

  static List<String> norm(String t) => t.toLowerCase().replaceAll(RegExp(r"[^a-z' ]"), ' ').split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();

  Future<void> _listen() async {
    if (listening) {
      await _stt.stop();
      return;
    }
    await Voice.stop();
    final ok = await _stt.initialize(onError: (e) => setState(() {
          listening = false;
          msg = e.errorMsg.contains('permission') ? 'اسمح للتطبيق يستخدم المايك من الإعدادات 🎤' : 'ما سمعت زين، جرّب مرة ثانية';
        }));
    if (!ok) {
      setState(() => msg = 'الجهاز ما يدعم التعرّف على الصوت، أو المايك مقفل 😔');
      return;
    }
    setState(() {
      listening = true;
      msg = 'أسمعك… 👂';
    });
    await _stt.listen(
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(partialResults: false),
      onResult: (r) {
        if (!r.finalResult) return;
        final tw = norm(widget.target);
        var best = 0.0, h = r.recognizedWords;
        for (final a in r.alternates) {
          final hw = norm(a.recognizedWords);
          final sc = tw.where(hw.contains).length / tw.length;
          if (sc > best) {
            best = sc;
            h = a.recognizedWords;
          }
        }
        setState(() {
          listening = false;
          heard = h;
          pct = (best * 100).round();
          msg = pct >= 80 ? '🌟 نطق ممتاز!' : pct >= 50 ? '👍 قريب! جرّب مرة ثانية' : '💪 خلنا نحاول مرة ثانية';
        });
        if (pct >= 80) En.log('en-speak', 5);
      },
    );
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tw = norm(widget.target), hw = norm(heard);
    return EnPage(title: '🎤 انطق الجملة', children: [
      SoftCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.target, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: _en(22, c: C.purple)),
          _btn('🔊 اسمعها أول', () => En.say(widget.target), alt: true),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _listen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 110,
                height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: listening ? const Color(0xFFE5484D) : C.orange, boxShadow: [BoxShadow(color: C.orange.withValues(alpha: .4), blurRadius: listening ? 30 : 14)]),
                child: const Center(child: Text('🎤', style: TextStyle(fontSize: 48))),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(pct >= 0 ? '$msg (${Learn.ar(pct)}٪)' : msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          if (heard.isNotEmpty) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
                for (final w in tw) Text(w, style: _en(18, c: hw.contains(w) ? const Color(0xFF2FA36B) : const Color(0xFFE5484D))),
              ]),
            ),
            Text('I heard: “$heard”', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(color: C.soft)),
          ],
        ]),
      ),
    ]);
  }
}

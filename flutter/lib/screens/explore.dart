import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../family.dart';
import '../learn.dart';
import '../nav.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';
import 'library.dart';

/// تبويب "اكتشف": رحلات حول العالم + الفضاء
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int get _sec => Nav.explore.value;
  String _region = 'all';
  String _q = '';

  @override
  void initState() {
    super.initState();
    Family.I.addListener(_r);
    Nav.explore.addListener(_r);
  }

  @override
  void dispose() {
    Family.I.removeListener(_r);
    Nav.explore.removeListener(_r);
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: 'اكتشف',
      subtitle: const ['سافر حول العالم ✈️', 'رحلة إلى الفضاء 🚀', 'قصصك المفضلة واللي قريتها 📚'][_sec],
      colors: _sec == 1 ? const [C.night1, Color(0xFF3A3F78), Color(0xFF6E6AAE)] : null,
      children: [
        Pills(items: const ['✈️ رحلات حول العالم', '🪐 الكواكب والقمر', '📚 مكتبة القصص'], index: _sec, onTap: (i) => Nav.explore.value = i),
        const SizedBox(height: 14),
        if (_sec == 0) ..._trips(context),
        if (_sec == 1) ..._space(context),
        if (_sec == 2) const MyLibrary(),
      ],
    );
  }

  /* ---------------- الرحلات ---------------- */
  List<Widget> _trips(BuildContext context) {
    final all = Learn.countries;
    final pass = Family.I.passport;
    final list = all.where((c) => (_region == 'all' || c['r'] == _region) && (_q.isEmpty || c['n'].toString().contains(_q) || c['cap'].toString().contains(_q))).toList();
    final regions = Learn.regions;
    return [
      SoftCard(
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PassportScreen())),
        child: Row(children: [
          const Text('🛂', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('جواز سفري', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text(pass.isEmpty ? 'اختر دولة وابدأ أول رحلة!' : 'زرت ${Learn.ar(pass.length)} ${pass.length == 1 ? 'دولة' : 'دول'} من ${Learn.ar(all.length)}',
                  style: const TextStyle(fontSize: 14.5, color: C.soft, fontWeight: FontWeight.w600)),
            ]),
          ),
          Text(pass.take(3).map(Learn.flag).join(' '), style: const TextStyle(fontSize: 22)),
        ]),
      ),
      const SizedBox(height: 12),
      TextField(
        onChanged: (v) => setState(() => _q = v.trim()),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'ابحث عن دولة أو عاصمة',
          hintStyle: const TextStyle(color: Color(0xFFB3BBCB)),
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      Pills(items: regions.map((r) => r[1]).toList(), index: regions.indexWhere((r) => r[0] == _region) < 0 ? 0 : regions.indexWhere((r) => r[0] == _region), onTap: (i) => setState(() => _region = regions[i][0])),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .9),
        itemBuilder: (_, i) {
          final c = list[i];
          final been = pass.contains(c['c']);
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(country: c)));
              },
              child: Stack(children: [
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(Learn.flag(c['c'].toString()), style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 4),
                    Text(c['n'].toString(), textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2)),
                  ]),
                ),
                if (been) const Positioned(top: 6, left: 8, child: Text('✅', style: TextStyle(fontSize: 14))),
              ]),
            ),
          );
        },
      ),
    ];
  }

  /* ---------------- الفضاء ---------------- */
  List<Widget> _space(BuildContext context) {
    final age = Learn.moonAge();
    final (pn, pd) = Learn.phase(age);
    final man = Learn.mansions;
    final mi = Learn.mansionIdx();
    final m = man.isNotEmpty ? man[mi] : const ['', '', ''];
    final planets = Learn.planets;
    const white = TextStyle(color: Colors.white);
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white24)),
        child: Column(children: [
          const Text('قمر الليلة', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SizedBox(width: 150, height: 150, child: CustomPaint(painter: MoonPainter(age))),
          const SizedBox(height: 8),
          Text(pn, style: white.copyWith(fontSize: 21, fontWeight: FontWeight.w800)),
          Text('مضيء ${Learn.ar(Learn.illum(age))}٪ · عمره ${Learn.ar(age.floor() + 1)} ${age < 10 ? 'أيام' : 'يومًا'}', style: white.copyWith(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(pd, textAlign: TextAlign.center, style: white.copyWith(fontSize: 16.5, height: 1.6, fontWeight: FontWeight.w600)),
          const Divider(color: Colors.white24, height: 26),
          Text('القمر الليلة في منزلة «${m[0]}»', style: white.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('ومعناها: ${m[1]}', style: white.copyWith(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(m[2], textAlign: TextAlign.center, style: white.copyWith(fontSize: 15.5, height: 1.6)),
          const SizedBox(height: 8),
          SpeakButton('قمر الليلة $pn. $pd. والقمر الليلة في منزلة ${m[0]}. ${m[2]}'),
        ]),
      ),
      const SizedBox(height: 14),
      BigButton(
        label: 'اختبار الفضاء 🚀',
        onTap: () {
          final qs = [...Learn.spaceQuiz]..shuffle();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => QuizScreen(
                    title: 'اختبار الفضاء',
                    colors: const [C.night1, Color(0xFF3A3F78), Color(0xFF8C86C9)],
                    questions: qs.take(6).map((r) => QuizQ(prompt: r[0], answer: r[1], wrong: r.sublist(2), big: '🪐')).toList(),
                    onDone: (s, n) => Family.I.logAct('space', s: 'quiz', score: s),
                  )));
        },
      ),
      Padding(padding: const EdgeInsets.fromLTRB(6, 20, 6, 10), child: Text('الكواكب 🪐', style: white.copyWith(fontSize: 20, fontWeight: FontWeight.w800))),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: planets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final p = planets[i];
            final cs = ((p['c'] as List?) ?? ['#cccccc', '#888888']).map((x) => hexColor(x.toString())).toList();
            final r = ((p['r'] as num?) ?? 1).toDouble();
            return GestureDetector(
              onTap: () => _planet(context, p, cs),
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white24)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(height: 80, child: Center(child: PlanetBall(colors: cs, size: (24 + 14 * (r > 4 ? 4 : r)).toDouble(), ring: p['e'] == 'Saturn'))),
                  Text(p['n'].toString(), style: white.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text(p['e'].toString(), style: white.copyWith(color: Colors.white60, fontSize: 12.5)),
                ]),
              ),
            );
          },
        ),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(6, 20, 6, 10), child: Text('نجوم السماء ✨', style: white.copyWith(fontSize: 20, fontWeight: FontWeight.w800))),
      for (final s in Learn.stars)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s[0], style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s[1], style: white.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(s[2], style: white.copyWith(color: Colors.white.withValues(alpha: .85), fontSize: 15, height: 1.5)),
              ]),
            ),
          ]),
        ),
      Padding(padding: const EdgeInsets.fromLTRB(6, 14, 6, 10), child: Text('منازل القمر الـ٢٨ 🌙', style: white.copyWith(fontSize: 20, fontWeight: FontWeight.w800))),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < man.length; i++)
          GestureDetector(
            onTap: () => _sheet(context, '🌙 ${man[i][0]}', 'معناها: ${man[i][1]}\n\n${man[i][2]}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: i == mi ? C.orange : Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
              child: Text('${Learn.ar(i + 1)}. ${man[i][0]}', style: white.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
      ]),
    ];
  }

  void _planet(BuildContext context, Map<String, dynamic> p, List<Color> cs) {
    HapticFeedback.lightImpact();
    Family.I.logAct('space', s: p['e'].toString());
    final facts = ((p['f'] as List?) ?? []).map((x) => x.toString()).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .92,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.fromLTRB(22, 18, 22, 30), children: [
          Center(child: PlanetBall(colors: cs, size: 90, ring: p['e'] == 'Saturn')),
          const SizedBox(height: 10),
          Text('${p['n']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          Text('${p['e']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: C.soft, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final row in [
            ('☀️', 'بُعده عن الشمس', p['d']),
            ('📏', 'حجمه', p['sz']),
            ('🕐', 'طول اليوم', p['day']),
            ('📅', 'طول السنة', '${Learn.ar(p['yr'] ?? '')} يومًا من أيامنا'),
            ('🌙', 'أقماره', p['mo']),
            ('🌡️', 'الحرارة', p['t']),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(row.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text('${row.$2}: ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Expanded(child: Text('${row.$3 ?? ''}', style: const TextStyle(fontSize: 16, color: C.soft, fontWeight: FontWeight.w600))),
              ]),
            ),
          const SizedBox(height: 6),
          for (final f in facts)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(16)),
              child: Text('✨ $f', style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 6),
          BigButton(label: 'اقرأ لي', icon: Icons.record_voice_over_rounded, onTap: () => Voice.stop().then((_) => Voice.speak('${p['n']}. ${facts.join(' ')}', .45))),
        ]),
      ),
    ).whenComplete(Voice.stop);
  }

  void _sheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, height: 1.6, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SpeakButton('$title. $body'.replaceAll('🌙', '')),
        ]),
      ),
    ).whenComplete(Voice.stop);
  }
}

/// رحلة لدولة: صفحات تتقلب (الوصول، المعالم، الأكل، معلومة) وختم في الجواز
class TripScreen extends StatefulWidget {
  final Map<String, dynamic> country;
  const TripScreen({super.key, required this.country});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final _pc = PageController();
  int _i = 0;
  late final List<(String, String, String)> _pages; // (نص، مشهد، رمز)

  Map<String, dynamic> get c => widget.country;

  @override
  void initState() {
    super.initState();
    final inf = Learn.info(c['c'].toString());
    final heroes = currentHeroes();
    final names = heroes.map((k) => k.name).join(' و');
    final sc = c['sc'].toString();
    final flag = Learn.flag(c['c'].toString());
    final p = <(String, String, String)>[];
    final hrs = inf?['h'];
    p.add(('ركب $names الطيارة ✈️ ${hrs != null ? 'وبعد ${Learn.ar(hrs)} ساعات تقريبًا ' : ''}وصلوا ${c['n']}! عاصمتها ${c['cap']}.${inf != null ? ' أهلها يتكلمون ${inf['lang']}، ويقولون للترحيب: «${inf['hi']}».' : ''}', sc, flag));
    final sights = ((inf?['sights'] as List?) ?? []).map((s) => (s as List).map((x) => x.toString()).toList()).toList();
    if (sights.isEmpty) {
      sights.addAll([
        ['جولة في العاصمة ${c['cap']}', sc == 'sea' ? 'sea' : 'road', '🏙️'],
        sc == 'desert' ? ['رحلة في الصحراء', 'desert', '🐪'] : sc == 'sea' ? ['يوم على الشاطئ', 'sea', '🏖️'] : sc == 'mountain' ? ['نطلع الجبال', 'mountain', '⛰️'] : ['نتمشى في الطبيعة', 'garden', '🌳'],
        ['نتسوّق من السوق الشعبي', 'souq', '🛍️'],
      ]);
    }
    for (final s in sights) {
      p.add(('اليوم: ${s[0]}. يا سلام وش هالمكان الحلو! 😍', s[1], s[2]));
    }
    p.add(('وقت الأكل! 🍽️ جرّبوا ${inf?['food'] ?? 'أكل البلد'}${inf?['cur'] != null ? '، ودفعوا بالعملة المحلية: ${inf!['cur']}' : ''}.', 'market', '🍽️'));
    if (inf?['fact'] != null) p.add(('هل تعرف؟ 💡 ${inf!['fact']}', sc, '💡'));
    p.add(('انتهت الرحلة! ختمنا جواز السفر بختم ${c['n']} $flag، ورجعنا البيت مبسوطين.', 'home', '🛂'));
    _pages = p;
  }

  @override
  void dispose() {
    Voice.stop();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await Family.I.stamp(c['c'].toString());
    Family.I.logAct('trip', s: c['c'].toString());
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(Learn.flag(c['c'].toString()), style: const TextStyle(fontSize: 64)),
          Text('ختم ${c['n']} في جوازك! 🛂', style: const TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800)),
          Text('زرت ${Learn.ar(Family.I.passport.length)} ${Family.I.passport.length == 1 ? 'دولة' : 'دول'} لين الحين', style: const TextStyle(fontSize: 16, color: C.soft, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          BigButton(label: 'تمام', onTap: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    final heroes = currentHeroes();
    final last = _i == _pages.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, top + 8, 12, 6),
            child: Row(children: [
              IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
              const SizedBox(width: 8),
              Text(Learn.flag(c['c'].toString()), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 6),
              Expanded(child: Text('رحلة إلى ${c['n']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF26305A)))),
              Text('${Learn.ar(_i + 1)}/${Learn.ar(_pages.length)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF34406E))),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (i) {
                Voice.stop();
                setState(() => _i = i);
              },
              itemBuilder: (_, i) {
                final pg = _pages[i];
                return ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 12), children: [
                  SceneArt(scene: pg.$2, prop: pg.$3, heroes: heroes, radius: 26),
                  const SizedBox(height: 14),
                  SoftCard(padding: const EdgeInsets.all(18), child: Text(pg.$1, style: const TextStyle(fontSize: 20, height: 1.8, fontWeight: FontWeight.w600))),
                ]);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 16),
            child: Row(children: [
              SpeakButton(_pages[_i].$1, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: BigButton(
                  label: last ? 'اختم الجواز 🛂' : 'التالي',
                  onTap: last ? _finish : () => _pc.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// جواز السفر: أعلام الدول اللي زرناها
class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final been = Learn.countries.where((c) => Family.I.passport.contains(c['c'])).toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1F4E79), Color(0xFF2D6AA6), C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: ListView(padding: EdgeInsets.fromLTRB(18, top + 10, 18, 30), children: [
          Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
            const SizedBox(width: 10),
            const Text('🛂 جواز سفري', style: TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          if (been.isEmpty)
            const SoftCard(padding: EdgeInsets.all(26), child: Text('الجواز فاضي! سافر لأول دولة وتنختم هنا ✈️', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final c in been)
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5484D).withValues(alpha: .5), width: 2)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(Learn.flag(c['c'].toString()), style: const TextStyle(fontSize: 40)),
                      Text(c['n'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ]),
                  ),
              ],
            ),
        ]),
      ),
    );
  }
}

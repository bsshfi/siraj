import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../nav.dart';
import '../theme.dart';
import '../tonight_logic.dart';
import '../widgets/common.dart';
import '../widgets/pin.dart';
import '../widgets/scene.dart';
import 'me.dart';
import 'reader.dart';
import 'settings.dart';
import 'sounds.dart';

/// شاشة "الليلة" — نفس رئيسية الويب: الساعة والتاريخ والفصل، النجوم، رسالة الوالدين، أبطال الليلة، قصة الليلة، وقت النوم، الأذكار والأصوات
class TonightScreen extends StatefulWidget {
  const TonightScreen({super.key});
  @override
  State<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends State<TonightScreen> {
  Timer? _clock;
  final f = Family.I;

  @override
  void initState() {
    super.initState();
    f.addListener(_r);
    _clock = Timer.periodic(const Duration(seconds: 20), (_) => _r());
  }

  @override
  void dispose() {
    f.removeListener(_r);
    _clock?.cancel();
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  Future<void> _settings({String? jump}) async {
    if (!await askPin(context)) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(jump: jump)));
    _r();
  }

  static const _days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  (String, String) _season(DateTime d) {
    final v = d.month * 100 + d.day;
    return v >= 320 && v < 621 ? ('فصل الربيع', '🌸') : v >= 621 && v < 923 ? ('فصل الصيف', '☀️') : v >= 923 && v < 1221 ? ('فصل الخريف', '🍂') : ('فصل الشتاء', '❄️');
  }

  /// رسالة من بابا/ماما (تختفي لما يضغطون ❤️ أو بعد ساعة من أول ظهور)
  Widget? _msg(List<Kid> ks) {
    final m = f.fam['msg'];
    if (m is! Map || (m['t'] ?? '').toString().isEmpty) return null;
    final at = (m['at'] as num?)?.toInt() ?? 0;
    final card = (String small, String body, {VoidCallback? seen}) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF0F5), Color(0xFFFFE3EE)]), borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              const Text('💌', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(small, style: const TextStyle(fontSize: 13, color: Color(0xFFC9407A), fontWeight: FontWeight.w800)),
                  Text(body, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.5)),
                ]),
              ),
              if (seen != null) IconButton(onPressed: seen, icon: const Text('❤️', style: TextStyle(fontSize: 26))),
            ]),
          ),
        );
    if (f.isParent && f.parentMode != 'kids') return card('رسالتك للعيال (تظهر لهم فوق)', m['t'].toString());
    if (f.msgSeen >= at) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - at > 24 * 3600000) return null;
    if (f.msgFirstAt != at) f.markMsgShown(at);
    if (now - f.msgFirstShown > 3600000) return null;
    final to = m['to'];
    if (to is List && !ks.any((k) => to.contains(k.id))) return null;
    return card('رسالة من ${m['from'] ?? f.dad}', m['t'].toString(), seen: () {
      HapticFeedback.mediumImpact();
      f.seeMsg(at);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final now = DateTime.now();
    final shown = f.kids.isNotEmpty ? f.myKids : currentHeroes();
    final hs = currentHeroes();
    final k0 = hs.isNotEmpty ? hs.first : shown.first;
    final greet = now.hour >= 17 || now.hour < 4 ? 'مساء الخير' : 'أهلًا';
    final own = f.isChild && f.devKids.isNotEmpty && shown.length < f.kids.length;
    final season = _season(now);
    final list = Tonight.list(hs);
    final n = Tonight.readCount(hs), allow = f.allowedTonight;
    final nxt = Tonight.next(hs);
    final st = nxt ?? (list.isNotEmpty ? list.first : Library.stories.first);
    final done = nxt == null;
    const lbls = ['قصة الليلة', 'القصة الثانية الليلة', 'القصة الثالثة الليلة', 'القصة الرابعة الليلة'];
    final lbl = n < lbls.length ? lbls[n] : 'قصة إضافية';
    final sh = Tonight.level(hs) == 1 && st.canShort;
    final np = sh ? st.youngPages!.length : st.pages.length;
    final mins = (np * (sh ? .5 : .7)).round().clamp(sh ? 1 : 2, 99);
    final r = f.resume;
    final resumeAt = r != null && r['id'] == st.id && now.millisecondsSinceEpoch - ((r['at'] as num?) ?? 0) < 12 * 3600000 ? ((r['i'] as num?) ?? 0).toInt() : -1;
    final msg = _msg(hs);
    String fill(String x) => fillTemplate(x, k0, friends: hs.length > 1 ? hs.sublist(1) : const [], dad: f.dad, mom: f.mom);

    // شريط وقت النوم
    final bm = Family.mins(f.bedtime), nm = now.hour * 60 + now.minute;
    final left = bm - nm;
    final pct = (bm - 16 * 60) > 0 ? ((nm - 16 * 60) / (bm - 16 * 60)).clamp(.04, 1.0) : 1.0;

    Widget chip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(18)),
          child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.ink)),
        );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .3, .62]),
      ),
      child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, top + 12, 16, 4),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('سراج', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF26305A), height: 1.05)),
                    const SizedBox(width: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/brand/icon.png', width: 38, height: 38)),
                  ]),
                  Text(own ? '$greet يا ${shown.map((k) => k.name).join(' و')} 🌙' : '$greet، جاهزين للحكاية؟ 🌙',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF34406E))),
                ]),
              ),
              GestureDetector(
                onTap: () => Nav.go(2, explore: 1),
                child: SizedBox(width: 66, height: 66, child: CustomPaint(painter: MoonPainter(Learn.moonAge()))),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .85)),
                onPressed: _settings,
                icon: const Icon(Icons.settings_rounded, color: C.ink),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              chip('${_days[now.weekday - 1]} ${Learn.ar('${now.day}/${now.month}/${now.year}')}'),
              chip('${season.$2} ${season.$1}'),
              chip('⭐ ${Learn.ar(f.monthNights(k0))} ${f.monthNights(k0) == 1 ? 'نجمة' : 'نجوم'} هالشهر'),
              chip('🔥 ${Learn.ar(f.streakOf(k0))} ${f.streakOf(k0) == 1 ? 'ليلة' : 'ليالٍ'} متتالية'),
              if (f.isParent)
                GestureDetector(onTap: () => Nav.go(4), child: chip('📊 المتابعة')),
            ]),
          ),
        ),
        if (f.isParent)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .7), borderRadius: BorderRadius.circular(22)),
                  child: Row(children: [
                    for (final m in [('view', '🔍 معاينة'), ('kids', '📖 أقرأ مع العيال')])
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            f.setParentMode(m.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(color: f.parentMode == m.$1 ? C.orange : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                            child: Text(m.$2, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: f.parentMode == m.$1 ? Colors.white : C.ink)),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(f.parentMode == 'kids' ? 'القصص والألعاب تنحسب للأبطال المختارين ⭐' : 'تتصفح بس، وما ينحسب شي على العيال',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF34406E), fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        if (msg != null) SliverToBoxAdapter(child: msg),
        if (f.kids.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SoftCard(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: 'أبطال الليلة  ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      TextSpan(text: 'أول من تختاره هو البطل ⭐', style: TextStyle(fontSize: 12.5, color: C.soft, fontWeight: FontWeight.w700)),
                    ])),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 116,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (final k in shown) _kidPick(k),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: SoftCard(
              padding: const EdgeInsets.all(10),
              onTap: () => openStory(context, st, heroes: hs),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Hero(tag: 'art-${st.id}', child: SceneArt(scene: st.scene, heroes: Tonight.artHeroes(st, hs), prop: done ? '🌙' : st.occ != null ? '🎉' : st.isPro ? '📖' : '✨', radius: 20)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      if (done) _tag('خلّصتوا قصص الليلة 🌙 (${Learn.ar(n)}/${Learn.ar(allow)})', const Color(0xFFEFEAFF), const Color(0xFF5B4BDB)),
                      if (!done && st.occ != null) _tag('قصة المناسبة 🎉', const Color(0xFFE5FBEA), const Color(0xFF1E8E4A)),
                      if (!done) _tag(allow > 1 ? '$lbl · ${Learn.ar(n + 1)}/${Learn.ar(allow)}' : 'قصة الليلة', const Color(0xFFEDE6FF), C.purple),
                      _tag('${Tonight.catOf(st).$2} ${Tonight.catOf(st).$3}', const Color(0xFFF4F7FC), C.soft),
                    ]),
                    const SizedBox(height: 6),
                    Text(fill(st.title), style: const TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800, height: 1.3)),
                    if (resumeAt > 0) Text('📖 بتكمّل من الصفحة ${Learn.ar(resumeAt + 1)}', style: const TextStyle(color: C.orange, fontWeight: FontWeight.w800)),
                    Text('${Learn.ar(np)} صفحات · ${Learn.ar(mins)} دقائق · ${sh ? 'نسخة قصيرة للصغار ✂️' : 'قيمة: ${st.value}'}',
                        style: const TextStyle(fontSize: 14, color: C.soft, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (done) ...[
                      const Text('موعدنا الجاية مع قصة جديدة ✨ تقدرون تعيدون أي قصة من «اكتشف ← مكتبة القصص».', style: TextStyle(color: C.soft, height: 1.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: BigButton(label: '🤲 أذكار النوم', onTap: () => _adhkar(context, k0))),
                        const SizedBox(width: 10),
                        Expanded(child: BigButton(label: '🌧️ أصوات النوم', onTap: () => _sounds(context))),
                      ]),
                      TextButton(onPressed: () => openStory(context, st, heroes: hs), child: const Text('اقرأها مرة ثانية 🔁', style: TextStyle(fontWeight: FontWeight.w800))),
                    ] else
                      BigButton(label: 'ابدأ $lbl ✨', icon: Icons.auto_stories_rounded, onTap: () => openStory(context, st, heroes: hs)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: [
                Text(f.isNight ? '🌙 وقت النوم الحين' : '🌙 وقت النوم ${TimePick.fmt(f.bedtime)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: f.isNight ? 1 : pct, minHeight: 8, backgroundColor: const Color(0xFFEDF1F8), color: C.purple),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  f.isNight ? 'تصبحون على خير 😴' : left > 0 && left < 720 ? 'باقي ${left >= 60 ? '${Learn.ar(left ~/ 60)} س ' : ''}${Learn.ar(left % 60)} د' : '',
                  style: const TextStyle(fontSize: 13, color: C.soft, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: _nightBtn('🤲', 'أذكار النوم', f.adkDay == Family.dateKey(now) ? 'تمّت ✓' : 'قبل النوم', () => _adhkar(context, k0))),
              const SizedBox(width: 12),
              Expanded(child: _nightBtn('🌧️', 'أصوات النوم', 'مطر · موج · صحراء', () => _sounds(context))),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 120 + MediaQuery.of(context).padding.bottom)),
      ]),
    );
  }

  void _adhkar(BuildContext context, Kid k) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdhkarScreen(kid: k))).then((_) => _r());
  void _sounds(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SoundsScreen()));

  Widget _tag(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(t, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _nightBtn(String e, String t, String s, VoidCallback onTap) => SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        onTap: onTap,
        child: Column(children: [
          Text(e, style: const TextStyle(fontSize: 34)),
          Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(s, style: const TextStyle(fontSize: 12.5, color: C.soft, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _kidPick(Kid k) {
    final sel = currentHeroes().map((x) => x.id).toList();
    final i = sel.indexOf(k.id);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        final s = [...sel];
        if (i >= 0) {
          if (s.length > 1) s.remove(k.id);
        } else {
          s.add(k.id);
        }
        f.setHeroes(s);
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 10),
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: i >= 0 ? C.orange : const Color(0xFFE6EAF2)),
            child: Stack(clipBehavior: Clip.none, children: [
              KidFace(kid: k, size: 64),
            ]),
          ),
          if (i == 0)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFFFFD23F), borderRadius: BorderRadius.circular(10)),
              child: const Text('⭐ البطل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            )
          else
          const SizedBox(height: 3),
          Text(k.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: i >= 0 ? C.ink : C.soft)),
        ]),
      ),
    );
  }
}

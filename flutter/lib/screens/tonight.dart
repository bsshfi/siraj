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
import '../widgets/moon_reader.dart';
import '../widgets/pin.dart';
import '../widgets/scene.dart';
import 'me.dart';
import 'reader.dart';
import 'settings.dart';
import 'sounds.dart';
import '../widgets/stk.dart';

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

    final parent = f.isParent;
    final dayNames = _days[now.weekday - 1];
    final se = _seasonIcon(now);
    final bh = Family.mins(f.bedtime) ~/ 60, bmin = Family.mins(f.bedtime) % 60;
    final t12 = '${bh % 12 == 0 ? 12 : bh % 12}:${bmin.toString().padLeft(2, '0')} ${bh < 12 ? 'ص' : 'م'}';
    final rows = allow > 1 ? list.take(allow).toList() : const <Story>[];
    final cat = Tonight.catOf(st);

    return SkyBg(
      child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        // ===== الرأس: سراج + القمر اللي يقرأ + زر الضبط، والتاريخ والفصل، ووضع وليّ الأمر =====
        SliverToBoxAdapter(
          child: Stack(clipBehavior: Clip.none, children: [
            const Positioned(top: 0, left: 0, right: 0, child: SkyFx(height: 330)),
            Padding(
              padding: EdgeInsets.fromLTRB(16, top + 20, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 2, top: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('سراج', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: Color(0xFF2E2A6B), height: 1.05)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(0, 4))]),
                              child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.asset('assets/brand/icon.png', width: 44, height: 44)),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(own ? '$greet يا ${shown.map((k) => k.name).join(' و')} 🌙' : '$greet، جاهزين للحكاية؟ 🌙',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2E3A5C))),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Transform.translate(
                      offset: const Offset(-6, 0),
                      child: SizedBox(
                        width: 158,
                        height: 136,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Positioned.fill(child: GestureDetector(onTap: () => Nav.go(2, explore: 1), child: const MoonReader(width: 158))),
                          Positioned(
                            top: -2,
                            left: -4,
                            child: GestureDetector(
                              onTap: _settings,
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33284688), blurRadius: 16, offset: Offset(0, 6))]),
                                child: const StkIcon('tune', size: 22),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _hpill([
                      StkIcon('cal', size: 24, day: '${now.day}', outline: 1.2),
                      const SizedBox(width: 6),
                      Flexible(child: Text(dayNames, maxLines: 1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.ink))),
                      const SizedBox(width: 6),
                      Text('${now.day}/${now.month}/${now.year}',
                          textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF2E2A6B))),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _hpill([
                      StkIcon(se.$2, size: 24, outline: 1.2),
                      const SizedBox(width: 6),
                      Flexible(child: Text(se.$1, maxLines: 1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.ink))),
                    ]),
                  ),
                ]),
                if (parent) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xF2FFFFFF)),
                      boxShadow: const [BoxShadow(color: Color(0x1F3A5A8A), blurRadius: 16, offset: Offset(0, 6))],
                    ),
                    child: Row(children: [
                      for (final m in const [('view', 'search', 'معاينة'), ('kids', 'book', 'أقرأ مع العيال')])
                        Expanded(child: _modeBtn(m.$1, m.$2, m.$3)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 3, 0, 8),
                    child: Text(f.parentMode == 'kids' ? 'القصص والألعاب تنحسب للأبطال المختارين ⭐' : 'تتصفح بس، وما ينحسب شي على العيال',
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7290))),
                  ),
                ] else
                  const SizedBox(height: 12),
              ]),
            ),
          ]),
        ),
        if (msg != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 4), child: msg)),
        // ===== أبطال الليلة =====
        if (f.kids.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Color(0xFFF3ECFF)]),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [BoxShadow(color: Color(0x245A46AA), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(children: [
                        for (var i = 0; i < shown.length; i++) ...[if (i > 0) const SizedBox(width: 10), _kidPick(shown[i])],
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('أبطال الليلة', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF3B2E8C), height: 1.3)),
                  Text('أول من تختاره هو البطل ⭐', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3B2E8C), height: 1.3)),
                ]),
              ]),
            ),
          ),
        // ===== قصة الليلة =====
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SoftCard(
              clip: true,
              padding: EdgeInsets.zero,
              onTap: () => openStory(context, st, heroes: hs),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Hero(tag: 'art-${st.id}', child: SceneArt(scene: st.scene, heroes: Tonight.artHeroes(st, hs), prop: done ? '🌙' : st.occ != null ? '🎉' : st.isPro ? '📖' : '✨', radius: 0)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (done || st.occ != null || allow > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(spacing: 6, runSpacing: 6, children: [
                          if (done) _tag('خلّصتوا قصص الليلة 🌙 (${Learn.ar(n)}/${Learn.ar(allow)})', const Color(0xFFEFEAFF), const Color(0xFF5B4BDB)),
                          if (!done && st.occ != null) _tag('قصة المناسبة 🎉', const Color(0xFFE5FBEA), const Color(0xFF1E8E4A)),
                          if (!done && allow > 1) _tag('$lbl · ${n + 1}/$allow', const Color(0xFFEFEAFF), const Color(0xFF5B4BDB)),
                        ]),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 2),
                      child: Text(fill(st.title), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, height: 1.4)),
                    ),
                    if (resumeAt > 0) Text('📖 بتكمّل من الصفحة ${Learn.ar(resumeAt + 1)}', style: const TextStyle(color: C.orange, fontWeight: FontWeight.w800, fontSize: 14)),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${Learn.ar(np)} صفحات · ${Learn.ar(mins)} دقائق · ${sh ? 'نسخة قصيرة للصغار ✂️' : 'صور متحركة ✨'}',
                          style: const TextStyle(fontSize: 13, color: C.soft, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      _cat(cat.$1, '${cat.$2} ${cat.$3}'),
                      if (st.value.isNotEmpty && st.value != cat.$3) Text(st.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.soft)),
                    ]),
                    if (rows.length > 1)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF8F6FF), borderRadius: BorderRadius.circular(16)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const Text('قصص الليلة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.soft)),
                          for (var i = 0; i < rows.length; i++) Padding(padding: const EdgeInsets.only(top: 6), child: _tlRow(rows[i], i, n, hs, fill)),
                        ]),
                      ),
                    if (done) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('موعدنا الجاية مع قصة جديدة ✨ تقدرون تعيدون أي قصة من «اكتشف ← مكتبة القصص».', style: TextStyle(color: C.soft, height: 1.5, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: BigButton(label: '🤲 أذكار النوم', fontSize: 17, onTap: () => _adhkar(context, k0))),
                        const SizedBox(width: 10),
                        Expanded(child: BigButton(label: '🌧️ أصوات النوم', fontSize: 17, onTap: () => _sounds(context))),
                      ]),
                      Center(child: TextButton(onPressed: () => openStory(context, st, heroes: hs), child: const Text('اقرأها مرة ثانية 🔁', style: TextStyle(fontWeight: FontWeight.w800)))),
                    ] else
                      Padding(padding: const EdgeInsets.only(top: 14), child: BigButton(label: 'ابدأ $lbl ✨', onTap: () => openStory(context, st, heroes: hs))),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        // ===== شريط وقت النوم =====
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Text(f.isNight ? '🌙 وقت النوم الحين' : '🌙 وقت النوم', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                if (!f.isNight) ...[
                  const SizedBox(width: 6),
                  Text(t12, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(color: const Color(0xFFE6E0D6), borderRadius: BorderRadius.circular(7)),
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: f.isNight ? 1 : pct.toDouble(),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          gradient: const LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Color(0xFFFFC37A), Color(0xFFF2851E)]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  f.isNight ? 'تصبحون على خير 😴' : left > 0 && left < 720 ? 'باقي ${left >= 60 ? '${Learn.ar(left ~/ 60)} س ' : ''}${Learn.ar(left % 60)} د' : '',
                  style: const TextStyle(fontSize: 13.5, color: C.orange, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        ),
        // ===== أذكار النوم وأصوات النوم =====
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(children: [
              Expanded(child: _nightBtn('🤲', 'أذكار النوم', f.adkDay == Family.dateKey(now) ? 'تمّت ✓' : 'قبل النوم', () => _adhkar(context, k0))),
              const SizedBox(width: 10),
              Expanded(child: _nightBtn('🌧️', 'أصوات النوم', 'مطر · موج · صحراء', () => _sounds(context))),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 120 + MediaQuery.of(context).padding.bottom)),
      ]),
    );
  }

  (String, String) _seasonIcon(DateTime d) {
    final v = d.month * 100 + d.day;
    return v >= 320 && v < 621 ? ('فصل الربيع', 'spring') : v >= 621 && v < 923 ? ('فصل الصيف', 'summer') : v >= 923 && v < 1221 ? ('فصل الخريف', 'autumn') : ('فصل الشتاء', 'winter');
  }

  /// .hpill في الويب
  Widget _hpill(List<Widget> children) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6EA),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x293C5096), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: children),
      );

  /// زر وضع وليّ الأمر (.modebar button)
  Widget _modeBtn(String mode, String icon, String label) {
    final on = f.parentMode == mode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (on) return;
        HapticFeedback.selectionClick();
        f.setParentMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38,
        decoration: BoxDecoration(
          gradient: on ? const LinearGradient(colors: [C.orange2, C.orange], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
          borderRadius: BorderRadius.circular(13),
          boxShadow: on ? const [BoxShadow(color: Color(0x44F2851E), blurRadius: 10, offset: Offset(0, 4))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          StkIcon(icon, size: 19, outline: on ? 1.2 : 0),
          const SizedBox(width: 6),
          Flexible(child: Text(label, maxLines: 1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? Colors.white : const Color(0xFF5A6180)))),
        ]),
      ),
    );
  }

  /// ألوان التصنيفات (.c-xxx في الويب)
  static const _catColors = {
    'pro': (Color(0xFFE3F6EC), Color(0xFF13784A)),
    'occ': (Color(0xFFE5FBEA), Color(0xFF1E8E4A)),
    'truth': (Color(0xFFE6F0FF), Color(0xFF2456B8)),
    'share': (Color(0xFFFFF1D6), Color(0xFFB4630E)),
    'mercy': (Color(0xFFFFE6F0), Color(0xFFC2296B)),
    'brave': (Color(0xFFFFEBDD), Color(0xFFC2410C)),
    'patience': (Color(0xFFEAF7E1), Color(0xFF3F7D1F)),
    'faith': (Color(0xFFEFEAFF), Color(0xFF5B4BDB)),
    'know': (Color(0xFFE2F5FB), Color(0xFF0E7490)),
    'family': (Color(0xFFFDEBE7), Color(0xFFB23B2A)),
    'habits': (Color(0xFFFFF8D6), Color(0xFF8A6D00)),
    'manners': (Color(0xFFF2EFFC), Color(0xFF6B5FA8)),
    'sahaba': (Color(0xFFFFF6D9), Color(0xFF9A6B00)),
    'choose': (Color(0xFFE4F4FF), Color(0xFF1565A8)),
    'series': (Color(0xFFEFE6FF), Color(0xFF6B3FC6)),
  };

  Widget _cat(String key, String t, {bool small = false}) {
    final c = _catColors[key] ?? (const Color(0xFFFFF1D6), const Color(0xFFB4630E));
    return Container(
      padding: small ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2) : const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(999)),
      child: Text(t, maxLines: 1, style: TextStyle(color: c.$2, fontWeight: FontWeight.w800, fontSize: small ? 11 : 13.5)),
    );
  }

  /// صف من «قصص الليلة» (.tlr)
  Widget _tlRow(Story s, int i, int n, List<Kid> hs, String Function(String) fill) {
    final c = Tonight.catOf(s);
    final isDone = i < n, now = i == n;
    return Opacity(
      opacity: isDone ? .6 : 1,
      child: GestureDetector(
        onTap: () => openStory(context, s, heroes: hs),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: now ? C.orange : Colors.transparent, width: 2)),
          child: Row(children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isDone ? const Color(0xFFDDF5E5) : const Color(0xFFEFEAFF)),
              child: Text(isDone ? '✓' : Learn.ar(i + 1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDone ? const Color(0xFF1E8E4A) : const Color(0xFF5B4BDB))),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(fill(s.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            _cat(c.$1, '${c.$2} ${c.$3}', small: true),
          ]),
        ),
      ),
    );
  }

  void _adhkar(BuildContext context, Kid k) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdhkarScreen(kid: k))).then((_) => _r());
  void _sounds(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SoundsScreen()));

  Widget _tag(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  /// زرّا الأذكار والأصوات (.nightbtns)
  Widget _nightBtn(String e, String t, String s, VoidCallback onTap) => SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        onTap: onTap,
        child: Column(children: [
          Text(e, style: const TextStyle(fontSize: 34, height: 1.7)),
          Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(s, style: const TextStyle(fontSize: 12, color: C.orange, fontWeight: FontWeight.w800)),
        ]),
      );

  /// طفل في «أبطال الليلة» (.kid): دائرة ٦٠ بيضاء، المختار حدّه برتقالي مع هالة، والبطل عليه شارة
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: i >= 0 ? C.orange : Colors.white, width: 3),
              boxShadow: i >= 0 ? const [BoxShadow(color: Color(0x33F2851E), spreadRadius: 4)] : const [BoxShadow(color: Color(0x2650628A), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: KidFace(kid: k, size: 54, bg: Colors.white),
          ),
          if (i == 0)
            Positioned(
              top: -6,
              left: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(12)),
                child: const Text('البطل ⭐', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600, height: 1.5)),
              ),
            ),
        ]),
        const SizedBox(height: 3),
        Text(k.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.ink)),
      ]),
    );
  }
}

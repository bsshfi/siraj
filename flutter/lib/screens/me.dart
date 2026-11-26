import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets/common.dart';
import 'kid_editor.dart';

/// تبويب "أنا": شخصية الطفل، نجومه، أسبوعه، شاراته، وأذكار النوم
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});
  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  int _k = 0;

  @override
  void initState() {
    super.initState();
    Family.I.addListener(_r);
  }

  @override
  void dispose() {
    Family.I.removeListener(_r);
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  static final Map<String, Story> _byId = {for (final s in Library.stories) s.id: s};

  List<Kid> get _kids => Family.I.kids.isNotEmpty ? Family.I.myKids : [Profile.hero ?? const Kid('بطلنا', 'm')];

  /// نجوم الأسبوع (من الأحد) لمكافأة الأسبوع
  int _weekStars(Kid k) {
    final d = DateTime.now();
    final ws = DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday % 7)).millisecondsSinceEpoch;
    return Family.I.logsOf(k).where((e) => ((e['t'] as num?) ?? 0) >= ws).map((e) => e['d']).toSet().length;
  }

  static const _badges = [
    ('📖', '١٠ قصص'), ('📚', '٢٥ قصة'), ('🏅', '٥٠ قصة'), ('🏆', '١٠٠ قصة'),
    ('🔥', '٧ ليالٍ متتالية'), ('🕌', '١٠ قصص أنبياء'), ('🤲', '٧ ليالٍ أذكار'), ('🔤', '٢٠ نشاط إنجليزي'), ('🪐', 'مستكشف الفضاء'),
  ];

  List<bool> _earned(Kid k, List<Map<String, dynamic>> logs, List<Map<String, dynamic>> acts) {
    final n = logs.length;
    final pro = logs.map((e) => e['s'].toString()).where((s) => RegExp(r'^p\d').hasMatch(s)).toSet().length;
    final adk = acts.where((a) => a['a'] == 'adhkar').map((a) => DateTime.fromMillisecondsSinceEpoch((a['t'] as num).toInt()).toIso8601String().substring(0, 10)).toSet().length;
    final en = acts.where((a) => a['a'] == 'en').length, sp = acts.where((a) => a['a'] == 'space').length;
    return [n >= 10, n >= 25, n >= 50, n >= 100, Family.I.streakOf(k) >= 7, pro >= 10, adk >= 7, en >= 20, sp >= 3];
  }

  @override
  Widget build(BuildContext context) {
    final kids = _kids;
    if (_k >= kids.length) _k = 0;
    final k = kids[_k];
    final logs = Family.I.logsOf(k), acts = Family.I.actsOf(k);
    final streak = Family.I.streakOf(k);
    final days = logs.map((e) => e['d'].toString()).toSet();
    final earned = _earned(k, logs, acts);
    final now = DateTime.now();
    final week = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    const wd = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    final recent = logs.reversed.map((e) => e['s'].toString()).toSet().take(6).map((id) => _byId[id]).whereType<Story>().toList();

    return TabPage(
      title: 'أنا',
      subtitle: k.isGirl ? 'نجومك وشاراتك يا بطلة ⭐' : 'نجومك وشاراتك يا بطل ⭐',
      children: [
        if (kids.length > 1) ...[Pills(items: kids.map((e) => e.name).toList(), index: _k, onTap: (i) => setState(() => _k = i)), const SizedBox(height: 12)],
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            SizedBox(width: 110, height: 150, child: KidAvatar(kid: k)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 10),
                _Stat('⭐', '${Learn.ar(logs.length)} نجمة', 'كل قصة تخلصها نجمة'),
                _Stat('🔥', '${Learn.ar(streak)} ${streak == 1 ? 'ليلة' : 'ليالٍ'} متتالية', 'لا توقف السلسلة!'),
                _Stat('🏅', '${Learn.ar(earned.where((e) => e).length)} شارة', 'من ${Learn.ar(_badges.length)}'),
              ]),
            ),
          ]),
        ),
        if (k.id.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              onPressed: () {
                final m = Family.I.kidMaps.where((x) => x['id'] == k.id).toList();
                if (m.isNotEmpty) Navigator.of(context).push(MaterialPageRoute(builder: (_) => KidEditor(kid: m.first, mode: EditMode.self)));
              },
              icon: const Text('✏️'),
              label: Text(k.isGirl ? 'غيّري شكلك' : 'غيّر شكلك', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
          ),
        if (Family.I.fam['reward'] is Map) () {
          final r = Family.I.fam['reward'] as Map;
          final need = (r['stars'] as num?)?.toInt() ?? 5, got = _weekStars(k).clamp(0, need);
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF6E0), Color(0xFFFFE9C2)]), borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('🎁', style: TextStyle(fontSize: 34)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('مكافأة الأسبوع', style: TextStyle(fontSize: 13, color: Color(0xFFB76E00), fontWeight: FontWeight.w800)),
                      Text(r['text'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  for (var i = 0; i < need; i++) Text('⭐', style: TextStyle(fontSize: 24, color: i < got ? null : const Color(0x33000000))),
                  const Spacer(),
                  Text(got >= need ? 'كسبتها! 🎉' : '${Learn.ar(got)}/${Learn.ar(need)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
                const Text('كل ليلة تقرأ فيها قصة = نجمة ⭐ (الأسبوع يبدأ من الأحد)', style: TextStyle(fontSize: 12.5, color: C.soft)),
              ]),
            ),
          );
        }(),
        const SectionTitle('أسبوعي 🌙'),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            for (final d in week)
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: days.contains(Family.dateKey(d)) ? const Color(0xFF2C2F5C) : const Color(0xFFF0F3F9),
                    border: Family.dateKey(d) == Family.dateKey(now) ? Border.all(color: C.orange, width: 2) : null,
                  ),
                  child: Text(days.contains(Family.dateKey(d)) ? '🌙' : '', style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 4),
                Text(wd[d.weekday - 1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.soft)),
              ]),
          ]),
        ),
        const SectionTitle('أذكار النوم 🤲'),
        SoftCard(
          padding: const EdgeInsets.all(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdhkarScreen(kid: k))),
          child: const Row(children: [
            Text('🤲', style: TextStyle(fontSize: 40)),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('أذكار قبل النوم', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text('نقولها مع بعض، ونعدّها بالضغط', style: TextStyle(fontSize: 14.5, color: C.soft, fontWeight: FontWeight.w600)),
              ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: C.soft),
          ]),
        ),
        const SectionTitle('شاراتي 🏅'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: .95,
          children: [
            for (var i = 0; i < _badges.length; i++)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: earned[i] ? Colors.white : Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(20)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Opacity(opacity: earned[i] ? 1 : .3, child: Text(_badges[i].$1, style: const TextStyle(fontSize: 34))),
                  const SizedBox(height: 4),
                  Text(_badges[i].$2, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: earned[i] ? C.ink : C.soft)),
                ]),
              ),
          ],
        ),
        if (recent.isNotEmpty) ...[
          const SectionTitle('آخر قصصي 📚'),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              for (final s in recent)
                ListTile(
                  leading: const Text('⭐', style: TextStyle(fontSize: 22)),
                  title: Text(fillTemplate(s.title, k, dad: Family.I.dad, mom: Family.I.mom), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  subtitle: s.value.isNotEmpty ? Text(s.value, style: const TextStyle(color: C.soft)) : null,
                ),
            ]),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String e, t, s;
  const _Stat(this.e, this.t, this.s);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text(e, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.2)),
              Text(s, style: const TextStyle(fontSize: 12.5, color: C.soft, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );
}

/// أذكار النوم: نص الذكر + العدد بالضغط + قراءة بالصوت
class AdhkarScreen extends StatefulWidget {
  final Kid kid;
  const AdhkarScreen({super.key, required this.kid});
  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  final _pc = PageController();
  final Map<int, int> _count = {};
  int _i = 0;
  bool _logged = false;

  List<Map<String, dynamic>> get _a => Learn.adhkar;

  void _tap(int i) {
    final need = (_a[i]['n'] as num?)?.toInt() ?? 1;
    final c = (_count[i] ?? 0) + 1;
    if (c > need) return;
    HapticFeedback.lightImpact();
    setState(() => _count[i] = c);
    if (c == need) {
      HapticFeedback.mediumImpact();
      if (i + 1 < _a.length) {
        Future.delayed(const Duration(milliseconds: 500), () => _pc.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic));
      } else if (!_logged) {
        _logged = true;
        Family.I.logAct('adhkar', who: [widget.kid]);
        _done();
      }
    }
  }

  void _done() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌙🤲', style: TextStyle(fontSize: 46)),
          Text('ما شاء الله يا ${widget.kid.name}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const Text('خلّصت أذكار النوم، الله يحفظك', style: TextStyle(fontSize: 17, color: C.soft, fontWeight: FontWeight.w600)),
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
  void dispose() {
    Voice.stop();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: C.night1,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.night1, Color(0xFF2C2F5C), C.night2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, top + 8, 12, 6),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white12)),
              const SizedBox(width: 8),
              const Expanded(child: Text('أذكار النوم', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
              Text('${Learn.ar(_i + 1)}/${Learn.ar(_a.length)}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _a.length,
              onPageChanged: (i) {
                Voice.stop();
                setState(() => _i = i);
              },
              itemBuilder: (_, i) {
                final a = _a[i];
                final need = (a['n'] as num?)?.toInt() ?? 1, c = _count[i] ?? 0;
                return ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 12), children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(a['t'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.purple)),
                      const SizedBox(height: 10),
                      Text(a['x'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 2, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(16)),
                        child: Text('💡 ${a['why']}\n📚 ${a['src']}', style: const TextStyle(fontSize: 14.5, height: 1.6, color: C.soft, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => _tap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 130,
                        height: 130,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c >= need ? const Color(0xFF2FA36B) : C.orange,
                          boxShadow: [BoxShadow(color: (c >= need ? const Color(0xFF2FA36B) : C.orange).withValues(alpha: .45), blurRadius: 24)],
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(c >= need ? '✓' : Learn.ar(c), style: const TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.w800, height: 1.1)),
                          Text(c >= need ? 'تم' : 'من ${Learn.ar(need)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 16),
            child: BigButton(
              label: 'اقرأ لي',
              icon: Icons.record_voice_over_rounded,
              onTap: () => Voice.stop().then((_) => Voice.speak(_a[_i]['x'].toString(), .4)),
            ),
          ),
        ]),
      ),
    );
  }
}

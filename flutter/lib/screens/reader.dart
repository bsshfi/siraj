import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tonight_logic.dart';
import '../tts.dart';
import '../widgets/scene.dart';

/// يفتح قصة بأبطال الليلة (مع انتقال ناعم)
Future<void> openStory(BuildContext context, Story s, {List<Kid>? heroes}) {
  HapticFeedback.lightImpact();
  final hs = heroes ?? currentHeroes();
  return Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, a, __) => ReaderScreen(story: s, heroes: hs),
    transitionsBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(opacity: c, child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(c), child: child));
    },
  ));
}

/// خيارات صوت القارئ (نفس الويب: أصوات الجهاز + صوت ناعم + صوت هادي للنوم)
Future<List<Map<String, dynamic>>> voiceOptions() async {
  final vs = (await Voice.arabicVoices()).take(4).toList();
  if (vs.isEmpty) return [];
  final fem = RegExp(r'laila|layla|hoda|salma|zariyah|amira|mariam|maryam|nora|noura|sara|female|woman|ليلى|سلمى|نورة', caseSensitive: false);
  final mal = RegExp(r'majed|maged|tarik|naayf|hamed|fahed|shakir|\bmale', caseSensitive: false);
  const ic = ['🌸', '⭐', '🎈', '🦋'], nth = ['الأول', 'الثاني', 'الثالث', 'الرابع'];
  final o = <Map<String, dynamic>>[];
  for (var i = 0; i < vs.length; i++) {
    final n = vs[i]['name']!;
    o.add({'n': n, 'l': vs[i]['locale'], 'p': 1.0, 'r': .45, 't': fem.hasMatch(n) ? 'صوت امرأة' : mal.hasMatch(n) ? 'صوت رجل' : 'الصوت ${nth[i]}', 'e': fem.hasMatch(n) ? '👩' : mal.hasMatch(n) ? '👨' : ic[i]});
  }
  o.add({'n': vs[0]['name'], 'l': vs[0]['locale'], 'p': 1.35, 'r': .45, 't': 'صوت ناعم', 'e': '🧁'});
  o.add({'n': vs[0]['name'], 'l': vs[0]['locale'], 'p': 1.12, 'r': .36, 't': 'صوت هادي للنوم', 'e': '🌙'});
  return o;
}

/// يطبّق صوت الطفل المحفوظ ويرجع سرعته
Future<double> applyKidVoice(Kid? k) async {
  final v = k == null ? null : Family.I.kv[k.id];
  if (v is Map) {
    await Voice.useVoice((v['n'] ?? '').toString(), (v['l'] ?? 'ar').toString(), ((v['p'] as num?) ?? 1).toDouble());
    return ((v['r'] as num?) ?? Profile.rate).toDouble();
  }
  await Voice.resetVoice();
  return Profile.rate;
}

/// اختيار صوت القارئ للطفل
Future<void> pickVoice(BuildContext context, Kid? k) async {
  final opts = await voiceOptions();
  if (!context.mounted) return;
  if (opts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ما فيه صوت عربي على هذا الجهاز، نزّله من إعدادات تحويل النص إلى كلام')));
    return;
  }
  final cur = k == null ? null : Family.I.kv[k.id];
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🗣️', style: TextStyle(fontSize: 44)),
          Text('بأي صوت تبي القصة${k != null ? ' يا ${k.name}' : ''}؟', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('اضغط ▶️ وتسمع الصوت، وبعدين اختار اللي يعجبك', style: TextStyle(color: C.soft, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final x in opts)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cur is Map && cur['n'] == x['n'] && cur['p'] == x['p'] && cur['r'] == x['r'] ? const Color(0xFFFFF1E2) : const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                IconButton(
                  onPressed: () async {
                    await Voice.stop();
                    await Voice.useVoice(x['n'], x['l'], x['p']);
                    Voice.speak('${k != null ? 'هلا ${k.name}! ' : 'هلا! '}أنا بقرأ لك قصة الليلة.', x['r']);
                  },
                  icon: const Icon(Icons.play_circle_fill_rounded, color: C.orange, size: 34),
                ),
                Expanded(child: Text('${x['e']} ${x['t']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                FilledButton(
                  onPressed: () {
                    if (k != null) Family.I.setKidVoice(k.id, {'n': x['n'], 'l': x['l'], 'p': x['p'], 'r': x['r']});
                    Voice.stop();
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(backgroundColor: C.orange),
                  child: const Text('اختار', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          const Text('تقدر تغيّره بعدين من زر 🗣️ فوق القصة', style: TextStyle(color: C.soft, fontSize: 12.5)),
        ]),
      ),
    ),
  );
  await Voice.stop();
}

/// قارئ القصة
class ReaderScreen extends StatefulWidget {
  final Story story;
  final List<Kid> heroes;
  const ReaderScreen({super.key, required this.story, required this.heroes});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pc;
  int _i = 0;
  bool _auto = false, _logged = false, _sleep = false;
  late bool _short;
  List<int> _hist = [];
  Timer? _sleepT;
  double _rate = Profile.rate;
  final f = Family.I;

  Story get s => widget.story;
  late final List<Kid> _hs = widget.heroes.isEmpty ? const [Kid('بطلنا', 'm')] : widget.heroes;
  Kid get _hero => _hs.first;
  String _fill(String x) => fillTemplate(x, _hero, friends: _hs.sublist(1), dad: f.dad, mom: f.mom);
  int get _lvl => Tonight.level(_hs);
  List<StoryPage> get _pages => _short ? (s.youngPages ?? s.pages) : s.pages;
  int get _total => _pages.length + 2; // + سؤال قبل النوم + النهاية

  @override
  void initState() {
    super.initState();
    _short = _lvl == 1 && s.canShort;
    final r = f.resume;
    if (r != null && r['id'] == s.id && DateTime.now().millisecondsSinceEpoch - ((r['at'] as num?) ?? 0) < 12 * 3600000 && ((r['i'] as num?) ?? 0) > 0) {
      _i = ((r['i'] as num).toInt()).clamp(0, _total - 1);
      _hist = ((r['hist'] as List?) ?? []).map((x) => (x as num).toInt()).toList();
    }
    _pc = PageController(initialPage: _i);
    applyKidVoice(_hero).then((r) {
      _rate = r;
      if (f.voice && mounted) _say(_i);
    });
  }

  String _sayText(int i) {
    if (i < _pages.length) return (i == 0 ? '${_fill(s.title)}. ' : '') + _fill(_pages[i].text);
    if (i == _pages.length) return 'سؤال قبل النوم. ${_fill(s.question)}';
    return '';
  }

  Future<void> _say(int i) async {
    await Voice.stop();
    final t = _sayText(i);
    if (t.isNotEmpty) await Voice.speak(t, _rate);
  }

  void _onPage(int i) {
    setState(() => _i = i);
    _sleepT?.cancel();
    if (i > 0 && i < s.pages.length) {
      f.setResume({'id': s.id, 'i': i, 'hist': _hist, 'at': DateTime.now().millisecondsSinceEpoch});
    } else if (i >= _pages.length && f.resume?['id'] == s.id) {
      f.setResume(null);
    }
    if (i == _pages.length && !_logged) {
      _logged = true;
      Profile.markDone(s.id);
      f.logStory(s.id, _hs);
    }
    if (i == _total - 1) {
      HapticFeedback.mediumImpact();
      if (Tonight.next(_hs) == null || Tonight.next(_hs)!.id == s.id) _sleepT = Timer(const Duration(seconds: 6), () => mounted ? setState(() => _sleep = true) : null);
    }
    if (!_auto && f.voice) _say(i);
  }

  Future<void> _go(int i) async {
    if (i < 0 || i >= _total) return;
    HapticFeedback.selectionClick();
    await _pc.animateToPage(i, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  int? _next(int i) {
    if (i >= _total - 1) return null;
    if (i < _pages.length) {
      final p = _pages[i];
      if (p.choices.isNotEmpty) return null;
      if (p.isEnd) return _pages.length;
    }
    return i + 1;
  }

  void _step(int d) {
    if (d > 0) {
      final n = _next(_i);
      if (n == null) return;
      if (s.hasChoices) _hist.add(_i);
      _go(n);
    } else {
      if (s.hasChoices && _hist.isNotEmpty) {
        _go(_hist.removeLast());
      } else {
        _go(_i - 1);
      }
    }
  }

  void _choose(int to) {
    setState(() => _auto = false);
    _hist.add(_i);
    _go(to);
  }

  Future<void> _readFrom(int i) async {
    setState(() => _auto = true);
    var cur = i;
    while (mounted && _auto) {
      await _say(cur);
      if (!mounted || !_auto) break;
      final n = _next(cur);
      if (n == null || cur >= _pages.length) {
        setState(() => _auto = false);
        break;
      }
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted || !_auto) break;
      if (s.hasChoices) _hist.add(cur);
      await _go(n);
      cur = n;
    }
  }

  Future<void> _toggleAuto() async {
    HapticFeedback.lightImpact();
    if (_auto) {
      setState(() => _auto = false);
      await Voice.stop();
    } else {
      _readFrom(_i);
    }
  }

  void _toggleShort() {
    setState(() {
      _short = !_short;
      _i = 0;
      _hist = [];
    });
    _pc.jumpToPage(0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_short ? 'النسخة القصيرة ✂️' : 'النسخة الكاملة 📖')));
  }

  @override
  void dispose() {
    _auto = false;
    _sleepT?.cancel();
    Voice.stop();
    _pc.dispose();
    super.dispose();
  }

  Widget _topBtn(String e, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: Colors.white12,
          shape: const CircleBorder(),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(9), child: Text(e, style: const TextStyle(fontSize: 20)))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    final fav = f.fav.contains(s.id);
    final onQ = _i == _pages.length, onEnd = _i == _total - 1;
    final nxt = onEnd ? Tonight.next(_hs) : null;
    return Scaffold(
      backgroundColor: C.night1,
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.night1, Color(0xFF2C2F5C), C.night2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, top + 8, 12, 6),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white12)),
                const SizedBox(width: 8),
                if (!f.counts)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: const Text('🔍 معاينة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                const Spacer(),
                _topBtn(fav ? '⭐' : '☆', () {
                  HapticFeedback.lightImpact();
                  f.toggleFav(s.id);
                  setState(() {});
                  if (!fav) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضيفت للمفضلة ⭐')));
                }),
                _topBtn('🗣️', () async {
                  await pickVoice(context, _hero);
                  _rate = await applyKidVoice(_hero);
                }),
                _topBtn(f.voice ? '🔊' : '🔈', () {
                  f.setVoice(!f.voice);
                  setState(() {});
                  f.voice ? _say(_i) : Voice.stop();
                }),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (_i + 1) / _total),
                  duration: const Duration(milliseconds: 380),
                  builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: Colors.white12, color: C.orange2),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _total,
                physics: _auto || s.hasChoices ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                onPageChanged: _onPage,
                itemBuilder: (_, i) {
                  if (i < _pages.length) return _page(i);
                  if (i == _pages.length) return _question();
                  return _end();
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, bottom + 16),
              child: onEnd
                  ? Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          child: Text(nxt != null && nxt.id != s.id ? 'خلاص، ننام 😴' : 'إغلاق', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      if (nxt != null && nxt.id != s.id) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: BigButton(
                            label: 'القصة التالية ✨',
                            onTap: () {
                              Navigator.pop(context);
                              openStory(context, nxt, heroes: _hs);
                            },
                          ),
                        ),
                      ],
                    ])
                  : Row(children: [
                      _RoundBtn(icon: Icons.chevron_left_rounded, onTap: _i > 0 ? () => _step(-1) : null),
                      const SizedBox(width: 14),
                      Expanded(
                        child: onQ
                            ? BigButton(label: 'النهاية 🌙', onTap: () => _step(1))
                            : BigButton(label: _auto ? 'إيقاف الصوت' : 'اقرأ لي', icon: _auto ? Icons.pause_rounded : Icons.record_voice_over_rounded, onTap: _toggleAuto),
                      ),
                      const SizedBox(width: 14),
                      _RoundBtn(icon: Icons.chevron_right_rounded, onTap: _next(_i) != null ? () => _step(1) : null),
                    ]),
            ),
          ]),
        ),
        // الشاشة تخفت لحالها بعد "تصبح على خير"
        IgnorePointer(
          ignoring: !_sleep,
          child: AnimatedOpacity(
            opacity: _sleep ? 1 : 0,
            duration: const Duration(seconds: 2),
            child: GestureDetector(
              onTap: () => setState(() => _sleep = false),
              child: Container(color: const Color(0xF2050712), alignment: Alignment.center, child: const Text('🌙', style: TextStyle(fontSize: 60))),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _page(int i) {
    final p = _pages[i];
    final text = _fill(p.text);
    final c = Tonight.catOf(s);
    final art = SceneArt(scene: p.scene, prop: p.prop, heroes: Tonight.artHeroes(s, _hs, p), radius: 26);
    return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 12), physics: const BouncingScrollPhysics(), children: [
      if (i == 0) ...[
        Text(_fill(s.title), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 19.5, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
            child: Text('${c.$2} ${c.$3}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
          ),
        ),
        if (_lvl <= 1 && s.canShort)
          Center(
            child: TextButton(
              onPressed: _toggleShort,
              child: Text(_short ? '✂️ نسخة قصيرة للصغار · اعرض الكاملة' : '📖 النسخة الكاملة · رجّع القصيرة', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: Colors.white38)),
            ),
          ),
        const SizedBox(height: 8),
      ],
      i == 0 ? Hero(tag: 'art-${s.id}', child: art) : art,
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Text(text, style: const TextStyle(fontSize: 18, height: 1.85, fontWeight: FontWeight.w600, color: C.ink)),
      ),
      if (p.choices.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('🧭 أنت تقرّر:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        for (final ch in p.choices) Padding(padding: const EdgeInsets.only(top: 10), child: BigButton(label: _fill(ch.$1), onTap: () => _choose(ch.$2))),
      ],
    ]);
  }

  Widget _question() => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 12), children: [
        SceneArt(scene: 'night', prop: '💭', heroes: _hs, radius: 26),
        const SizedBox(height: 14),
        const Text('سؤال قبل النوم', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD86B), fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(26)),
          child: Text('💬 ${_fill(s.question)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, height: 1.7, fontWeight: FontWeight.w700, color: C.ink)),
        ),
        if (s.src.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('📚 المصدر: ${s.src}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
      ]);

  Widget _end() {
    final n = _hs.map((k) => k.name).join(' و');
    final one = _hs.length == 1;
    final nxt = Tonight.next(_hs);
    final more = nxt != null && nxt.id != s.id;
    return Center(
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(26), children: [
        Text(more ? '⭐' : '🌙', textAlign: TextAlign.center, style: const TextStyle(fontSize: 80)),
        Text(more ? 'أحسنتم!' : one ? (_hero.isGirl ? 'تصبحين على خير' : 'تصبح على خير') : 'تصبحون على خير',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(more ? '$n، الليلة لكم قصة ثانية ✨\n«${_fill(nxt.title)}»' : 'نومًا هنيئًا يا $n ✨\nوموعدنا مع حكايةٍ جديدة غدًا',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.7, fontWeight: FontWeight.w600)),
        if (!more) const Padding(padding: EdgeInsets.only(top: 10), child: Text('الشاشة بتخفت لحالها… 😴', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
        Padding(padding: const EdgeInsets.only(top: 18), child: Text('⭐ ${Learn.ar(f.monthNights(_hero))} نجوم هالشهر', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD86B), fontWeight: FontWeight.w800, fontSize: 16))),
      ]),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onTap == null ? .35 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.white12,
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, color: Colors.white, size: 30))),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../nav.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets/common.dart';
import 'story_games.dart';

/// تبويب "العب وتعلّم": الإنجليزي (حروف، كلمات، جمل) + ألعاب
class PlayLearnScreen extends StatefulWidget {
  const PlayLearnScreen({super.key});
  @override
  State<PlayLearnScreen> createState() => _PlayLearnScreenState();
}

class _PlayLearnScreenState extends State<PlayLearnScreen> {
  int _cat = 0;
  int get _sec => Nav.learn.value;

  @override
  void initState() {
    super.initState();
    Nav.learn.addListener(_r);
  }

  @override
  void dispose() {
    Nav.learn.removeListener(_r);
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  bool _logged = false;

  void _say(String t) {
    HapticFeedback.lightImpact();
    Voice.stop().then((_) => Voice.speak(t, .42, en: true));
    if (!_logged) {
      _logged = true;
      Family.I.logAct('en', s: 'browse');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabPage(
      title: 'العب وتعلّم',
      subtitle: _sec == 0 ? 'ألعاب تفكير وذكاء 🎮' : 'Let\'s learn English! 🔤',
      children: [
        Pills(items: const ['🎮 ألعاب', '🔤 حروف', '🧠 كلمات', '💬 جمل'], index: _sec, onTap: (i) => Nav.learn.value = i),
        const SizedBox(height: 14),
        if (_sec == 0) ..._games(context),
        if (_sec == 1) _letters(),
        if (_sec == 2) ..._words(),
        if (_sec == 3) ..._sentences(),
      ],
    );
  }

  Widget _letters() {
    final l = Learn.letters;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: l.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .82),
      itemBuilder: (_, i) {
        final r = l[i];
        return _Tile(
          onTap: () => _say('${r[0]}. ${r[1]}'),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${r[0]}${r[0].toLowerCase()}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: C.orange, fontFamily: 'sans-serif', height: 1.1)),
            Text(r[3], style: const TextStyle(fontSize: 32)),
            Text(r[1], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'sans-serif')),
            Text(r[2], style: const TextStyle(fontSize: 12.5, color: C.soft, fontWeight: FontWeight.w700)),
          ]),
        );
      },
    );
  }

  List<Widget> _words() {
    final w = Learn.words;
    final cats = w.keys.toList();
    if (cats.isEmpty) return [];
    if (_cat >= cats.length) _cat = 0;
    final list = w[cats[_cat]]!;
    return [
      Pills(items: cats, index: _cat, onTap: (i) => setState(() => _cat = i)),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.25),
        itemBuilder: (_, i) {
          final r = list[i];
          return _Tile(
            onTap: () => _say(r[0]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(r[2], style: const TextStyle(fontSize: 40)),
              Text(r[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'sans-serif')),
              Text(r[1], style: const TextStyle(fontSize: 14, color: C.soft, fontWeight: FontWeight.w700)),
            ]),
          );
        },
      ),
      const SectionTitle('كلمات نشوفها كثير 👀'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in Learn.sight)
          ActionChip(
            onPressed: () => _say(s),
            label: Text(s, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'sans-serif')),
            backgroundColor: Colors.white,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
      ]),
    ];
  }

  List<Widget> _sentences() {
    final hero = currentHeroes().first;
    return [
      for (final r in Learn.sentences)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Tile(
            onTap: () => _say(r[0].replaceAll('{n}', hero.name)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Text(r[2], style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(r[0].replaceAll('{n}', hero.name), style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.w800, fontFamily: 'sans-serif')),
                    ),
                    Text(r[1].replaceAll('{n}', hero.name), style: const TextStyle(fontSize: 14.5, color: C.soft, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const Icon(Icons.volume_up_rounded, color: C.orange),
              ]),
            ),
          ),
        ),
    ];
  }

  /* ---------------- الألعاب ---------------- */
  List<Widget> _games(BuildContext context) {
    final rnd = math.Random();
    void open(String title, List<QuizQ> qs, String act, {List<Color>? colors}) {
      HapticFeedback.lightImpact();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(title: title, questions: qs, colors: colors, onDone: (s, n) => Family.I.logAct(act, s: title, score: s))));
    }

    List<QuizQ> listenGame() {
      final all = Learn.words.values.expand((e) => e).toList()..shuffle(rnd);
      return all.take(8).map((w) {
        final wrong = (all.where((x) => x[0] != w[0]).toList()..shuffle(rnd)).take(3).map((x) => '${x[2]} ${x[1]}').toList();
        return QuizQ(prompt: 'اسمع الكلمة واختر معناها', answer: '${w[2]} ${w[1]}', wrong: wrong, say: w[0], sayEn: true, big: '🎧');
      }).toList();
    }

    List<QuizQ> letterGame() {
      final l = [...Learn.letters]..shuffle(rnd);
      return l.take(8).map((r) {
        final wrong = (Learn.letters.where((x) => x[0] != r[0]).toList()..shuffle(rnd)).take(3).map((x) => x[0]).toList();
        return QuizQ(prompt: 'بأي حرف تبدأ كلمة ${r[1]}؟', answer: r[0], wrong: wrong, big: r[3], say: r[1], sayEn: true);
      }).toList();
    }

    List<QuizQ> flagGame() {
      final cs = [...Learn.countries]..shuffle(rnd);
      return cs.take(8).map((c) {
        final pool = Learn.countries.where((x) => x['c'] != c['c'] && x['r'] == c['r']).toList()..shuffle(rnd);
        final more = Learn.countries.where((x) => x['c'] != c['c']).toList()..shuffle(rnd);
        final wrong = [...pool, ...more].map((x) => x['n'].toString()).toSet().take(3).toList();
        return QuizQ(prompt: 'علم أي دولة هذا؟', answer: c['n'].toString(), wrong: wrong, big: Learn.flag(c['c'].toString()));
      }).toList();
    }

    List<QuizQ> capitalGame() {
      final cs = Learn.countries.where((c) => ['gcc', 'arab', 'europe'].contains(c['r'])).toList()..shuffle(rnd);
      return cs.take(8).map((c) {
        final wrong = (Learn.countries.where((x) => x['cap'] != c['cap']).toList()..shuffle(rnd)).take(3).map((x) => x['cap'].toString()).toList();
        return QuizQ(prompt: 'وش عاصمة ${c['n']}؟', answer: c['cap'].toString(), wrong: wrong, big: Learn.flag(c['c'].toString()));
      }).toList();
    }

    List<QuizQ> storyGame() {
      final hero = currentHeroes().first;
      final read = Library.stories.where((s) => s.value.isNotEmpty).toList()..shuffle(rnd);
      final vals = Library.stories.map((s) => s.value).where((v) => v.isNotEmpty).toSet().toList();
      return read.take(6).map((s) {
        final wrong = (vals.where((v) => v != s.value).toList()..shuffle(rnd)).take(3).toList();
        return QuizQ(prompt: 'قصة «${fillTemplate(s.title, hero)}» وش علّمتنا؟', answer: s.value, wrong: wrong, big: '📖');
      }).toList();
    }

    final games = [
      ('🎧', 'اسمع واختر', 'كلمات إنجليزي بالصوت', const Color(0xFF5B8DEF), () => open('اسمع واختر', listenGame(), 'en')),
      ('🔤', 'أول حرف', 'بأي حرف تبدأ الكلمة؟', const Color(0xFFFF6B6B), () => open('أول حرف', letterGame(), 'en')),
      ('🚩', 'لعبة الأعلام', 'اعرف الدولة من علمها', const Color(0xFF2FA36B), () => open('لعبة الأعلام', flagGame(), 'flags')),
      ('🏙️', 'العواصم', 'وش عاصمة الدولة؟', const Color(0xFFF2851E), () => open('العواصم', capitalGame(), 'flags')),
      ('📖', 'قيمة القصة', 'وش علّمتنا القصة؟', const Color(0xFF8B5CF6), () => open('قيمة القصة', storyGame(), 'quiz')),
      ('🪐', 'اختبار الفضاء', 'كواكب ونجوم وقمر', const Color(0xFF3A3F78), () {
        final qs = [...Learn.spaceQuiz]..shuffle(rnd);
        open('اختبار الفضاء', qs.take(6).map((r) => QuizQ(prompt: r[0], answer: r[1], wrong: r.sublist(2), big: '🪐')).toList(), 'space',
            colors: const [C.night1, Color(0xFF3A3F78), Color(0xFF8C86C9)]);
      }),
    ];
    if (Family.I.isNight) return [const StoryGamesCard()];
    return [
      const StoryGamesCard(),
      const SectionTitle('ألعاب تفكير وذكاء 🎮'),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .95,
        children: [
          for (final g in games)
            Material(
              color: g.$4,
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: g.$5,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(18)),
                      child: Text(g.$1, style: const TextStyle(fontSize: 32)),
                    ),
                    const Spacer(),
                    Text(g.$2, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(g.$3, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: .85))),
                  ]),
                ),
              ),
            ),
        ],
      ),
    ];
  }
}

class _Tile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Tile({required this.child, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: child),
      );
}

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tonight_logic.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';

/// ألعاب القصة (play.js): تلوين المشهد، أحجية الصورة، سؤال وجواب + معرض رسوماتي
class StoryGames {
  static String? forced;
  static const sceneAr = {
    'desert': 'البر', 'sea': 'البحر', 'space': 'الفضاء', 'garden': 'الحديقة', 'home': 'البيت', 'school': 'المدرسة', 'night': 'الليل', 'mosque': 'المسجد', 'park': 'حديقة الألعاب',
    'market': 'السوق', 'road': 'الحيّ', 'mountain': 'الجبال', 'farm': 'المزرعة', 'kitchen': 'المطبخ', 'rain': 'تحت المطر', 'hills': 'الجبال', 'souq': 'السوق القديم', 'oldhome': 'البيت القديم', 'fields': 'الحقول',
  };

  /// قصة الألعاب: المختارة، أو آخر قصة قرأها الطفل، أو قصة الليلة
  static Story story() {
    if (forced != null) {
      final s = Tonight.byId(forced!);
      if (s != null) return s;
    }
    final mine = Family.I.myKids.map((k) => k.id).toSet();
    for (final e in Family.I.allLogs) {
      if (mine.isEmpty || ((e['k'] as List?) ?? []).any(mine.contains)) {
        final s = Tonight.byId(e['s'].toString());
        if (s != null) return s;
      }
    }
    final l = Tonight.list(currentHeroes());
    return l.isNotEmpty ? l.first : Library.stories.first;
  }

  static void log(String a, Story s, int score) => Family.I.logAct(a, s: s.id, score: score);

  static Future<List<Map<String, dynamic>>> gallery() async {
    try {
      final p = await SharedPreferences.getInstance();
      return ((jsonDecode(p.getString('siraj-gallery') ?? '[]') as List)).map((x) => Map<String, dynamic>.from(x as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGallery(List<Map<String, dynamic>> g) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('siraj-gallery', jsonEncode(g.take(12).toList()));
  }

  static List<QuizQ> quiz(Story st, List<Kid> hs) {
    final r = math.Random();
    final values = Library.stories.map((s) => s.value).where((v) => v.isNotEmpty && v != st.value).toSet().toList()..shuffle(r);
    final scenes = sceneAr.keys.where((k) => k != st.scene).toList()..shuffle(r);
    final emoRe = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    final emo = st.pages.map((p) => p.prop).where((e) => emoRe.hasMatch(e)).toSet().toList();
    final right = emo.isNotEmpty ? emo[r.nextInt(emo.length)] : '🌙';
    const pool = ['🚀', '🐢', '☕', '🌻', '⚽', '🐱', '🧸', '🍉', '🔦', '🏆', '📚', '🐦', '🎁', '🍦', '🚗', '🐑', '🎨', '🐝', '🔑', '🏰', '🌧️', '🦅', '🐟', '⛄'];
    final wrong = (pool.where((e) => !emo.contains(e)).toList()..shuffle(r)).take(3).toList();
    final hero = hs.first;
    return [
      QuizQ(prompt: 'وش الشي الجميل اللي تعلّمناه في «${fillTemplate(st.title, hero, friends: hs.sublist(1))}»؟', answer: st.value, wrong: values.take(3).toList(), big: '💡'),
      QuizQ(prompt: 'وين صارت أغلب أحداث القصة؟', answer: sceneAr[st.scene] ?? 'البيت', wrong: scenes.where((k) => sceneAr[k] != sceneAr[st.scene]).map((k) => sceneAr[k]!).toSet().take(3).toList(), big: '🗺️'),
      QuizQ(prompt: 'أي صورة من هذي ظهرت في القصة؟', answer: right, wrong: wrong, big: '👀'),
    ]..shuffle(r);
  }
}

/// بطاقة ألعاب القصة في تبويب العب وتعلّم
class StoryGamesCard extends StatefulWidget {
  const StoryGamesCard({super.key});
  @override
  State<StoryGamesCard> createState() => _StoryGamesCardState();
}

class _StoryGamesCardState extends State<StoryGamesCard> {
  List<Map<String, dynamic>> _gal = [];

  @override
  void initState() {
    super.initState();
    _loadGal();
  }

  Future<void> _loadGal() async {
    final g = await StoryGames.gallery();
    if (mounted) setState(() => _gal = g);
  }

  void _pick() {
    final seen = <String>{}, list = <Story>[];
    for (final e in Family.I.allLogs) {
      if (seen.add(e['s'].toString())) {
        final s = Tonight.byId(e['s'].toString());
        if (s != null) list.add(s);
      }
    }
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اقرأ قصة أولًا، وبعدها تلعب ألعابها 🌙')));
      return;
    }
    final hs = currentHeroes();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
          const Text('اختر القصة', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final s in list.take(30))
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: SizedBox(width: 90, child: SceneArt(scene: s.scene, radius: 12)),
              title: Text(fillTemplate(s.title, hs.first, friends: hs.sublist(1)), style: const TextStyle(fontWeight: FontWeight.w800)),
              onTap: () {
                StoryGames.forced = s.id;
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _open(String kind) async {
    final st = StoryGames.story(), hs = currentHeroes();
    HapticFeedback.lightImpact();
    Widget w;
    if (kind == 'quiz') {
      w = QuizScreen(title: '❓ سؤال وجواب', questions: StoryGames.quiz(st, hs), onDone: (s, _) => StoryGames.log('quiz', st, s));
    } else if (kind == 'puzzle') {
      w = PuzzleScreen(story: st, heroes: hs);
    } else {
      w = ColorScreen(story: st, heroes: hs);
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    _loadGal();
  }

  @override
  Widget build(BuildContext context) {
    if (Family.I.isNight) {
      return SoftCard(
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          const Text('😴', style: TextStyle(fontSize: 60)),
          const Text('الألعاب نامت', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const Text('الحين وقت قصة الليلة بس. الألعاب ترجع الصبح ☀️', textAlign: TextAlign.center, style: TextStyle(color: C.soft, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    final st = StoryGames.story(), hs = currentHeroes();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SoftCard(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          SizedBox(width: 130, child: SceneArt(scene: st.scene, heroes: Tonight.artHeroes(st, hs), radius: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ألعاب قصة', style: TextStyle(color: C.purple, fontWeight: FontWeight.w800, fontSize: 13)),
              Text('«${fillTemplate(st.title, hs.first, friends: hs.sublist(1), dad: Family.I.dad, mom: Family.I.mom)}»', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              TextButton(onPressed: _pick, style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact), child: const Text('اختر قصة ثانية', style: TextStyle(fontWeight: FontWeight.w800))),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        for (final g in [('color', '🎨', 'لوّن المشهد', 'بألوانك'), ('puzzle', '🧩', 'أحجية الصورة', 'رتّب القطع'), ('quiz', '❓', 'سؤال وجواب', '٣ أسئلة')])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                onTap: () => _open(g.$1),
                child: Column(children: [
                  Text(g.$2, style: const TextStyle(fontSize: 30)),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(g.$3, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
                  Text(g.$4, style: const TextStyle(color: C.soft, fontSize: 12)),
                ]),
              ),
            ),
          ),
      ]),
      if (_gal.isNotEmpty) ...[
        const SectionTitle('معرض رسوماتي 🖼️'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: [
            for (var i = 0; i < _gal.length; i++)
              SoftCard(
                padding: const EdgeInsets.all(6),
                child: Column(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: SvgPicture.string(_gal[i]['svg'].toString(), fit: BoxFit.cover))),
                  TextButton(
                    onPressed: () async {
                      _gal.removeAt(i);
                      await StoryGames.saveGallery(_gal);
                      setState(() {});
                    },
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFD33A3A), visualDensity: VisualDensity.compact),
                    child: const Text('حذف'),
                  ),
                ]),
              ),
          ],
        ),
      ],
    ]);
  }
}

/// أحجية الصورة: اضغط قطعتين تتبدّل
class PuzzleScreen extends StatefulWidget {
  final Story story;
  final List<Kid> heroes;
  const PuzzleScreen({super.key, required this.story, required this.heroes});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late int n;
  late List<int> order;
  int sel = -1, moves = 0;
  late StoryPage page;

  @override
  void initState() {
    super.initState();
    _new();
  }

  void _new() {
    final age = widget.heroes.map((k) => k.age == 0 ? 2 : k.age).fold<int>(1, math.max);
    n = age <= 1 ? 2 : age == 2 ? 3 : 4;
    page = widget.story.pages[math.min(2, widget.story.pages.length - 1)];
    final r = math.Random();
    do {
      order = List.generate(n * n, (i) => i)..shuffle(r);
    } while (_done);
    sel = -1;
    moves = 0;
  }

  bool get _done => [for (var i = 0; i < order.length; i++) order[i] == i].every((x) => x);

  void _tap(int i) {
    if (_done) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (sel < 0) {
        sel = i;
      } else {
        final t = order[sel];
        order[sel] = order[i];
        order[i] = t;
        sel = -1;
        moves++;
        if (_done) {
          HapticFeedback.mediumImpact();
          StoryGames.log('puzzle', widget.story, moves);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final art = SceneArt(scene: page.scene, prop: page.prop, heroes: Tonight.artHeroes(widget.story, widget.heroes, page), radius: 0);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: ListView(padding: EdgeInsets.fromLTRB(16, top + 8, 16, 30), children: [
          Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
            const SizedBox(width: 10),
            const Text('🧩 أحجية الصورة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
          ]),
          const SizedBox(height: 6),
          Text(_done ? '' : 'اضغط قطعتين عشان تبدّلهم', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34406E), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 400 / 260,
              child: LayoutBuilder(builder: (_, box) {
                final w = box.maxWidth, h = box.maxHeight, tw = w / n, th = h / n;
                return Stack(children: [
                  for (var i = 0; i < order.length; i++)
                    Positioned(
                      left: (i % n) * tw,
                      top: (i ~/ n) * th,
                      width: tw,
                      height: th,
                      child: GestureDetector(
                        onTap: () => _tap(i),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: i == sel ? C.orange : Colors.white, width: i == sel ? 3 : (_done ? 0 : 1))),
                          child: ClipRect(
                            child: OverflowBox(
                              maxWidth: w,
                              maxHeight: h,
                              alignment: Alignment(n == 1 ? 0 : -1 + 2 * (order[i] % n) / (n - 1), n == 1 ? 0 : -1 + 2 * (order[i] ~/ n) / (n - 1)),
                              child: SizedBox(width: w, height: h, child: art),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 16),
          if (_done) ...[
            Text('🎉 أحسنت! رتّبت الصورة في ${Learn.ar(moves)} حركة', textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
            const SizedBox(height: 12),
            BigButton(label: 'أحجية ثانية 🔁', onTap: () => setState(_new)),
          ],
        ]),
      ),
    );
  }
}

/// تلوين المشهد: نفس رسمة القصة بخطوط بس، ويلوّنها الطفل بلمسة (لوحة رسم داخل التطبيق)
class ColorScreen extends StatefulWidget {
  final Story story;
  final List<Kid> heroes;
  const ColorScreen({super.key, required this.story, required this.heroes});
  @override
  State<ColorScreen> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  static const pal = ['#FF6B6B', '#FF9F1C', '#FFD93D', '#4CD97B', '#2FA4E7', '#9B6BF2', '#FF7AB6', '#8B5A2B', '#F1C08F', '#2B2350', '#9BE1FF', '#ffffff'];
  String paint = pal[0];
  WebViewController? _c;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final art = await rootBundle.loadString('assets/js/art.js');
    final st = widget.story;
    final page = st.pages[math.min(1, st.pages.length - 1)];
    final kids = jsonEncode(Tonight.artHeroes(st, widget.heroes, page).map((k) => {'name': k.name, 'g': k.gender, 'av': k.av ?? {}}).toList());
    final html = '''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<style>html,body{margin:0;background:#fff}#box svg{width:100%;height:auto;display:block}.paintable{cursor:pointer}</style></head>
<body><div id="box"></div><script>$art</script><script>
var paint='${pal[0]}';
function lineArt(svg){var d=new DOMParser().parseFromString(svg,'image/svg+xml'),r=d.documentElement;
r.querySelectorAll('defs,text,animate,animateTransform').forEach(function(n){n.remove()});
r.querySelectorAll('rect,circle,ellipse,path,polygon').forEach(function(n){var f=n.getAttribute('fill');
if(f==='none'){n.setAttribute('stroke','#3B3B5C');return}
n.setAttribute('fill','#ffffff');n.removeAttribute('opacity');n.setAttribute('stroke','#3B3B5C');n.setAttribute('stroke-width','1.2');n.setAttribute('class','paintable')});
r.setAttribute('xmlns','http://www.w3.org/2000/svg');return new XMLSerializer().serializeToString(r)}
var kids=$kids;kids.forEach(function(k){if(!k.av||!Object.keys(k.av).length)k.av=ART.DEFAULTS[k.g==='f'?'f':'m']});
document.getElementById('box').innerHTML=lineArt(ART.page(${jsonEncode(page.scene)},'',kids));
document.getElementById('box').addEventListener('click',function(e){var t=e.target.closest('.paintable');if(t)t.setAttribute('fill',paint)});
</script></body></html>''';
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadHtmlString(html);
    if (mounted) setState(() => _c = c);
  }

  Future<void> _save() async {
    if (_c == null) return;
    try {
      var r = await _c!.runJavaScriptReturningResult('document.getElementById("box").innerHTML');
      var s = r is String ? r : r.toString();
      if (s.startsWith('"')) s = jsonDecode(s) as String;
      final g = await StoryGames.gallery();
      g.insert(0, {'svg': s, 't': DateTime.now().millisecondsSinceEpoch, 's': widget.story.id});
      await StoryGames.saveGallery(g);
      StoryGames.log('color', widget.story, 0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انحفظت في معرضك 🖼️')));
      Navigator.pop(context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: C.skyPale,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, top + 8, 14, 8),
          child: Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            const SizedBox(width: 10),
            const Expanded(child: Text('🎨 لوّن المشهد', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(aspectRatio: 400 / 260, child: _c == null ? const Center(child: CircularProgressIndicator()) : WebViewWidget(controller: _c!)),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            for (final p in pal)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => paint = p);
                  _c?.runJavaScript("paint='$p'");
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hexColor(p),
                    shape: BoxShape.circle,
                    border: Border.all(color: p == paint ? C.ink : const Color(0xFFDDE3EE), width: p == paint ? 4 : 1.5),
                  ),
                ),
              ),
          ]),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
          child: BigButton(label: 'حفظ في معرضي 🖼️', onTap: _save),
        ),
      ]),
    );
  }
}

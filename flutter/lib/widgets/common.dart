import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../learn.dart';
import '../theme.dart';
import '../tts.dart';

/// صفحة تبويب: سماء متدرّجة + عنوان + محتوى قابل للتمرير
class TabPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final List<Color>? colors;
  const TabPage({super.key, required this.title, this.subtitle, this.trailing, required this.children, this.colors});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors ?? const [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0, .3, .62]),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, top + 14, 16, 120 + bottom),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF26305A), height: 1.1)),
                  if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF34406E))),
                ]),
              ),
              if (trailing != null) trailing!,
            ]),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// أزرار اختيار القسم (حبوب)
class Pills extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onTap;
  const Pills({super.key, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == index;
          return GestureDetector(
            onTap: () {
              if (on) return;
              HapticFeedback.selectionClick();
              onTap(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? C.orange : Colors.white.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(23),
                boxShadow: on ? const [BoxShadow(color: Color(0x40F2851E), blurRadius: 12, offset: Offset(0, 4))] : null,
              ),
              child: Text(items[i], style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: on ? Colors.white : C.ink)),
            ),
          );
        },
      ),
    );
  }
}

/// عنوان قسم صغير
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(6, 18, 6, 10), child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF26305A))));
}

/// زر صوت صغير
class SpeakButton extends StatelessWidget {
  final String text;
  final bool en;
  final double size;
  const SpeakButton(this.text, {super.key, this.en = false, this.size = 22});
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        onPressed: () {
          HapticFeedback.lightImpact();
          Voice.stop().then((_) => Voice.speak(text, en ? .42 : .45, en: en));
        },
        icon: Icon(Icons.volume_up_rounded, size: size, color: C.orange),
        style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFF1E2)),
      );
}

/// سؤال اختيار من متعدد — يخلط الخيارات، يلوّن الصح والخطأ، ويرجع النتيجة
class QuizQ {
  final String prompt;
  final String? big; // إيموجي أو علم كبير فوق السؤال
  final String answer;
  final List<String> wrong;
  final String? say; // نص ينقرأ بالصوت (اسمع واختر)
  final bool sayEn;
  const QuizQ({required this.prompt, required this.answer, required this.wrong, this.big, this.say, this.sayEn = false});
}

class QuizScreen extends StatefulWidget {
  final String title;
  final List<QuizQ> questions;
  final void Function(int score, int total)? onDone;
  final List<Color>? colors;
  const QuizScreen({super.key, required this.title, required this.questions, this.onDone, this.colors});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _i = 0, _score = 0;
  String? _picked;
  late List<String> _opts;
  bool _done = false;

  QuizQ get q => widget.questions[_i];

  @override
  void initState() {
    super.initState();
    _prep();
  }

  void _prep() {
    _opts = [q.answer, ...q.wrong.take(3)]..shuffle();
    _picked = null;
    if (q.say != null) Future.delayed(const Duration(milliseconds: 350), () => Voice.speak(q.say!, q.sayEn ? .42 : .45, en: q.sayEn));
  }

  void _pick(String o) {
    if (_picked != null) return;
    final ok = o == q.answer;
    ok ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _picked = o;
      if (ok) _score++;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_i + 1 >= widget.questions.length) {
        setState(() => _done = true);
        widget.onDone?.call(_score, widget.questions.length);
      } else {
        setState(() {
          _i++;
          _prep();
        });
      }
    });
  }

  @override
  void dispose() {
    Voice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final n = widget.questions.length;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: widget.colors ?? const [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: ListView(padding: EdgeInsets.fromLTRB(18, top + 10, 18, 30), children: [
          Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF26305A)))),
            if (!_done) Text('${Learn.ar(_i + 1)}/${Learn.ar(n)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF34406E))),
          ]),
          const SizedBox(height: 14),
          if (_done)
            SoftCard(
              padding: const EdgeInsets.all(26),
              child: Column(children: [
                Text(_score == n ? '🏆' : _score >= n / 2 ? '🌟' : '💪', style: const TextStyle(fontSize: 64)),
                Text(_score == n ? 'ممتاز! كلها صح' : _score >= n / 2 ? 'أحسنت!' : 'محاولة حلوة!', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('جاوبت ${Learn.ar(_score)} من ${Learn.ar(n)}', style: const TextStyle(fontSize: 18, color: C.soft, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                BigButton(label: 'تمام', onTap: () => Navigator.pop(context)),
              ]),
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(key: ValueKey(_i), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    if (q.big != null) Text(q.big!, style: const TextStyle(fontSize: 74, height: 1.2)),
                    Text(q.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.5)),
                    if (q.say != null) ...[const SizedBox(height: 6), SpeakButton(q.say!, en: q.sayEn, size: 30)],
                  ]),
                ),
                const SizedBox(height: 8),
                for (final o in _opts)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _OptionTile(
                      text: o,
                      state: _picked == null ? 0 : o == q.answer ? 1 : o == _picked ? 2 : 3,
                      onTap: () => _pick(o),
                    ),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}


class _OptionTile extends StatelessWidget {
  final String text;
  final int state; // 0 عادي، 1 صح، 2 خطأ، 3 باهت
  final VoidCallback onTap;
  const _OptionTile({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = state == 1 ? const Color(0xFFDDF7E8) : state == 2 ? const Color(0xFFFFE3E3) : Colors.white;
    final bd = state == 1 ? const Color(0xFF2FA36B) : state == 2 ? const Color(0xFFE5484D) : Colors.white;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: state == 3 ? .5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: bd, width: 2.5)),
            child: Row(children: [
              Expanded(child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              if (state == 1) const Icon(Icons.check_circle_rounded, color: Color(0xFF2FA36B)),
              if (state == 2) const Icon(Icons.cancel_rounded, color: Color(0xFFE5484D)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// رسمة القمر حسب عمره (نفس moonSVG في الويب)
class MoonPainter extends CustomPainter {
  final double age;
  const MoonPainter(this.age);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    const c = Offset(50, 50), r = 44.0;
    canvas.drawCircle(c, r + 8, Paint()..shader = const RadialGradient(colors: [Color(0x59FFF1B8), Color(0x00FFF1B8)], stops: [.6, 1]).createShader(Rect.fromCircle(center: c, radius: r + 8)));
    canvas.drawCircle(c, r, Paint()..shader = const RadialGradient(center: Alignment(-.1, -.2), colors: [Color(0xFF454C72), Color(0xFF262B47)]).createShader(Rect.fromCircle(center: c, radius: r)));
    final p = age / 29.530588853, k = math.cos(2 * math.pi * p), rx = k.abs() * r, wax = p < .5;
    final path = Path()..moveTo(50, 50 - r);
    path.arcToPoint(const Offset(50, 50 + r), radius: const Radius.circular(r), clockwise: wax);
    final sweep = wax ? (k > 0 ? false : true) : (k > 0 ? true : false);
    path.arcToPoint(const Offset(50, 50 - r), radius: Radius.elliptical(math.max(rx, .01), r), clockwise: sweep);
    path.close();
    canvas.drawPath(path, Paint()..shader = const RadialGradient(center: Alignment(-.16, -.24), radius: .72, colors: [Color(0xFFFFFBEA), Color(0xFFF7E7B0), Color(0xFFE6CD84)], stops: [0, .6, 1]).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.save();
    canvas.clipPath(path);
    final cr = Paint()..color = const Color(0x40B89A55);
    for (final x in const [[36, 34, 7], [62, 56, 9], [44, 66, 5.5], [66, 32, 4], [28, 54, 4.5], [54, 78, 3.5], [74, 70, 3], [48, 24, 3]]) {
      canvas.drawCircle(Offset(x[0].toDouble(), x[1].toDouble()), x[2].toDouble(), cr);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MoonPainter old) => old.age != age;
}

/// كوكب: كرة بتدرّج لونين (+ حلقات لزحل)
class PlanetBall extends StatelessWidget {
  final List<Color> colors;
  final double size;
  final bool ring;
  const PlanetBall({super.key, required this.colors, this.size = 60, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final ball = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.35, -.35), colors: colors),
        boxShadow: [BoxShadow(color: colors.last.withValues(alpha: .35), blurRadius: size / 4)],
      ),
    );
    if (!ring) return ball;
    return SizedBox(
      width: size * 1.7,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        ball,
        Transform.rotate(
          angle: -.35,
          child: Container(
            width: size * 1.65,
            height: size * .38,
            decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.elliptical(size, size * .2)), border: Border.all(color: const Color(0xCCE8D3A0), width: size * .07)),
          ),
        ),
      ]),
    );
  }
}

Color hexColor(String h) => Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));

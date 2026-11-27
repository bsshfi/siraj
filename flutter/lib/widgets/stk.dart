import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// أيقونات الملصقات — نفس رسومات سراج الويب (stickers.js + أيقونات الشريط السفلي)، تنصدّر لـ assets/data/icons.json
class Stk {
  static Map<String, String> _m = {};
  static Future<void> load() async {
    try {
      _m = Map<String, String>.from(jsonDecode(await rootBundle.loadString('assets/data/icons.json')) as Map);
    } catch (_) {}
  }

  static String? svg(String k, {String? day}) {
    final s = _m[k];
    return s != null && day != null ? s.replaceAll('§D§', day) : s;
  }
}

/// أيقونة ملصق. [outline] يرسم حدّ أبيض حولها مثل ملصقات الويب
class StkIcon extends StatelessWidget {
  final String name;
  final double size;
  final String? day;
  final double outline;
  const StkIcon(this.name, {super.key, this.size = 24, this.day, this.outline = 0});

  @override
  Widget build(BuildContext context) {
    final s = Stk.svg(name, day: day);
    if (s == null) return SizedBox(width: size, height: size);
    final pic = SvgPicture.string(s, width: size, height: size);
    if (outline <= 0) return pic;
    final w = SvgPicture.string(s, width: size, height: size, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        for (final o in [Offset(outline, 0), Offset(-outline, 0), Offset(0, outline), Offset(0, -outline)]) Transform.translate(offset: o, child: w),
        pic,
      ]),
    );
  }
}

/// خلفية السماء الثابتة لكل الصفحات — نفس تدرّج body في الويب + الغيوم الفاتحة تحت
class SkyBg extends StatelessWidget {
  final Widget child;
  const SkyBg({super.key, required this.child});

  static const gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4FA3EC), Color(0xFF7CBDF3), Color(0xFFA9D3F7), Color(0xFFD6EAFB), Color(0xFFEEF2FD), Color(0xFFF4EEFB)],
    stops: [0, .2, .4, .62, .82, 1],
  );

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: gradient))),
      const Positioned.fill(child: CustomPaint(painter: _BottomClouds())),
      Positioned.fill(child: child),
    ]);
  }
}

class _BottomClouds extends CustomPainter {
  const _BottomClouds();
  @override
  void paint(Canvas c, Size s) {
    final h = s.height * .42, w = s.width;
    // radial-gradient(120% 60% at 15% 100%, #C8E2F7 0 40%) و (100% 50% at 90% 100%, #D9ECFA 0 45%)
    c.drawOval(Rect.fromCenter(center: Offset(w * .15, s.height), width: 2 * w * 1.2 * .4, height: 2 * h * .6 * .4), Paint()..color = const Color(0xFFC8E2F7));
    c.drawOval(Rect.fromCenter(center: Offset(w * .9, s.height), width: 2 * w * .45, height: 2 * h * .5 * .45), Paint()..color = const Color(0xFFD9ECFA));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// نجوم تلمع وغيمة خلف رأس الرئيسية (skyfx في الويب)
class SkyFx extends StatefulWidget {
  final double height;
  const SkyFx({super.key, this.height = 330});
  @override
  State<SkyFx> createState() => _SkyFxState();
}

class _SkyFxState extends State<SkyFx> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  static const _st = [[8, 14, 16], [30, 6, 10], [55, 18, 9], [72, 8, 14], [90, 20, 11], [18, 40, 8], [62, 36, 10], [84, 44, 8]];
  static const _star = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><path d="M10 0l2.6 6.4L19 7.6l-4.8 4.3L15.5 19 10 15.6 4.5 19l1.3-7.1L1 7.6l6.4-1.2z" fill="#FFE27A"/></svg>';
  static const _cloud =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 90" preserveAspectRatio="none"><g fill="#fff" opacity=".85"><ellipse cx="40" cy="70" rx="70" ry="30"/><ellipse cx="120" cy="80" rx="70" ry="24"/><ellipse cx="330" cy="72" rx="80" ry="30"/><ellipse cx="400" cy="60" rx="50" ry="30"/></g><g fill="#fff" opacity=".55"><ellipse cx="230" cy="84" rx="90" ry="18"/></g></svg>';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = widget.height;
      return ShaderMask(
        shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.black, Colors.transparent], stops: [0, .7, 1]).createShader(r),
        blendMode: BlendMode.dstIn,
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 0, right: 0, bottom: 40, height: 90, child: Opacity(opacity: .75, child: SvgPicture.string(_cloud, fit: BoxFit.fill))),
            for (var i = 0; i < _st.length; i++)
              Positioned(
                left: w * _st[i][0] / 100,
                top: h * _st[i][1] / 100,
                width: _st[i][2].toDouble(),
                height: _st[i][2].toDouble(),
                child: still
                    ? SvgPicture.string(_star)
                    : AnimatedBuilder(
                        animation: _c,
                        builder: (_, child) {
                          // @keyframes spk: 0/100% scale .6 شفافية .5 — 50% scale 1.1 شفافية 1 (كل نجمة متأخرة -.7 ث)
                          var t = (_c.value + i * .7 / 2.8) % 1;
                          t = Curves.easeInOut.transform(t < .5 ? t * 2 : (1 - t) * 2);
                          return Opacity(opacity: .5 + .5 * t, child: Transform.scale(scale: .6 + .5 * t, child: child));
                        },
                        child: SvgPicture.string(_star),
                      ),
              ),
          ]),
        ),
      );
    });
  }
}

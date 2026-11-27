import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'stk.dart';

/// القمر اللي يقرأ كتاب ويجلس على غيمة (moonReader في سراج الويب).
/// ثلاث طبقات: التوهّج خلف، القمر نفسه يتمايل (mrbob)، والغيمة والكتاب قدّام
class MoonReader extends StatefulWidget {
  final double width;
  const MoonReader({super.key, this.width = 158});
  @override
  State<MoonReader> createState() => _MoonReaderState();
}

class _MoonReaderState extends State<MoonReader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width, h = w * 190 / 220, k = w / 220;
    Widget layer(String n) {
      final s = Stk.svg(n);
      return s == null ? const SizedBox() : SvgPicture.string(s, width: w, height: h);
    }

    final face = layer('moonFace');
    return SizedBox(
      width: w,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        layer('moonBack'),
        if (MediaQuery.of(context).disableAnimations)
          face
        else
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              // 50%{transform:translateY(-3px) rotate(-1.5deg)} حول (112, 80)
              final t = Curves.easeInOut.transform(_c.value);
              return Transform(
                origin: Offset(112 * k, 80 * k),
                transform: Matrix4.translationValues(0, -3 * k * t, 0)..rotateZ(-0.0262 * t),
                child: child,
              );
            },
            child: face,
          ),
        layer('moonFront'),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// القمر اللي يقرأ كتاب ويجلس على غيمة (نفس moonReader في سراج الويب)
const _svg = r'''<svg viewBox="0 0 220 190"><defs>
      <radialGradient id="mrGlow" cx="50%" cy="45%" r="50%"><stop offset="0" stop-color="#FFF6C8" stop-opacity=".95"/><stop offset=".55" stop-color="#FFE9A0" stop-opacity=".35"/><stop offset="1" stop-color="#FFE9A0" stop-opacity="0"/></radialGradient>
      <radialGradient id="mrMoon" cx="38%" cy="32%" r="70%"><stop offset="0" stop-color="#FFF3B8"/><stop offset=".6" stop-color="#FFDF72"/><stop offset="1" stop-color="#F4C24A"/></radialGradient>
      <linearGradient id="mrBook" x1="0" x2="1"><stop offset="0" stop-color="#6D45D9"/><stop offset="1" stop-color="#8E5BEA"/></linearGradient></defs>
      <circle cx="112" cy="84" r="92" fill="url(#mrGlow)"/>
      <g>
        <circle cx="112" cy="80" r="62" fill="url(#mrMoon)"/>
        <g fill="#F7D35E" opacity=".75"><circle cx="78" cy="58" r="9"/><circle cx="150" cy="56" r="7"/><circle cx="140" cy="104" r="6"/><circle cx="74" cy="100" r="5"/><circle cx="160" cy="84" r="4"/></g>
        <path d="M88 74q8-9 16 0M122 74q8-9 16 0" stroke="#3B2A20" stroke-width="4.2" fill="none" stroke-linecap="round"/>
        <ellipse cx="84" cy="88" rx="9" ry="6" fill="#FF9AA8" opacity=".75"/><ellipse cx="142" cy="88" rx="9" ry="6" fill="#FF9AA8" opacity=".75"/>
        <path d="M100 88q13 16 26 0z" fill="#B23A48"/><path d="M106 95q7 5 14 0q-7-5-14 0z" fill="#FF7A8A"/>
        <path d="M150 32l2.5 5.5 6 .6-4.5 4 1.3 6-5.3-3-5.3 3 1.3-6-4.5-4 6-.6z" fill="#fff" opacity=".9"/>
      </g>
      <g><path d="M40 150c-6-18 4-34 20-36-2 16-8 28-20 36z" fill="#4CAF50"/><path d="M40 150c4-12 10-22 20-36" stroke="#2E7D32" stroke-width="2" fill="none"/><path d="M52 156c2-16 16-24 30-20-6 12-16 20-30 20z" fill="#66BB6A"/></g>
      <g fill="#fff"><ellipse cx="66" cy="160" rx="40" ry="18"/><ellipse cx="112" cy="150" rx="46" ry="24"/><ellipse cx="164" cy="160" rx="40" ry="18"/><ellipse cx="112" cy="168" rx="80" ry="16"/></g>
      <g fill="#E4DDF9" opacity=".85"><ellipse cx="112" cy="174" rx="78" ry="8"/></g>
      <g transform="translate(4 14) scale(.96)">
        <path d="M80 128l32 6 32-6v-30l-32 6-32-6z" fill="url(#mrBook)"/>
        <path d="M84 125l28 5V104l-28-5z" fill="#fff"/><path d="M140 125l-28 5V104l28-5z" fill="#FBF7FF"/>
        <path d="M89 106l18 3.4M89 112l18 3.4M89 118l18 3.4" stroke="#D5CBEF" stroke-width="1.6"/>
        <circle cx="126" cy="114" r="6" fill="#E85A8A" opacity=".85"/>
        <ellipse cx="80" cy="114" rx="9" ry="10" fill="#FFD966"/><ellipse cx="144" cy="114" rx="9" ry="10" fill="#FFD966"/>
      </g>
      <g fill="#FFE27A"><path d="M34 40l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"/><path d="M196 110l1.6 4 4 1.6-4 1.6-1.6 4-1.6-4-4-1.6 4-1.6z"/><path d="M190 24l1.4 3.4 3.4 1.4-3.4 1.4-1.4 3.4-1.4-3.4-3.4-1.4 3.4-1.4z"/></g>
    </svg>''';

class MoonReader extends StatefulWidget {
  final double size;
  const MoonReader({super.key, this.size = 92});
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
    final w = widget.size, h = w * 190 / 220;
    final pic = SvgPicture.string(_svg, width: w, height: h);
    if (MediaQuery.of(context).disableAnimations) return pic;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(offset: Offset(0, -3 * t), child: Transform.rotate(angle: -0.026 * t, child: child));
      },
      child: pic,
    );
  }
}

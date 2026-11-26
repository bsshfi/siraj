import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../family.dart';
import '../learn.dart';
import '../theme.dart';

/// رمز وليّ الأمر (٤ أرقام) — يحمي الإعدادات من الصغار.
/// لو ما فيه رمز (نسخة بدون عائلة) نسأل سؤال ضرب بدلها (سياسة العائلات في Google Play)
Future<bool> askPin(BuildContext context, {String hint = 'للإعدادات والمتابعة'}) async {
  final pin = Family.I.pin;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (_) => pin.length == 4 ? _PinPad(pin: pin, hint: hint) : const _MathGate(),
  );
  return ok == true;
}

class _PinPad extends StatefulWidget {
  final String pin, hint;
  const _PinPad({required this.pin, required this.hint});
  @override
  State<_PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<_PinPad> with SingleTickerProviderStateMixin {
  String _buf = '';
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _key(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == '⌫') {
        if (_buf.isNotEmpty) _buf = _buf.substring(0, _buf.length - 1);
      } else if (_buf.length < 4) {
        _buf += k;
      }
    });
    if (_buf.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (_buf == widget.pin) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context, true);
        } else {
          HapticFeedback.heavyImpact();
          _shake.forward(from: 0);
          setState(() => _buf = '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 18, 28, bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFFFF1E2), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.lock_rounded, color: C.orange, size: 34)),
        const SizedBox(height: 8),
        const Text('رمز وليّ الأمر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(widget.hint, style: const TextStyle(color: C.soft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _shake,
          builder: (_, child) => Transform.translate(offset: Offset(math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value), 0), child: child),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < _buf.length ? C.orange : const Color(0xFFE3E8F1)),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Directionality(
          textDirection: TextDirection.ltr,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 14,
            childAspectRatio: 1.7,
            children: [
              for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'])
                k.isEmpty
                    ? const SizedBox()
                    : Material(
                        color: const Color(0xFFF4F7FC),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _key(k),
                          child: Center(child: k == '⌫' ? const Icon(Icons.backspace_rounded, color: C.soft) : Text(k, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
                        ),
                      ),
            ],
          ),
        ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(fontSize: 16, color: C.soft, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _MathGate extends StatefulWidget {
  const _MathGate();
  @override
  State<_MathGate> createState() => _MathGateState();
}

class _MathGateState extends State<_MathGate> {
  late int _a, _b;
  late List<int> _o;

  @override
  void initState() {
    super.initState();
    _new();
  }

  void _new() {
    final r = math.Random();
    _a = 6 + r.nextInt(4);
    _b = 6 + r.nextInt(4);
    final s = <int>{_a * _b};
    while (s.length < 4) {
      s.add(_a * _b + r.nextInt(17) - 8);
    }
    _o = s.toList()..shuffle(r);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('👨‍👩‍👧', style: TextStyle(fontSize: 48)),
        const Text('للكبار فقط — جاوب عشان تدخل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Directionality(textDirection: TextDirection.ltr, child: Text('${Learn.ar(_a)} × ${Learn.ar(_b)} = ؟', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.purple))),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final o in _o)
              Material(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    if (o == _a * _b) {
                      Navigator.pop(context, true);
                    } else {
                      HapticFeedback.heavyImpact();
                      setState(_new);
                    }
                  },
                  child: Center(child: Text(Learn.ar(o), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

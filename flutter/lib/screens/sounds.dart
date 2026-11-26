import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../learn.dart';
import '../theme.dart';

/// أصوات النوم (مطر، موج، صحراء، هدوء) + مؤقت يطفي بهدوء — نفس night.js
class Sounds extends ChangeNotifier {
  static final Sounds I = Sounds._();
  Sounds._();

  static const list = [('rain', '🌧️', 'مطر'), ('waves', '🌊', 'موج البحر'), ('desert', '🏜️', 'ليل الصحراء'), ('fan', '🌀', 'هدوء')];
  final AudioPlayer _p = AudioPlayer();
  String? cur;
  DateTime? endAt;
  Timer? _t, _fade;

  String get label => list.firstWhere((x) => x.$1 == cur, orElse: () => ('', '🎵', '')).$3;
  String get icon => list.firstWhere((x) => x.$1 == cur, orElse: () => ('', '🎵', '')).$2;

  Future<void> play(String kind) async {
    await stop(notify: false);
    cur = kind;
    notifyListeners();
    try {
      await _p.setReleaseMode(ReleaseMode.loop);
      await _p.setVolume(0);
      await _p.play(AssetSource('sounds/$kind.wav'));
      _ramp(0, .9, const Duration(seconds: 2));
    } catch (_) {}
  }

  void _ramp(double from, double to, Duration d, [VoidCallback? done]) {
    _fade?.cancel();
    const steps = 20;
    var i = 0;
    _fade = Timer.periodic(Duration(milliseconds: d.inMilliseconds ~/ steps), (t) {
      i++;
      _p.setVolume(from + (to - from) * i / steps);
      if (i >= steps) {
        t.cancel();
        done?.call();
      }
    });
  }

  void setTimer(int min) {
    _t?.cancel();
    endAt = DateTime.now().add(Duration(minutes: min));
    _t = Timer(Duration(minutes: min) - const Duration(seconds: 8), () => _ramp(.9, 0, const Duration(seconds: 8), stop));
    notifyListeners();
  }

  Future<void> stop({bool notify = true}) async {
    _t?.cancel();
    _fade?.cancel();
    endAt = null;
    cur = null;
    try {
      await _p.stop();
    } catch (_) {}
    if (notify) notifyListeners();
  }
}

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});
  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  Timer? _tick;
  @override
  void initState() {
    super.initState();
    Sounds.I.addListener(_r);
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => _r());
  }

  @override
  void dispose() {
    Sounds.I.removeListener(_r);
    _tick?.cancel();
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = Sounds.I;
    final top = MediaQuery.of(context).padding.top;
    final left = s.endAt != null && s.cur != null ? (s.endAt!.difference(DateTime.now()).inSeconds / 60).ceil().clamp(0, 999) : 0;
    return Scaffold(
      backgroundColor: C.night1,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF12153A), C.night1, C.night2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: ListView(padding: EdgeInsets.fromLTRB(18, top + 8, 18, 30), children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white12)),
          ),
          const SizedBox(height: 10),
          const Text('🌙', textAlign: TextAlign.center, style: TextStyle(fontSize: 70)),
          const Text('أصوات النوم', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const Text('اختر صوت، وغمّض عيونك… ويطفي لحاله 😴', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              for (final x in Sounds.list)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    s.cur == x.$1 ? s.stop() : s.play(x.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: s.cur == x.$1 ? C.orange : Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(x.$2, style: const TextStyle(fontSize: 44)),
                      Text(x.$3, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('يطفي بعد:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final m in [10, 20, 30])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text('${Learn.ar(m)} د', style: const TextStyle(fontWeight: FontWeight.w800)),
                  selected: s.endAt != null && s.cur != null && (s.endAt!.difference(DateTime.now()).inSeconds / 60 - m).abs() < 1,
                  onSelected: s.cur == null ? null : (_) => s.setTimer(m),
                  selectedColor: C.orange,
                  showCheckmark: false,
                ),
              ),
          ]),
          if (s.cur != null) ...[
            const SizedBox(height: 16),
            Text(left > 0 ? '⏳ باقي ${Learn.ar(left)} دقيقة' : '🎵 شغّال', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: s.stop,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('⏹ إيقاف', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ],
        ]),
      ),
    );
  }
}

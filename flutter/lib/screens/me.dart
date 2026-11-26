import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tts.dart';

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
          Text('ما شاء الله يا ${widget.kid.name}!', style: const TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800)),
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
                      Text(a['t'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.purple)),
                      const SizedBox(height: 10),
                      Text(a['x'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 2, fontWeight: FontWeight.w600)),
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
                          Text(c >= need ? '✓' : Learn.ar(c), style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w800, height: 1.1)),
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

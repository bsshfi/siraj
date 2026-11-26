import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../avatars.dart';
import '../family.dart';
import '../sync.dart';
import '../theme.dart';

/// خلفية سماء سراج
class SkyBackground extends StatelessWidget {
  final Widget child;
  const SkyBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .4, .8]),
        ),
        child: child,
      );
}

/// ربط الجهاز برمز العائلة
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});
  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: const TextStyle(fontFamily: 'Baloo', fontSize: 16))));

  Future<void> _paste() async {
    final d = await Clipboard.getData('text/plain');
    final t = d?.text ?? '';
    final c = Sync.norm(t);
    if (c.isEmpty) return _toast('ما لقيت رمز صحيح في المنسوخ');
    setState(() => _code.text = c);
    HapticFeedback.selectionClick();
  }

  Future<void> _join() async {
    if (_busy) return;
    setState(() => _busy = true);
    final err = await Family.I.join(_code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      HapticFeedback.heavyImpact();
      return _toast(err);
    }
    HapticFeedback.mediumImpact();
    final kids = Family.I.kids;
    if (kids.length > 1) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhoScreen(first: true)));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            ),
            const SizedBox(height: 8),
            const Text('🔑', textAlign: TextAlign.center, style: TextStyle(fontSize: 54)),
            const Text('ربط العائلة', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
            const Text('اكتب رمز عائلتك، ويطلع أطفالك بأسمائهم وأشكالهم', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF34406E), fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _code,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    inputFormatters: [_CodeFormatter()],
                    onSubmitted: (_) => _join(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 3, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'K7QPM-4XR2D',
                      hintStyle: const TextStyle(color: Color(0xFFC3CAD8), fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: const Color(0xFFF4F7FC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('لصق الرمز', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.orange,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    side: const BorderSide(color: Color(0xFFFFD9B3), width: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _busy
                    ? const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
                    : BigButton(label: 'ربط', icon: Icons.link_rounded, onTap: _join),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// يكتب الرمز بشكل XXXXX-XXXXX: حروف كبيرة، والشرطة تنضاف لحالها بعد خامس حرف
class _CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var raw = newValue.text;
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      raw = raw.replaceAll(ar[i], '$i');
    }
    raw = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    // لو مسح الشرطة بالرجوع، نمسح الحرف اللي قبلها
    if (oldValue.text.endsWith('-') && newValue.text.length < oldValue.text.length && raw.length == 5) raw = raw.substring(0, 4);
    if (raw.length > 10) raw = raw.substring(0, 10);
    final out = raw.length >= 5 ? '${raw.substring(0, 5)}-${raw.substring(5)}' : raw;
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}

/// مين يستخدم هالجهاز؟ (اختيار أكثر من طفل)
class WhoScreen extends StatefulWidget {
  final bool first;
  const WhoScreen({super.key, this.first = false});
  @override
  State<WhoScreen> createState() => _WhoScreenState();
}

class _WhoScreenState extends State<WhoScreen> {
  late final Set<String> _sel = {...Family.I.devKids};

  @override
  Widget build(BuildContext context) {
    final kids = Family.I.kids;
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (!widget.first)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
              ),
            const SizedBox(height: 10),
            const Text('مين يستخدم هالجهاز؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
            const Text('اختر طفل أو أكثر', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF34406E), fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .78,
              children: [
                for (final k in kids)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sel.contains(k.id) ? _sel.remove(k.id) : _sel.add(k.id));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _sel.contains(k.id) ? const Color(0xFFFFF1E2) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _sel.contains(k.id) ? C.orange : Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Color(0x1A50628A), blurRadius: 16, offset: Offset(0, 6))],
                      ),
                      child: Column(children: [
                        Expanded(child: KidAvatar(kid: k)),
                        Text(k.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        Icon(_sel.contains(k.id) ? Icons.check_circle_rounded : Icons.circle_outlined, color: _sel.contains(k.id) ? C.orange : const Color(0xFFC9D2E3)),
                      ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () async {
                HapticFeedback.selectionClick();
                await Family.I.setDevKids(kids.map((k) => k.id).toList());
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Row(children: [
                Text('👨‍👩‍👧', style: TextStyle(fontSize: 30)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('أنا ولي الأمر / جهاز للكل', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('كل الأطفال يقدرون يكونون أبطال الحكاية', style: TextStyle(fontSize: 13.5, color: C.soft, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: C.soft),
              ]),
            ),
            const SizedBox(height: 18),
            BigButton(
              label: 'تمام',
              onTap: () async {
                await Family.I.setDevKids(_sel.isEmpty ? kids.map((k) => k.id).toList() : _sel.toList());
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

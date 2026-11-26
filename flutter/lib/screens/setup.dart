import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import 'link.dart';

/// أول تشغيل: ربط برمز العائلة، أو بطل سريع بدون رمز
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _home(BuildContext context) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(22), children: [
            const SizedBox(height: 30),
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(32), child: Image.asset('assets/brand/icon.png', width: 116, height: 116))),
            const SizedBox(height: 14),
            const Text('سراج', textAlign: TextAlign.center, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
            const Text('قصص قبل النوم… وطفلك هو البطل 🌙', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 36),
            BigButton(
              label: 'عندي رمز عائلة',
              icon: Icons.key_rounded,
              onTap: () async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const JoinScreen()));
                if (ok == true && context.mounted) _home(context);
              },
            ),
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 15),
              onTap: () async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const SetupScreen(editing: true)));
                if (ok == true && context.mounted) _home(context);
              },
              child: const Text('ابدأ بدون رمز', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.ink)),
            ),
            const SizedBox(height: 14),
            const Text('رمز العائلة يطلع من جهاز الوالدين في سراج،\nويربط كل أجهزة العائلة مع بعض.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, color: C.soft, height: 1.6)),
          ]),
        ),
      ),
    );
  }
}

/// بطل سريع بدون عائلة: الاسم + ولد/بنت
class SetupScreen extends StatefulWidget {
  final bool editing;
  const SetupScreen({super.key, this.editing = false});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController(text: Profile.hero?.name ?? '');
  String _g = Profile.hero?.gender ?? 'm';

  Future<void> _save() async {
    final n = _name.text.trim();
    if (n.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم البطل أول 😊')));
      return;
    }
    await Profile.saveHero(Kid(n, _g));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget _pick(String g, String label) {
    final on = _g == g;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _g = g);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFF1E2) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: on ? C.orange : const Color(0xFFE6EAF2), width: on ? 2.5 : 1.5),
          ),
          child: Column(children: [
            SizedBox(height: 110, child: SvgPicture.asset(g == 'f' ? 'assets/avatars/girl.svg' : 'assets/avatars/boy.svg')),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: on ? C.orange : C.ink)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Align(alignment: AlignmentDirectional.centerStart, child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
            const SizedBox(height: 8),
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('مين بطل الحكاية؟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'اسم الطفل',
                    filled: true,
                    fillColor: const Color(0xFFF4F7FC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [_pick('m', 'ولد'), const SizedBox(width: 12), _pick('f', 'بنت')]),
                const SizedBox(height: 18),
                BigButton(label: 'حفظ', onTap: _save),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';

/// أول تشغيل: اسم البطل وولد/بنت (المرحلة ٢: ربط العائلة برمزها)
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
    if (widget.editing) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .4, .8]),
        ),
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SizedBox(height: 12),
            if (widget.editing)
              Align(alignment: AlignmentDirectional.centerStart, child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.asset('assets/brand/icon.png', width: 96, height: 96))),
            const SizedBox(height: 10),
            const Text('سراج', textAlign: TextAlign.center, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
            const Text('قصص قبل النوم… وطفلك هو البطل 🌙', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
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
                BigButton(label: widget.editing ? 'حفظ' : 'يلّا نبدأ ✨', onTap: _save),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

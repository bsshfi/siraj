import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../main.dart';
import '../theme.dart';
import 'kid_editor.dart';
import 'link.dart';
import 'settings.dart';

/// أول تشغيل: من يستخدم هذا الجهاز؟ (نفس الويب)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _home(BuildContext context) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));

  Widget _choice(BuildContext context, String ic, String t, String s, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
          padding: const EdgeInsets.all(18),
          onTap: onTap,
          child: Row(children: [
            Text(ic, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(s, style: const TextStyle(fontSize: 14.5, color: C.soft, height: 1.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: C.soft),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(22), children: [
            const SizedBox(height: 18),
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(32), child: Image.asset('assets/brand/icon.png', width: 110, height: 110))),
            const SizedBox(height: 12),
            const Text('سراج', textAlign: TextAlign.center, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
            const Text('قصص ما قبل النوم، أبطالها أطفالك ✨', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 26),
            const Text('أهلًا بك 👋 من يستخدم هذا الجهاز؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: Color(0xFF26305A), fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _choice(context, '👨‍👩‍👧', 'أنا وليّ الأمر', 'أنشئ عائلتك وأضف أطفالك، وتابع قراءتهم من جوالك', () async {
              await Family.I.startParent();
              if (!context.mounted) return;
              final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const ParentSetupScreen()));
              if (ok == true && context.mounted) _home(context);
            }),
            _choice(context, '🧒', 'جهاز طفل', 'اربطه بعائلتك برمز العائلة من جوال وليّ الأمر', () async {
              final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const JoinScreen(as: 'child')));
              if (ok == true && context.mounted) _home(context);
            }),
            TextButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const JoinScreen(as: 'parent')));
                if (ok == true && context.mounted) _home(context);
              },
              child: const Text('عندي رمز عائلة وأبي أسترجعها 🔑', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
            ),
          ]),
        ),
      ),
    );
  }
}

/// إعداد العائلة (وليّ الأمر): الأطفال، وش ينادونكم، وقت القصة، رمز وليّ الأمر
class ParentSetupScreen extends StatefulWidget {
  const ParentSetupScreen({super.key});
  @override
  State<ParentSetupScreen> createState() => _ParentSetupScreenState();
}

class _ParentSetupScreenState extends State<ParentSetupScreen> {
  final f = Family.I;
  final _pin = TextEditingController();
  late String _bed = f.bedtime;

  @override
  void initState() {
    super.initState();
    f.addListener(_r);
  }

  @override
  void dispose() {
    f.removeListener(_r);
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  Future<void> _finish() async {
    if (f.kids.isEmpty) return toast(context, 'أضف طفلًا واحدًا على الأقل');
    if (_pin.text.length != 4) return toast(context, 'الرمز لازم يكون ٤ أرقام');
    HapticFeedback.mediumImpact();
    await f.finishSetup(pin: _pin.text, bedtime: _bed);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 50)),
          const Text('تم إنشاء عائلتك!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('هذا رمز عائلتك. احفظه، وبه تربط تابلت الأطفال.', textAlign: TextAlign.center, style: TextStyle(color: C.soft, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(16)),
            child: Text(f.code, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'monospace', color: C.purple)),
          ),
          const SizedBox(height: 10),
          const Text('في التابلت: افتح سراج ← «جهاز طفل» ← أدخل الرمز.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: C.soft)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: f.code));
                  toast(ctx, 'تم نسخ الرمز ✓');
                },
                child: const Text('نسخ', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: C.orange), child: const Text('تم', style: TextStyle(fontWeight: FontWeight.w800)))),
          ]),
        ]),
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _card(String t, String? s, List<Widget> c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            if (s != null) Text(s, style: const TextStyle(color: C.soft, fontWeight: FontWeight.w600, height: 1.5)),
            const SizedBox(height: 10),
            ...c,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 10),
              const Text('عائلتي', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
            ]),
            const SizedBox(height: 12),
            _card('الأطفال 🧒', 'أضف أطفالك ليصيروا أبطال القصص.', [
              for (final k in f.kidMaps)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: KidFace(kid: Kid.fromJson(k), size: 46),
                  title: Text(k['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  trailing: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => KidEditor(kid: k))), child: const Text('تعديل')),
                ),
              if (f.kids.isEmpty) const Text('لا يوجد أطفال بعد', textAlign: TextAlign.center, style: TextStyle(color: C.soft)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KidEditor())), child: const Text('+ إضافة طفل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
            _card('وش ينادونكم العيال؟ 💛', 'عشان تصير القصص قصة عائلتكم: «قال بابا…»', [
              const Text('الأب', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              CallChips(value: f.dad, opts: Family.dadOpts, onChanged: (v) => setState(() => f.fam['dad'] = v)),
              const SizedBox(height: 12),
              const Text('الأم', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              CallChips(value: f.mom, opts: Family.momOpts, onChanged: (v) => setState(() => f.fam['mom'] = v)),
            ]),
            _card('وقت القصة 🌙', 'يوصل تذكير لجهاز الأطفال في هذا الوقت.', [TimePick(value: _bed, onChanged: (v) => setState(() => _bed = v))]),
            _card('رمز وليّ الأمر 🔒', '٤ أرقام تحمي الإعدادات من الصغار.', [
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '2580',
                    hintStyle: const TextStyle(color: Color(0xFFC3CAD8)),
                    filled: true,
                    fillColor: const Color(0xFFF4F7FC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ]),
            BigButton(label: 'أنشئ العائلة 🌙', onTap: _finish),
          ]),
        ),
      ),
    );
  }
}

/// بطل سريع بدون عائلة (للنسخ القديمة فقط)
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
    if (n.isEmpty) return toast(context, 'اكتب اسم البطل أول 😊');
    await Profile.saveHero(Kid(n, _g));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Align(alignment: AlignmentDirectional.centerStart, child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('مين بطل الحكاية؟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: _name, decoration: const InputDecoration(hintText: 'اسم الطفل')),
                const SizedBox(height: 14),
                Row(children: [
                  for (final g in ['m', 'f'])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _g = g),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: _g == g ? C.orange : const Color(0xFFE6EAF2), width: 2)),
                          child: Column(children: [
                            SizedBox(height: 100, child: SvgPicture.asset(g == 'f' ? 'assets/avatars/girl.svg' : 'assets/avatars/boy.svg')),
                            Text(g == 'f' ? 'بنت' : 'ولد', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 14),
                BigButton(label: 'حفظ', onTap: _save),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

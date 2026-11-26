import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data.dart';
import 'screens/setup.dart';
import 'screens/tonight.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // شريط الحالة شفاف فوق، وأزرار الجوال تحت مخفية (تظهر بالسحب)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Future.wait([Library.load(), Profile.load()]);
  runApp(const SirajApp());
}

class SirajApp extends StatelessWidget {
  const SirajApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سراج | Siraj',
      debugShowCheckedModeBanner: false,
      theme: sirajTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Profile.hero == null ? const SetupScreen() : const Shell(),
    );
  }
}

/// الهيكل الرئيسي: نفس تبويبات الويب
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  static const _tabs = [
    ('الليلة', Icons.nightlight_round, Color(0xFF8B5CF6)),
    ('أنا', Icons.face_rounded, Color(0xFFEC6FA8)),
    ('اكتشف', Icons.public_rounded, Color(0xFFF5913A)),
    ('العب وتعلّم', Icons.extension_rounded, Color(0xFFE9B526)),
    ('للوالدين', Icons.family_restroom_rounded, Color(0xFF6D7BF2)),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const TonightScreen(),
      const _Soon(title: 'أنا', emoji: '⭐', note: 'غرفتك وشخصيتك ونجومك'),
      const _Soon(title: 'اكتشف', emoji: '🌍', note: 'الرحلات حول العالم والفضاء'),
      const _Soon(title: 'العب وتعلّم', emoji: '🧩', note: 'الإنجليزي والألعاب'),
      const _Soon(title: 'للوالدين', emoji: '👨‍👩‍👧', note: 'ربط العائلة والإعدادات والتقارير'),
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x2650628A), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(child: _NavItem(
                label: _tabs[i].$1,
                icon: _tabs[i].$2,
                color: _tabs[i].$3,
                selected: _tab == i,
                onTap: () {
                  if (_tab == i) return;
                  HapticFeedback.selectionClick();
                  setState(() => _tab = i);
                },
              )),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedScale(
            scale: selected ? 1.12 : 1,
            duration: const Duration(milliseconds: 220),
            child: Icon(icon, size: 24, color: selected ? Colors.white : color.withValues(alpha: .75)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : C.soft)),
        ]),
      ),
    );
  }
}

class _Soon extends StatelessWidget {
  final String title, emoji, note;
  const _Soon({required this.title, required this.emoji, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .35, .7]),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SoftCard(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('$note\nقريبًا في النسخة الجاية ✨', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: C.soft, height: 1.6)),
            ]),
          ),
        ),
      ),
    );
  }
}

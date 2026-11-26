import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'avatars.dart';
import 'data.dart';
import 'family.dart';
import 'learn.dart';
import 'remote.dart';
import 'screens/explore.dart';
import 'screens/me.dart';
import 'screens/parents.dart';
import 'screens/play_learn.dart';
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
  await Future.wait([Library.load(), Profile.load(), Family.I.load(), Learn.load()]);
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
      // محرّك رسم الشخصيات (مخفي) — نفس رسّام نسخة الويب
      builder: (context, child) => Stack(children: [
        Positioned(left: 0, top: 0, child: Avatars.host()),
        if (child != null) Positioned.fill(child: child),
      ]),
      home: Profile.hero == null && !Family.I.linked ? const WelcomeScreen() : const Shell(),
    );
  }
}

/// الهيكل الرئيسي: نفس تبويبات الويب
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Remote.check(context);
      Family.I.syncNow();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Family.I.syncNow();
      if (mounted) Remote.check(context);
    }
  }

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
      const MeScreen(),
      const ExploreScreen(),
      const PlayLearnScreen(),
      const ParentsScreen(),
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

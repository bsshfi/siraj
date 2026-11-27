import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'avatars.dart';
import 'data.dart';
import 'family.dart';
import 'learn.dart';
import 'nav.dart';
import 'notify.dart';
import 'remote.dart';
import 'sky.dart';
import 'screens/kid_editor.dart';
import 'screens/sounds.dart';
import 'widgets/pin.dart';
import 'screens/explore.dart';
import 'screens/sky_screen.dart';
import 'screens/parents.dart';
import 'screens/play_learn.dart';
import 'screens/setup.dart';
import 'screens/tonight.dart';
import 'theme.dart';
import 'widgets/stk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // شريط الحالة شفاف فوق، وأزرار الجوال تحت مخفية (تظهر بالسحب)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  if (Family.demo) await _seedDemo();
  await Future.wait([Library.load(), Profile.load(), Family.I.load(), Learn.load(), ArtOpts.load(), Sky.load(), Stk.load()]);
  runApp(const SirajApp());
}

/// بيانات عرض ثابتة للقطات الشاشة الآلية (--dart-define=DEMO=true فقط)
Future<void> _seedDemo() async {
  final p = await SharedPreferences.getInstance();
  if (p.getString('family_v1') != null) return;
  await p.setBool('notifAsked', true);
  await p.setString('family_v1', jsonEncode({
    'role': 'parent', 'code': 'DEMO0-DEMO0', 'dev': 'demo1234', 'sel': ['k1'], 'tourDone': true, 'parentMode': 'view',
    'fam': {
      'kids': [
        {'id': 'k1', 'name': 'نورة', 'g': 'f', 'age': 7},
        {'id': 'k2', 'name': 'خالد', 'g': 'm', 'age': 6},
        {'id': 'k3', 'name': 'فهد', 'g': 'm', 'age': 4},
      ],
      'pin': '1234', 'dad': 'بابا', 'mom': 'ماما', 'bedtime': '20:30', 'remind': true, 'perNight': 2, 'shortKids': true, 'lockOn': false, 'lock': '21:30',
    },
  }));
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
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final w = mq.size.width;
        // الخطوط بنفس مقاسات الويب بالضبط (px = dp) مثل سراج على الآيفون: نتجاهل تكبير خط الجوال، ونصغّر شوي على الجوالات الضيقة جدًا
        final sys = mq.textScaler.scale(1).clamp(.85, 1.0);
        final fit = w < 360 ? .92 : 1.0;
        // التابلت: المحتوى في عمود بعرض مريح في النص (مثل نسخة الويب)
        const maxW = 720.0;
        final wide = w > maxW + 40;
        Widget app = MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(sys * fit), size: wide ? Size(maxW, mq.size.height) : mq.size),
          child: child ?? const SizedBox(),
        );
        if (wide) {
          app = DecoratedBox(
            decoration: const BoxDecoration(gradient: SkyBg.gradient),
            child: Center(child: SizedBox(width: maxW, child: ClipRect(child: app))),
          );
        }
        return Stack(children: [
          Positioned(left: 0, top: 0, child: Avatars.host()),
          Positioned.fill(child: app),
        ]);
      },
      home: Profile.hero == null && !Family.I.linked ? const WelcomeScreen() : const Shell(),
      navigatorKey: Shell.nav,
    );
  }
}

/// الهيكل الرئيسي: نفس تبويبات الويب
class Shell extends StatefulWidget {
  const Shell({super.key});
  static final nav = GlobalKey<NavigatorState>();
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int get _tab => Nav.tab.value;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Nav.tab.addListener(_r);
    Family.I.addListener(_r);
    Sounds.I.addListener(_r);
    // وليّ الأمر طلب تحديث كل أجهزة العيال
    Family.I.onForceUpdate = () {
      final c = Shell.nav.currentContext;
      if (c != null) Remote.check(c, manual: true);
    };
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _r());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Remote.check(context);
      Family.I.syncNow();
      _tour().then((_) async {
        // نطلب إذن الإشعارات أول ما يدخل (وليّ أمر أو طفل)، ومرة وحدة بس
        await Notify.askOnce();
        Notify.schedule();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Nav.tab.removeListener(_r);
    Family.I.removeListener(_r);
    Sounds.I.removeListener(_r);
    _tick?.cancel();
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  /// جولة سريعة أول مرة على جهاز الطفل
  Future<void> _tour() async {
    final f = Family.I;
    if (f.tourDone || !f.isChild) return;
    final n = f.myKids.map((k) => k.name).join(' و');
    final steps = [
      ('🌙', 'هلا $n!', 'كل ليلة لك قصة جديدة باسمك، وأنت البطل فيها'),
      ('⭐', 'اجمع النجوم', 'كل قصة تخلصها = نجمة، والشارات تنفتح لك في «أنا»'),
      ('🌍', 'اكتشف العالم', 'سافر لكل الدول، واعرف الكواكب والقمر'),
      ('🧩', 'العب وتعلّم', 'إنجليزي وألعاب وأسئلة على قدّك'),
    ];
    for (var i = 0; i < steps.length; i++) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(steps[i].$1, style: const TextStyle(fontSize: 60)),
            Text(steps[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(steps[i].$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.5, color: C.soft, height: 1.6, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            BigButton(label: i == steps.length - 1 ? 'يلا نبدأ! 🚀' : 'التالي', onTap: () => Navigator.pop(ctx, true)),
            if (i < steps.length - 1) TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تخطي', style: TextStyle(color: C.soft))),
          ]),
        ),
      );
      if (go != true) break;
    }
    f.setTourDone();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Family.I.syncNow();
      if (mounted) Remote.check(context);
    }
  }

  static const _tabs = [
    ('الليلة', 'navTonight'),
    ('أنا', 'navMe'),
    ('اكتشف', 'navExplore'),
    ('العب وتعلّم', 'navLearn'),
    ('للوالدين', 'navParents'),
  ];

  @override
  Widget build(BuildContext context) {
    final f = Family.I;
    // جهاز الطفل: بدون تبويب الوالدين (الإعدادات من ⚙️ برمز وليّ الأمر)
    final shown = [0, 1, 2, 3, if (!f.isChild) 4];
    if (!shown.contains(_tab)) Nav.tab.value = 0;
    final pages = <Widget>[
      const TonightScreen(),
      const MeScreen(),
      const ExploreScreen(),
      const PlayLearnScreen(),
      f.isChild ? const SizedBox() : const ParentsScreen(),
    ];
    if (f.isLocked) return const _LockScreen();
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        IndexedStack(index: _tab, children: pages),
        if (Sounds.I.cur != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 92,
            child: Material(
              color: C.night1,
              borderRadius: BorderRadius.circular(22),
              elevation: 6,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SoundsScreen())),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                  child: Row(children: [
                    Text(Sounds.I.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('أصوات النوم: ${Sounds.I.label}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: Sounds.I.stop, icon: const Icon(Icons.stop_circle_rounded, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
      bottomNavigationBar: Padding(
        // .bnav في الويب: زجاج أبيض عائم، ارتفاع ٦٨، زوايا ٢٦، بعيد عن الحواف ١٤
        padding: EdgeInsets.fromLTRB(14, 0, 14, max(14.0, MediaQuery.of(context).padding.bottom - 14)),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 452),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xD1FFFFFF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0x14141E32)),
                  ),
                  child: Row(children: [
                    for (final i in shown)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: _NavItem(
                            label: _tabs[i].$1,
                            icon: _tabs[i].$2,
                            selected: _tab == i,
                            onTap: () {
                              if (_tab == i) return;
                              HapticFeedback.selectionClick();
                              Nav.tab.value = i;
                            },
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 54,
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [Color(0xFF8A5CF0), Color(0xFF6A42D8)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? const [BoxShadow(color: Color(0x526A42D8), blurRadius: 14, offset: Offset(0, 6))] : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          StkIcon(icon, size: 26),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(fontSize: 11, height: 1.2, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : const Color(0xFF7A8291))),
        ]),
      ),
    );
  }
}

/// قفل وقت النوم على جهاز الطفل (وليّ الأمر يفتحه ٣٠ دقيقة برمزه)
class _LockScreen extends StatelessWidget {
  const _LockScreen();
  @override
  Widget build(BuildContext context) {
    final f = Family.I;
    final n = f.myKids.map((k) => k.name).join(' و');
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0E1030), C.night1, C.night2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🌙', style: TextStyle(fontSize: 90)),
              const Text('حان وقت النوم', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('تصبح على خير يا $n 💤\nموعدنا بكرة مع حكاية جديدة', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 18, height: 1.7, fontWeight: FontWeight.w600)),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () async {
                  if (await askPin(context, hint: 'فتح التطبيق ٣٠ دقيقة')) f.setUnlock(DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch);
                },
                child: const Text('🔓 وليّ الأمر', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

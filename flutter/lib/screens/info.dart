import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../data.dart';
import '../learn.dart';
import '../theme.dart';

/// حول التطبيق، سياسة الخصوصية، المشاركة — كلها داخل التطبيق بدون صفحات ويب
class Info {
  static const mail = 'siraj@wamdarc.com';
  static const site = 'https://siraj.wamdarc.com';

  static Future<void> shareApp() => SharePlus.instance.share(ShareParams(
        title: 'سراج | SIRAJ',
        text: 'سراج 🌙 قصص ما قبل النوم، أبطالها أطفالك. قصص هادفة بأسمائهم وبالصور، وتشتغل بدون إنترنت.\n$site',
      ));

  static Future<String> version() async {
    try {
      final p = await PackageInfo.fromPlatform();
      return '${p.version} (${p.buildNumber})';
    } catch (_) {
      return '';
    }
  }
}

/// شعار WAMD ARC (بدون رابط)
class WamdLogo extends StatelessWidget {
  final bool dark;
  const WamdLogo({super.key, this.dark = false});
  @override
  Widget build(BuildContext context) => Column(children: [
        Image.asset(dark ? 'assets/brand/wamdarc-dark.png' : 'assets/brand/wamdarc-light.png', width: 132, height: 21, errorBuilder: (_, __, ___) => const SizedBox()),
        const SizedBox(height: 4),
        Text('WAMDARC.COM', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: dark ? Colors.white60 : C.soft)),
      ]);
}

class _InfoPage extends StatelessWidget {
  final String title, sub;
  final List<Widget> children;
  const _InfoPage({required this.title, required this.sub, required this.children});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .3, .6])),
        child: ListView(padding: EdgeInsets.fromLTRB(16, top + 8, 16, bottom + 30), children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
          ),
          Center(child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Image.asset('assets/brand/icon.png', width: 92, height: 92))),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF34406E))),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _v = '';
  @override
  void initState() {
    super.initState();
    Info.version().then((v) => mounted ? setState(() => _v = v) : null);
  }

  @override
  Widget build(BuildContext context) {
    final n = (Library.stories.length ~/ 10) * 10;
    final f = [
      ('📖', 'قصص بأسماء أطفالك', 'أكثر من ${Learn.ar(n)} قصة أصلية: قيم، وقصص أنبياء وصحابة، وعلوم، وقصص «اختر طريقك».'),
      ('🎨', 'شخصيات يصممها الطفل', 'الشكل واللبس والأحذية وقمصان الأندية، وتظهر في رسومات القصص.'),
      ('🔤', 'إنجليزي وألعاب', 'حروف وكلمات ونطق وألغاز وأسئلة، حسب عمر كل طفل.'),
      ('🪐', 'الكواكب والقمر', 'منازل القمر والكواكب والنجوم بأسلوب يناسب الصغار.'),
      ('✈️', 'رحلات حول العالم', 'يسافر مع العائلة، ويتعلم الأعلام والعواصم، ويختم جوازه.'),
      ('🤲', 'أذكار وأصوات النوم', 'أذكار النوم بمصادرها، وأصوات هادئة بمؤقت.'),
      ('👨‍👩‍👧', 'متابعة الوالدين', 'لوحة متابعة، ورسائل للعيال، ومكافأة الأسبوع.'),
      ('🔒', 'خصوصية العائلة', 'أسماء الأطفال وكل بياناتهم تنشفّر على جهازك قبل أي مزامنة.'),
    ];
    return _InfoPage(title: 'سراج | SIRAJ', sub: _v.isEmpty ? '' : 'الإصدار $_v', children: [
      const Text('قصص قبل النوم بأسماء أطفالك 🌙', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.purple)),
      const SizedBox(height: 10),
      SoftCard(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'سراج يحوّل وقت النوم لحكاية يكون أطفالك أبطالها: قصة كل ليلة بأسمائهم، ورسومات فيها شخصياتهم، وأنشطة خفيفة تعلّمهم وتسعدهم. بدون إعلانات، وبدون مشتريات داخل التطبيق.',
          style: TextStyle(fontSize: 16, height: 1.7, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 12),
      SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          for (final x in f)
            ListTile(
              leading: Text(x.$1, style: const TextStyle(fontSize: 28)),
              title: Text(x.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              subtitle: Text(x.$3, style: const TextStyle(color: C.soft, height: 1.5, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
      const SizedBox(height: 18),
      const Text('من تطوير', textAlign: TextAlign.center, style: TextStyle(color: C.soft, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const WamdLogo(),
      const SizedBox(height: 18),
      BigButton(label: 'مشاركة التطبيق 📤', onTap: Info.shareApp),
    ]);
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/data/privacy.json'),
      builder: (_, snap) {
        Map<String, dynamic> d = {};
        try {
          if (snap.hasData) d = Map<String, dynamic>.from(jsonDecode(snap.data!) as Map);
        } catch (_) {}
        final secs = ((d['sections'] as List?) ?? []).map((x) => Map<String, dynamic>.from(x as Map)).toList();
        return _InfoPage(title: 'سياسة الخصوصية', sub: 'سراج | SIRAJ${d['updated'] != null ? ' · آخر تحديث: ${d['updated']}' : ''}', children: [
          for (final s in secs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s['e']} ${s['h']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (final b in (s['b'] as List? ?? []))
                    Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(b.toString(), style: const TextStyle(fontSize: 15.5, height: 1.7, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
          const SizedBox(height: 10),
          const WamdLogo(),
        ]);
      },
    );
  }
}

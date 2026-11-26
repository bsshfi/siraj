import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets/common.dart';
import 'link.dart';
import 'setup.dart';

/// تبويب "للوالدين": بوابة للكبار (سياسة العائلات في Google Play) ثم لوحة المتابعة والإعدادات
class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});
  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  static DateTime? _openUntil;
  late int _a, _b;
  late List<int> _opts;
  String _ver = '';

  bool get _open => _openUntil != null && DateTime.now().isBefore(_openUntil!);

  @override
  void initState() {
    super.initState();
    _newGate();
    Family.I.addListener(_r);
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _ver = '${p.version} (${p.buildNumber})');
    });
  }

  @override
  void dispose() {
    Family.I.removeListener(_r);
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  void _newGate() {
    final r = math.Random();
    _a = 6 + r.nextInt(4);
    _b = 6 + r.nextInt(4);
    final ans = _a * _b;
    final s = <int>{ans};
    while (s.length < 4) {
      s.add(ans + (r.nextInt(17) - 8));
    }
    _opts = s.toList()..shuffle(r);
  }

  void _answer(int v) {
    if (v == _a * _b) {
      HapticFeedback.mediumImpact();
      setState(() => _openUntil = DateTime.now().add(const Duration(minutes: 10)));
      Family.I.syncNow();
    } else {
      HapticFeedback.heavyImpact();
      setState(_newGate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) return _gate();
    return _dash(context);
  }

  Widget _gate() => TabPage(
        title: 'للوالدين',
        subtitle: 'هالقسم للكبار فقط 🔒',
        children: [
          SoftCard(
            padding: const EdgeInsets.all(22),
            child: Column(children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 54)),
              const Text('جاوب عشان تدخل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('${Learn.ar(_a)} × ${Learn.ar(_b)} = ؟', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: C.purple)),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  for (final o in _opts)
                    Material(
                      color: const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _answer(o),
                        child: Center(child: Text(Learn.ar(o), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
                      ),
                    ),
                ],
              ),
            ]),
          ),
        ],
      );

  String _ago(num t) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(t.toInt()));
    if (d.inMinutes < 1) return 'الحين';
    if (d.inMinutes < 60) return 'قبل ${Learn.ar(d.inMinutes)} د';
    if (d.inHours < 24) return 'قبل ${Learn.ar(d.inHours)} س';
    if (d.inDays == 1) return 'أمس';
    return 'قبل ${Learn.ar(d.inDays)} ${d.inDays < 11 ? 'أيام' : 'يوم'}';
  }

  static const _actName = {
    'adhkar': 'قال أذكار النوم 🤲', 'en': 'لعب English 🔤', 'space': 'اكتشف الفضاء 🪐', 'trip': 'سافر برحلة ✈️', 'flags': 'لعب لعبة الأعلام 🚩',
    'quiz': 'جاوب أسئلة القصص ❓', 'color': 'لوّن المشهد 🎨', 'puzzle': 'رتّب الأحجية 🧩',
  };

  Widget _dash(BuildContext context) {
    final f = Family.I;
    final kids = f.linked && f.kids.isNotEmpty ? f.kids : [Profile.hero ?? const Kid('بطلنا', 'm')];
    final byId = {for (final s in Library.stories) s.id: s};
    final names = {for (final k in kids) k.id: k.name};
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final feed = [
      ...f.allLogs.map((e) => (e, true)),
      ...f.allActs.map((e) => (e, false)),
    ]..sort((a, b) => ((b.$1['t'] as num?) ?? 0).compareTo((a.$1['t'] as num?) ?? 0));

    return TabPage(
      title: 'للوالدين',
      subtitle: f.linked ? 'العائلة مربوطة ✅' : 'هالجهاز مو مربوط بعائلة',
      trailing: IconButton.filledTonal(
        onPressed: () {
          HapticFeedback.lightImpact();
          f.syncNow();
        },
        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .85)),
        icon: f.syncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Icon(Icons.sync_rounded, color: C.ink),
      ),
      children: [
        if (!f.linked)
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('اربط الجهاز بعائلتك 🔑', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const Text('عشان تطلع أسماء أطفالك وأشكالهم، وتوصلك قراءاتهم من كل الأجهزة.', style: TextStyle(fontSize: 15, color: C.soft, height: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              BigButton(label: 'ربط برمز العائلة', icon: Icons.key_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinScreen()))),
            ]),
          ),
        const SectionTitle('الأطفال 👧👦'),
        for (final k in kids) _kidCard(k, weekAgo, byId),
        const SectionTitle('آخر النشاطات 🕐'),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: feed.isEmpty
              ? const Padding(padding: EdgeInsets.all(20), child: Text('ما فيه نشاط لين الحين', textAlign: TextAlign.center, style: TextStyle(color: C.soft, fontWeight: FontWeight.w700)))
              : Column(children: [
                  for (final (e, isLog) in feed.take(15))
                    ListTile(
                      dense: true,
                      leading: Text(isLog ? '📖' : '🎮', style: const TextStyle(fontSize: 22)),
                      title: Text(
                        '${((e['k'] as List?) ?? []).map((id) => names[id] ?? '').where((n) => n.isNotEmpty).join(' و')}${((e['k'] as List?) ?? []).isEmpty ? '' : ': '}'
                        '${isLog ? (byId[e['s']] != null ? 'قرأ «${fillTemplate(byId[e['s']]!.title, kids.first)}»' : 'قرأ قصة') : (_actName[e['a']] ?? e['a'].toString())}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      trailing: Text(_ago((e['t'] as num?) ?? 0), style: const TextStyle(color: C.soft, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                ]),
        ),
        const SectionTitle('الإعدادات ⚙️'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('سرعة القراءة بالصوت', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Row(children: [
              const Text('🐢'),
              Expanded(
                child: Slider(
                  value: Profile.rate.clamp(.25, .7),
                  min: .25,
                  max: .7,
                  divisions: 9,
                  activeColor: C.orange,
                  onChanged: (v) => setState(() => Profile.rate = v),
                  onChangeEnd: (v) {
                    Profile.saveRate(v);
                    Voice.stop().then((_) => Voice.speak('كان يا ما كان، في قديم الزمان', v));
                  },
                ),
              ),
              const Text('🐇'),
            ]),
            if (f.linked) Text('وقت النوم في العائلة: ${Learn.ar(f.bedtime)}', style: const TextStyle(color: C.soft, fontWeight: FontWeight.w700)),
            const Divider(height: 22),
            if (f.linked && f.kids.length > 1)
              _row(Icons.groups_rounded, 'مين يستخدم هالجهاز؟', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhoScreen()))),
            if (!f.linked) _row(Icons.edit_rounded, 'تعديل البطل', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetupScreen(editing: true))).then((_) => _r())),
            _row(Icons.brush_rounded, 'تعديل الأطفال وأشكالهم (من الموقع)', () => launchUrl(Uri.parse('https://siraj.wamdarc.com/'), mode: LaunchMode.externalApplication)),
            if (f.log.isNotEmpty || f.act.isNotEmpty) _row(Icons.cleaning_services_rounded, 'مسح قراءات هالجهاز', () => _confirm(context, 'تمسح قراءات وألعاب هالجهاز؟', 'لو كنت تتصفح بس، امسحها عشان ما تنحسب على العيال.', f.clearMine)),
            if (f.linked) _row(Icons.link_off_rounded, 'فك ربط هالجهاز', () => _confirm(context, 'تفك ربط الجهاز؟', 'تقدر تربطه مرة ثانية بنفس الرمز.', f.unlink), danger: true),
          ]),
        ),
        const SectionTitle('عن سراج 🌙'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(children: [
            _row(Icons.privacy_tip_rounded, 'سياسة الخصوصية', () => launchUrl(Uri.parse('https://siraj.wamdarc.com/privacy.html'), mode: LaunchMode.externalApplication)),
            _row(Icons.mail_rounded, 'تواصل معنا', () => launchUrl(Uri.parse('mailto:bsshfi@gmail.com?subject=${Uri.encodeComponent('سراج | Siraj')}'))),
            const SizedBox(height: 6),
            Text('سراج | Siraj $_ver\nمن WAMD ARC · بدون إعلانات وبدون تتبّع', textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontWeight: FontWeight.w600, height: 1.6)),
          ]),
        ),
      ],
    );
  }

  Widget _kidCard(Kid k, int weekAgo, Map<String, Story> byId) {
    final f = Family.I;
    final logs = f.logsOf(k), acts = f.actsOf(k);
    final week = logs.where((e) => ((e['t'] as num?) ?? 0) >= weekAgo).map((e) => e['d']).toSet().length;
    final last = logs.isNotEmpty ? logs.last : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          KidFace(kid: k, size: 62),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text('⭐ ${Learn.ar(logs.length)} قصة · 🌙 ${Learn.ar(week)}/٧ ليالي هالأسبوع · 🔥 ${Learn.ar(f.streakOf(k))}',
                  style: const TextStyle(fontSize: 13.5, color: C.soft, fontWeight: FontWeight.w700)),
              Text('🎮 ${Learn.ar(acts.length)} نشاط${last != null && byId[last['s']] != null ? ' · آخر قصة: ${fillTemplate(byId[last['s']]!.title, k)}' : ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, color: C.soft, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(IconData i, String t, VoidCallback onTap, {bool danger = false}) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(i, color: danger ? Colors.redAccent : C.sky),
        title: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: danger ? Colors.redAccent : C.ink)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: C.soft),
        onTap: onTap,
      );

  void _confirm(BuildContext context, String title, String body, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await action();
            },
            child: const Text('نعم'),
          ),
        ],
      ),
    );
  }
}

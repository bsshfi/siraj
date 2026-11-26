import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tonight_logic.dart';
import '../widgets/common.dart';
import '../widgets/pin.dart';
import 'link.dart';
import 'settings.dart';
import 'setup.dart';

/// تبويب "للوالدين" (جوال وليّ الأمر): لوحة المتابعة — نفس renderDash في الويب
class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});
  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  final f = Family.I;

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

  String _ago(num t) {
    final m = ((DateTime.now().millisecondsSinceEpoch - t) / 60000).round();
    if (m < 2) return 'الآن';
    if (m < 60) return 'قبل ${Learn.ar(m)} دقيقة';
    final h = (m / 60).round();
    if (h < 24) return 'قبل ${Learn.ar(h)} ساعة';
    final d = (h / 24).round();
    return d == 1 ? 'أمس' : 'قبل ${Learn.ar(d)} أيام';
  }

  Future<void> _settings({String? jump}) async {
    if (!await askPin(context)) return;
    if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(jump: jump)));
  }

  void _code() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔑', style: TextStyle(fontSize: 46)),
          const Text('رمز عائلتك', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(f.code, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'monospace', color: C.purple)),
          const SizedBox(height: 8),
          const Text('في التابلت: افتح سراج ← «جهاز طفل» ← أدخل الرمز.', textAlign: TextAlign.center, style: TextStyle(color: C.soft)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: f.code));
              Navigator.pop(ctx);
              toast(context, 'تم نسخ الرمز ✓');
            },
            style: FilledButton.styleFrom(backgroundColor: C.orange),
            child: const Text('نسخ الرمز', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  static const _actName = {
    'adhkar': 'قال أذكار النوم 🤲', 'en': 'لعب English 🔤', 'space': 'اكتشف الفضاء 🪐', 'trip': 'سافر برحلة ✈️', 'flags': 'لعب لعبة الأعلام 🚩',
    'quiz': 'جاوب أسئلة القصص ❓', 'color': 'لوّن المشهد 🎨', 'puzzle': 'رتّب الأحجية 🧩',
  };

  @override
  Widget build(BuildContext context) {
    if (f.kids.isEmpty) {
      return TabPage(title: 'للوالدين', subtitle: 'ما فيه عائلة على هالجهاز', children: [
        SoftCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('👨‍👩‍👧', textAlign: TextAlign.center, style: TextStyle(fontSize: 50)),
            const Text('أنشئ عائلتك أو اربط الجهاز', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            BigButton(label: 'أنا وليّ الأمر — أنشئ عائلتي', onTap: () async {
              await f.startParent();
              if (context.mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentSetupScreen()));
            }),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinScreen(as: 'parent'))), child: const Text('عندي رمز عائلة 🔑', style: TextStyle(fontWeight: FontWeight.w800))),
          ]),
        ),
      ]);
    }
    final byId = {for (final s in Library.stories) s.id: s};
    final logs = f.allLogs, acts = f.allActs;
    final now = DateTime.now();
    final week = List.generate(7, (i) => Family.dateKey(now.subtract(Duration(days: 6 - i))));
    const dn = ['إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];
    final devs = f.devices;
    String names(List ids) => ids.map((id) => f.kidById(id.toString())?.name).whereType<String>().join(' و');

    Widget quick(String e, String t, VoidCallback onTap) => Expanded(
          child: SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 14),
            onTap: onTap,
            child: Column(children: [Text(e, style: const TextStyle(fontSize: 30)), Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))]),
          ),
        );

    return TabPage(
      title: 'للوالدين',
      subtitle: 'متابعة العائلة 📊',
      trailing: IconButton.filledTonal(
        onPressed: () {
          HapticFeedback.lightImpact();
          f.syncNow();
        },
        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .85)),
        icon: f.syncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Icon(Icons.sync_rounded, color: C.ink),
      ),
      children: [
        Row(children: [
          quick('⚙️', 'الإعدادات', _settings),
          const SizedBox(width: 8),
          quick('💌', 'رسالة للعيال', () => _settings(jump: 'msg')),
          const SizedBox(width: 8),
          quick('🎁', 'مكافأة الأسبوع', () => _settings(jump: 'reward')),
          if (f.linked) ...[const SizedBox(width: 8), quick('🔑', 'رمز العائلة', _code)],
        ]),
        const SectionTitle('الأطفال 👧👦'),
        for (final k in f.kids) () {
          final mine = logs.where((e) => ((e['k'] as List?) ?? []).contains(k.id)).toList();
          final days = mine.map((e) => e['d'].toString()).toSet();
          final last = mine.isNotEmpty ? mine.first : null;
          final lastSt = last != null ? byId[last['s']] : null;
          final a = acts.where((x) => ((x['k'] as List?) ?? []).contains(k.id)).toList();
          int cnt(String t) => a.where((x) => x['a'] == t).length;
          final kd = devs.where((d) => d['role'] == 'child' && ((d['kids'] as List?) ?? []).contains(k.id)).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  KidFace(kid: k, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(k.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      Text(last != null ? 'آخر قصة ${_ago((last['t'] as num?) ?? 0)}' : (k.isGirl ? 'ما قرأت بعد' : 'ما قرأ بعد'), style: const TextStyle(color: C.soft, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  for (final s in [(Learn.ar(mine.map((e) => e['s']).toSet().length), 'قصة'), ('${Learn.ar(f.streakOf(k))} 🔥', 'أيام متتالية'), (Learn.ar(mine.length), 'مرة قراءة')])
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          Text(s.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Text(s.$2, style: const TextStyle(fontSize: 12.5, color: C.soft, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  for (final d in week)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: days.contains(d) ? const Color(0xFF2C2F5C) : const Color(0xFFF0F3F9), borderRadius: BorderRadius.circular(10)),
                        child: Text(dn[DateTime.parse(d).weekday - 1], textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: days.contains(d) ? Colors.white : C.soft)),
                      ),
                    ),
                ]),
                if (lastSt != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('آخر قصة: «${fillTemplate(lastSt.title, k, dad: f.dad, mom: f.mom)}»', style: const TextStyle(color: C.soft, fontWeight: FontWeight.w600))),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('⭐ ${Learn.ar(f.monthNights(k))} نجمة هالشهر${a.isNotEmpty ? ' · 🤲 ${Learn.ar(cnt('adhkar'))} · 🔤 ${Learn.ar(cnt('en'))} · 🪐 ${Learn.ar(cnt('space'))} · ✈️ ${Learn.ar(cnt('trip'))}' : ''}',
                      style: const TextStyle(color: C.soft, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: kd.isNotEmpty ? const Color(0xFFE5FBEA) : const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    kd.isNotEmpty
                        ? '📱 سراج مثبّت على ${kd.first['plat'] ?? 'جهاز'}${kd.length > 1 ? ' و${Learn.ar(kd.length - 1)} غيره' : ''} · آخر فتح ${_ago((kd.first['last'] as num?) ?? 0)}'
                        : '⚪ ما فيه جهاز مربوط ل${k.isGirl ? 'ها' : 'ه'}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: kd.isNotEmpty ? const Color(0xFF1E8E4A) : C.soft, fontSize: 13.5),
                  ),
                ),
              ]),
            ),
          );
        }(),
        const SectionTitle('الأجهزة المربوطة 📱'),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: devs.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: Text('ما فيه أجهزة مربوطة غير هذا الجوال.', textAlign: TextAlign.center, style: TextStyle(color: C.soft, fontWeight: FontWeight.w700)))
              : Column(children: [
                  for (final d in devs)
                    ListTile(
                      leading: Icon(Icons.circle, size: 12, color: DateTime.now().millisecondsSinceEpoch - ((d['last'] as num?) ?? 0) < 3 * 86400000 ? const Color(0xFF2FA36B) : const Color(0xFFC9D2E3)),
                      title: Text(d['role'] == 'parent' ? 'وليّ أمر' : names((d['kids'] as List?) ?? []).isNotEmpty ? names(d['kids'] as List) : 'جهاز طفل (ما اختار اسمه بعد)', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${d['plat'] ?? 'جهاز'} · آخر فتح ${_ago((d['last'] as num?) ?? 0)}${d['ver'] != null ? ' · v${d['ver']}' : ''}', style: const TextStyle(fontSize: 12.5)),
                      trailing: TextButton(
                        onPressed: () => f.hideDevice(d['dev'].toString()),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFD33A3A)),
                        child: const Text('إزالة'),
                      ),
                    ),
                ]),
        ),
        const SectionTitle('آخر النشاط 🕐'),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: logs.isEmpty && acts.isEmpty
              ? const Padding(padding: EdgeInsets.all(20), child: Text('ما فيه نشاط بعد', textAlign: TextAlign.center, style: TextStyle(color: C.soft, fontWeight: FontWeight.w700)))
              : Column(children: [
                  for (final e in [...logs.take(12).map((e) => (e, true)), ...acts.take(8).map((e) => (e, false))]..sort((a, b) => ((b.$1['t'] as num?) ?? 0).compareTo((a.$1['t'] as num?) ?? 0)))
                    () {
                      final m = e.$1, ks = ((m['k'] as List?) ?? []).map((id) => f.kidById(id.toString())).whereType<Kid>().toList();
                      final st = byId[m['s']];
                      final what = e.$2
                          ? (st != null ? (ks.isNotEmpty ? fillTemplate(st.title, ks.first, friends: ks.sublist(1), dad: f.dad, mom: f.mom) : st.title.replaceAll('{n}', '…')) : 'قصة')
                          : (_actName[m['a']] ?? m['a'].toString());
                      return ListTile(
                        dense: true,
                        leading: Text(e.$2 ? '📖' : (st == null ? '🎮' : '📖'), style: const TextStyle(fontSize: 22)),
                        title: Text(what, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: Text('${ks.isEmpty ? '—' : ks.map((k) => k.name).join(' و')} · ${_ago((m['t'] as num?) ?? 0)} · ${m['role'] == 'child' ? 'جهاز الطفل' : 'جوال وليّ الأمر'}', style: const TextStyle(fontSize: 12.5)),
                      );
                    }(),
                ]),
        ),
        if (f.log.isNotEmpty || f.act.isNotEmpty) ...[
          const SectionTitle('قراءات هذا الجوال'),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('قصص وألعاب انحسبت من جوالك (${Learn.ar(f.log.length)} قصة · ${Learn.ar(f.act.length)} لعبة). لو كنت تتصفح بس، امسحها عشان ما تنحسب على العيال.',
                  style: const TextStyle(color: C.soft, height: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: f.clearMine, child: const Text('مسح قراءات هذا الجوال', style: TextStyle(fontWeight: FontWeight.w800))),
            ]),
          ),
        ],
        const SizedBox(height: 4),
        Text('تصنيفات القصص المقروءة: ${logs.map((e) => byId[e['s']]).whereType<Story>().map((s) => Tonight.catOf(s).$2).toSet().join(' ')}', textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontSize: 13)),
      ],
    );
  }
}

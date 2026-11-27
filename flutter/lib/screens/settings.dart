import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../notify.dart';
import '../remote.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'info.dart';
import 'kid_editor.dart';
import 'library.dart';
import 'link.dart';
import '../widgets/stk.dart';

void toast(BuildContext context, String m) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m, style: const TextStyle(fontFamily: 'Baloo', fontSize: 16, fontWeight: FontWeight.w700)), behavior: SnackBarBehavior.floating));
}

/// اختيار وقت (−/+ ربع ساعة + أوقات سريعة) — نفس الويب
class TimePick extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> quick;
  const TimePick({super.key, required this.value, required this.onChanged, this.quick = const ['19:30', '20:00', '20:30', '21:00']});

  static String fmt(String hm) {
    final m = Family.mins(hm), h = m ~/ 60, mm = m % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '${Learn.ar(h12)}:${Learn.ar(mm.toString().padLeft(2, '0'))}';
  }

  static String part(String hm) {
    final h = Family.mins(hm) ~/ 60;
    return h < 4 ? 'بعد منتصف الليل' : h < 12 ? 'صباحًا' : h < 15 ? 'ظهرًا' : h < 18 ? 'عصرًا' : 'مساءً';
  }

  String _bump(int d) {
    final t = (Family.mins(value) + d + 1440) % 1440;
    return '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget btn(String t, int d) => IconButton.filledTonal(
          onPressed: () {
            HapticFeedback.selectionClick();
            onChanged(_bump(d));
          },
          icon: Text(t, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: C.orange)),
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFF1E2), minimumSize: const Size(52, 52)),
        );
    return Column(children: [
      Row(children: [
        btn('−', -15),
        Expanded(
          child: Column(children: [
            Text(fmt(value), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
            Text('${part(value)} 🌙', style: const TextStyle(color: C.soft, fontWeight: FontWeight.w700)),
          ]),
        ),
        btn('+', 15),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
        for (final q in quick)
          ChoiceChip(
            label: Text(fmt(q), style: TextStyle(fontWeight: FontWeight.w800, color: q == value ? Colors.white : C.ink)),
            selected: q == value,
            selectedColor: C.orange,
            showCheckmark: false,
            backgroundColor: const Color(0xFFF4F7FC),
            side: BorderSide.none,
            onSelected: (_) => onChanged(q),
          ),
      ]),
    ]);
  }
}

/// "وش ينادونكم العيال؟" شرائح + خانة "غير ذلك"
class CallChips extends StatefulWidget {
  final String value;
  final List<String> opts;
  final ValueChanged<String> onChanged;
  const CallChips({super.key, required this.value, required this.opts, required this.onChanged});
  @override
  State<CallChips> createState() => _CallChipsState();
}

class _CallChipsState extends State<CallChips> {
  late final _c = TextEditingController(text: widget.opts.contains(widget.value) ? '' : widget.value);
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      for (final o in widget.opts)
        ChoiceChip(
          label: Text(o, style: TextStyle(fontWeight: FontWeight.w800, color: o == widget.value ? Colors.white : C.ink)),
          selected: o == widget.value,
          selectedColor: C.orange,
          showCheckmark: false,
          backgroundColor: const Color(0xFFF4F7FC),
          side: BorderSide.none,
          onSelected: (_) {
            _c.clear();
            widget.onChanged(o);
          },
        ),
      SizedBox(
        width: 120,
        child: TextField(
          controller: _c,
          maxLength: 12,
          onChanged: (v) {
            if (v.trim().isNotEmpty) widget.onChanged(v.trim());
          },
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            hintText: 'غير ذلك',
            hintStyle: const TextStyle(color: Color(0xFFB3BBCB)),
            filled: true,
            fillColor: const Color(0xFFF4F7FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ),
    ]);
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? sub;
  final List<Widget> children;
  const _Card(this.title, {this.sub, required this.children});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            if (sub != null) Padding(padding: const EdgeInsets.only(top: 2, bottom: 6), child: Text(sub!, style: const TextStyle(color: C.soft, height: 1.5, fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            ...children,
          ]),
        ),
      );
}

Widget _field(TextEditingController c, String hint, {int lines = 1, int max = 140}) => TextField(
      controller: c,
      maxLines: lines,
      maxLength: max,
      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB3BBCB)),
        filled: true,
        fillColor: const Color(0xFFF4F7FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );

Widget _chips(List<(String, String)> items, bool Function(String) on, ValueChanged<String> tap) => Wrap(spacing: 8, runSpacing: 8, children: [
      for (final it in items)
        ChoiceChip(
          label: Text(it.$2, style: TextStyle(fontWeight: FontWeight.w800, color: on(it.$1) ? Colors.white : C.ink)),
          selected: on(it.$1),
          selectedColor: C.orange,
          showCheckmark: false,
          backgroundColor: const Color(0xFFF4F7FC),
          side: BorderSide.none,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            tap(it.$1);
          },
        ),
    ]);

/// الإعدادات (خلف رمز وليّ الأمر) — كل أقسام الويب
class SettingsScreen extends StatefulWidget {
  final String? jump; // 'msg' | 'reward'
  const SettingsScreen({super.key, this.jump});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final f = Family.I;
  late final _msg = TextEditingController(text: (f.fam['msg'] as Map?)?['t']?.toString() ?? '');
  late final _rw = TextEditingController(text: (f.fam['reward'] as Map?)?['text']?.toString() ?? '');
  final _pin = TextEditingController();
  late Object _msgTo = (f.fam['msg'] as Map?)?['to'] ?? 'all';
  late String _msgFrom = ((f.fam['msg'] as Map?)?['from'] ?? f.dad).toString();
  late int _rwStars = ((f.fam['reward'] as Map?)?['stars'] as num?)?.toInt() ?? 5;
  late String _bed = f.bedtime;
  late bool _remind = f.fam['remind'] != false;
  late bool _lockOn = f.fam['lockOn'] == true;
  late String _lock = (f.fam['lock'] ?? '21:30').toString();
  String _ver = '';
  final _msgKey = GlobalKey(), _rwKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    f.addListener(_r);
    Info.version().then((v) => mounted ? setState(() => _ver = v) : null);
    if (widget.jump != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final k = widget.jump == 'msg' ? _msgKey : _rwKey;
        if (k.currentContext != null) Scrollable.ensureVisible(k.currentContext!, duration: const Duration(milliseconds: 400));
      });
    }
  }

  @override
  void dispose() {
    f.removeListener(_r);
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  String get _joinText => 'اربط جهاز الأطفال بعائلتنا في سراج 🌙\nرمز العائلة: ${f.code}\n${Info.site}/#join=${f.code}';

  Future<void> _confirm(String title, String body, VoidCallback ok) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(body, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم')),
        ],
      ),
    );
    if (r == true) ok();
  }

  Widget _link(IconData i, List<Color> g, String t, VoidCallback onTap, {String? trailing, bool danger = false}) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(12)),
          child: Icon(i, color: Colors.white, size: 22),
        ),
        title: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: danger ? const Color(0xFFD33A3A) : C.ink)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (trailing != null) Text(trailing, style: const TextStyle(color: C.soft, fontWeight: FontWeight.w700)),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: C.soft),
        ]),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    final kids = f.kids;
    final dk = f.devKids.map(f.kidById).whereType<Kid>().toList();
    final x = f.fam['extra'];
    final ex = x is Map && x['d'] == f.nightKey ? ((x['n'] as num?)?.toInt() ?? 0) : 0;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: SkyBg.gradient),
        child: ListView(padding: EdgeInsets.fromLTRB(14, top + 8, 14, bottom + 40), children: [
          Row(children: [
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
            const SizedBox(width: 10),
            const Text('⚙️ الإعدادات', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
          ]),
          const SizedBox(height: 14),
          if (f.linked)
            _Card('العائلة والنسخة الاحتياطية 👨‍👩‍👧', sub: 'رمز العائلة هو نسختك الاحتياطية: به تربط جهاز طفل، وبه يرجع كل شيء لو حذفت التطبيق أو غيّرت الجوال. احفظه في مكانٍ آمن.', children: [
              Text('هذا الجهاز: ${f.isChild ? 'جهاز ${dk.isEmpty ? 'طفل' : dk.map((k) => k.name).join(' و')} 🧒' : 'جوال وليّ الأمر 👨‍👩‍👧'}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.purple)),
              const SizedBox(height: 8),
              _chips(const [('parent', '👨‍👩‍👧 جوال وليّ الأمر'), ('child', '🧒 جهاز طفل')], (v) => v == f.role, (v) {
                if (v == f.role) return;
                setState(() {
                  f.role = v;
                  if (v == 'child' && f.devKids.isEmpty) f.devKids = f.kids.map((k) => k.id).toList();
                });
                f.save();
                f.syncNow();
                toast(context, v == 'parent' ? 'صار جوال وليّ الأمر ✓' : 'صار جهاز طفل ✓');
              }),
              if (f.isChild && kids.length > 1) ...[
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhoScreen())), child: const Text('تغيير صاحب الجهاز 👤', style: TextStyle(fontWeight: FontWeight.w800))),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(18)),
                child: Text(f.code, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: 3, fontFamily: 'monospace', color: C.purple)),
              ),
              const SizedBox(height: 12),
              Center(child: QrImageView(data: '${Info.site}/#join=${f.code}', size: 170, backgroundColor: Colors.white)),
              const Text('صوّر الرمز من كاميرا التابلت، أو أرسل له الرابط', textAlign: TextAlign.center, style: TextStyle(color: C.soft, fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: BigButton(label: 'إرسال رابط الربط', onTap: () => SharePlus.instance.share(ShareParams(title: 'ربط سراج', text: _joinText)))),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: f.code));
                      toast(context, 'تم نسخ الرمز ✓');
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('نسخ الرمز', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ]),
            ]),
          _Card('الأطفال 🧒', children: [
            for (final k in f.kidMaps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: KidFace(kid: Kid.fromJson(k), size: 46),
                title: Text(k['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => KidEditor(kid: k))), child: const Text('تعديل')),
                  TextButton(
                    onPressed: () => _confirm('حذف ${k['name']}؟', 'تنحذف شخصيته من كل أجهزة العائلة.', () => f.delKid(k['id'].toString())),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFD33A3A)),
                    child: const Text('حذف'),
                  ),
                ]),
              ),
            if (kids.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('لا يوجد أطفال بعد', textAlign: TextAlign.center, style: TextStyle(color: C.soft))),
            const SizedBox(height: 6),
            OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KidEditor())), child: const Text('+ إضافة طفل', style: TextStyle(fontWeight: FontWeight.w800))),
            const Divider(height: 26),
            const Text('شخصيات بابا وماما في القصص', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              for (final who in ['dad', 'mom'])
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => KidEditor(mode: EditMode.parent, parentWho: who))),
                    child: Column(children: [
                      SizedBox(height: 90, child: KidAvatar(kid: Kid(who == 'dad' ? f.dad : f.mom, who == 'dad' ? 'm' : 'f', av: f.parentAv(who, ArtOpts.allDefaults)))),
                      Text('${who == 'dad' ? f.dad : f.mom} ✏️', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
            ]),
          ]),
          _Card('وش ينادونكم العيال؟ 💛', sub: 'عشان تصير القصص قصة عائلتكم: «قال بابا…»', children: [
            const Text('الأب', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            CallChips(value: f.dad, opts: Family.dadOpts, onChanged: (v) => f.setFam('dad', v)),
            const SizedBox(height: 12),
            const Text('الأم', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            CallChips(value: f.mom, opts: Family.momOpts, onChanged: (v) => f.setFam('mom', v)),
          ]),
          _Card('وقت القصة 🔔', sub: f.isChild ? 'التذكير يوصل لهذا الجهاز في الوقت المحدد.' : 'التذكير يوصل لأجهزة الأطفال المربوطة.', children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🔔 تذكير وقت القصة', style: TextStyle(fontWeight: FontWeight.w800)),
              value: _remind,
              onChanged: (v) async {
                setState(() => _remind = v);
                if (v && !await Notify.ask() && context.mounted) toast(context, 'فعّل إشعارات سراج من إعدادات الجوال');
              },
            ),
            if (!f.isChild)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ذكّرني على هذا الجوال بعد', style: TextStyle(fontWeight: FontWeight.w700)),
                value: f.fam['remindParent'] == true,
                onChanged: (v) async {
                  if (v) await Notify.ask();
                  f.setFam('remindParent', v);
                },
              ),
            TimePick(value: _bed, onChanged: (v) => setState(() => _bed = v)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                f.fam['bedtime'] = _bed;
                f.fam['remind'] = _remind;
                f.famChanged();
                toast(context, 'تم الحفظ ✓');
              },
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: () async {
                if (!await Notify.ask()) {
                  if (context.mounted) toast(context, 'الإشعارات مقفلة — فعّلها من إعدادات الجوال ← التطبيقات ← سراج');
                  return;
                }
                Notify.test();
              },
              child: const Text('🔔 جرّب الإشعار الحين', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
          Container(
            key: _msgKey,
            child: _Card('💌 رسالة للعيال', sub: 'تظهر لهم فوق قصة الليلة لين يضغطون ❤️', children: [
              _field(_msg, 'مثلًا: فخور فيكم اليوم يا أبطال ❤️', lines: 2),
              const SizedBox(height: 10),
              const Text('لمين؟', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              _chips([('all', 'الكل'), ...kids.map((k) => (k.id, k.name))], (v) => v == 'all' ? _msgTo == 'all' : _msgTo is List && (_msgTo as List).contains(v), (v) {
                setState(() {
                  if (v == 'all') {
                    _msgTo = 'all';
                  } else {
                    final l = _msgTo is List ? [...(_msgTo as List)] : <dynamic>[];
                    l.contains(v) ? l.remove(v) : l.add(v);
                    _msgTo = l.isEmpty ? 'all' : l;
                  }
                });
              }),
              const SizedBox(height: 10),
              const Text('من؟', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              _chips([(f.dad, f.dad), (f.mom, f.mom)], (v) => v == _msgFrom, (v) => setState(() => _msgFrom = v)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: BigButton(
                    label: 'إرسال 💌',
                    onTap: () {
                      final t = _msg.text.trim();
                      if (t.isEmpty) return toast(context, 'اكتب الرسالة');
                      f.setFam('msg', {'t': t, 'at': DateTime.now().millisecondsSinceEpoch, 'to': _msgTo, 'from': _msgFrom});
                      toast(context, 'وصلت الرسالة للعيال 💌');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    _msg.clear();
                    f.setFam('msg', null);
                    toast(context, 'انمسحت الرسالة');
                  },
                  child: const Text('مسح الرسالة'),
                ),
              ]),
            ]),
          ),
          Container(
            key: _rwKey,
            child: _Card('🎁 مكافأة الأسبوع', sub: 'كل ليلة يقرون فيها قصة = نجمة. لما يوصلون العدد يكسبون المكافأة اللي تحددها.', children: [
              _field(_rw, 'مثلًا: طلعة للحديقة 🎡', max: 60),
              const SizedBox(height: 10),
              const Text('كم نجمة؟', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              _chips([for (final n in [3, 4, 5, 6, 7]) ('$n', '${Learn.ar(n)} ⭐')], (v) => v == '$_rwStars', (v) => setState(() => _rwStars = int.parse(v))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: BigButton(
                    label: 'حفظ',
                    onTap: () {
                      final t = _rw.text.trim();
                      if (t.isEmpty) return toast(context, 'اكتب المكافأة');
                      f.setFam('reward', {'text': t, 'stars': _rwStars});
                      toast(context, 'تم حفظ المكافأة 🎁');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    _rw.clear();
                    f.setFam('reward', null);
                    toast(context, 'توقفت المكافأة');
                  },
                  child: const Text('إيقاف المكافأة'),
                ),
              ]),
            ]),
          ),
          _Card('الليل والنوم 🌙', children: [
            const Text('كم قصة الليلة؟', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            _chips([for (final n in [1, 2, 3]) ('$n', Learn.ar(n))], (v) => v == '${f.perNight}', (v) => f.setFam('perNight', int.parse(v))),
            const Text('بعد القصة الأولى يظهر لهم زر «القصة التالية» لين يوصلون العدد.', style: TextStyle(color: C.soft, fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                f.giveExtra();
                toast(context, 'صار لهم الليلة ${Learn.ar(f.allowedTonight)} قصص ✨');
              },
              child: const Text('✨ قصة إضافية الليلة بس', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            if (ex > 0) Text('الليلة: ${Learn.ar(f.allowedTonight)} قصص (منها ${Learn.ar(ex)} إضافية)', style: const TextStyle(color: C.purple, fontWeight: FontWeight.w700)),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('✂️ قصص قصيرة للصغار (٣-٥)', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('لعمر ٣-٥: نسخة قصيرة مكتوبة لكل قصة. ٦ سنوات وفوق: القصة كاملة. إذا يقرون مع بعض يمشي على عمر الأصغر.', style: TextStyle(height: 1.5)),
              value: f.shortKids,
              onChanged: (v) {
                f.setFam('shortKids', v);
                toast(context, v ? 'القصص تقصر للصغار (٣-٥) ✂️' : 'كل القصص كاملة 📖');
              },
            ),
            const Divider(height: 24),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('قفل التطبيق وقت النوم', style: TextStyle(fontWeight: FontWeight.w800)), value: _lockOn, onChanged: (v) => setState(() => _lockOn = v)),
            TimePick(value: _lock, quick: const ['21:00', '21:30', '22:00', '22:30'], onChanged: (v) => setState(() => _lock = v)),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('من هذا الوقت لين ٥ الصبح، أجهزة الأطفال تعرض «حان وقت النوم» بس.', style: TextStyle(color: C.soft, fontSize: 13.5, height: 1.5)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                f.fam['lockOn'] = _lockOn;
                f.fam['lock'] = _lock;
                f.famChanged();
                toast(context, 'تم الحفظ ✓');
              },
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
          _Card('مكتبة القصص 📚 (${Learn.ar(Library.stories.length)})', sub: 'اضغط أي قصة لمعاينتها بأسماء أطفالك.', children: [
            BigButton(label: 'افتح المكتبة', icon: Icons.auto_stories_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen(all: true)))),
          ]),
          _Card('رمز وليّ الأمر 🔒', children: [
            Row(children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _pin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'رمز جديد',
                      hintStyle: const TextStyle(color: Color(0xFFB3BBCB), letterSpacing: 0, fontSize: 16),
                      filled: true,
                      fillColor: const Color(0xFFF4F7FC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  if (_pin.text.length != 4) return toast(context, 'الرمز لازم يكون ٤ أرقام');
                  f.setFam('pin', _pin.text);
                  _pin.clear();
                  toast(context, 'تم تغيير الرمز ✓');
                },
                child: const Text('تغيير', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ]),
          const SectionTitle('الأجهزة'),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(children: [
              if (f.isParent && f.linked)
                _link(Icons.system_update_rounded, const [Color(0xFFF07AA8), Color(0xFFC9407A)], 'تحديث كل أجهزة العيال', () {
                  f.refreshAll();
                  toast(context, 'أرسلت أمر التحديث لأجهزة العيال 📲');
                }),
              if (!f.linked) _link(Icons.key_rounded, const [Color(0xFFFEAE47), Color(0xFFF0761C)], 'ربط برمز العائلة', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinScreen()))),
              if (f.linked)
                _link(Icons.link_off_rounded, const [Color(0xFFFF7A7A), Color(0xFFD33A3A)], 'فك ربط هذا الجهاز', danger: true, () {
                  _confirm('فك ربط هذا الجهاز؟', 'ينمسح كل شيء من هالجهاز. بيانات العائلة تبقى محفوظة في الرمز.', () async {
                    await f.unlink();
                    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                  });
                }),
            ]),
          ),
          const SectionTitle('سراج | SIRAJ'),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(children: [
              _link(Icons.info_rounded, const [Color(0xFF7FA6C6), Color(0xFF4E7AA3)], 'حول التطبيق', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()))),
              _link(Icons.ios_share_rounded, const [Color(0xFFFEAE47), Color(0xFFF0761C)], 'مشاركة التطبيق', Info.shareApp),
              _link(Icons.mail_rounded, const [Color(0xFF4FC79A), Color(0xFF21875F)], 'تواصل معنا',
                  () => launchUrl(Uri.parse('mailto:${Info.mail}?subject=${Uri.encodeComponent('سراج — ملاحظة v$_ver')}'))),
              _link(Icons.privacy_tip_rounded, const [Color(0xFF9D7BEA), Color(0xFF6A45C9)], 'سياسة الخصوصية', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
            ]),
          ),
          const SectionTitle('التطبيق'),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: _link(Icons.refresh_rounded, const [Color(0xFF5AC8FA), Color(0xFF2C7FD6)], 'البحث عن تحديثات', trailing: _ver, () => Remote.check(context, manual: true)),
          ),
          const SizedBox(height: 20),
          Text('سراج | SIRAJ — الإصدار $_ver', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: C.soft)),
          const SizedBox(height: 8),
          const WamdLogo(),
        ]),
      ),
    );
  }
}

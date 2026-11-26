import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../nav.dart';
import '../sky.dart';
import '../theme.dart';
import '../tonight_logic.dart';
import '../widgets/common.dart';
import 'kid_editor.dart';

/// تبويب "أنا" = "سمائي" في الويب: غرفتي، إنجازاتي، عائلتي، لوحة الشرف، تقويم الشهر، الكوكبة، الهدايا، ألبوم الملصقات
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});
  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final f = Family.I;
  int _k = 0;

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

  List<Kid> get _kids => f.kids.isNotEmpty ? f.myKids : [Profile.hero ?? const Kid('بطلنا', 'm')];
  String gx(Kid k, String m, String fm) => k.isGirl ? fm : m;

  void _card(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              child,
              const SizedBox(height: 14),
              BigButton(label: 'حلو! 👍', onTap: () => Navigator.pop(ctx)),
            ]),
          ),
        ),
      ),
    );
  }

  String _cheer(Kid k, String value) {
    final n = k.name, g = k.isGirl;
    final l = [
      value.isNotEmpty ? 'يا $n، ${g ? 'أنتِ بطلة' : 'أنت بطل'} $value اليوم! 🏅' : 'يا $n، ${g ? 'أنتِ نجمة' : 'أنت نجم'} العيلة! 🌟',
      'كل قصة ${g ? 'تقرينها' : 'تقراها'} تخلي سماك تلمع أكثر ✨',
      '${g ? 'كمّلي' : 'كمّل'} يا $n، الكوكبة الجاية قريبة! 🚀',
      'ما شاء الله يا $n، ${g ? 'شاطرة ومجتهدة' : 'شاطر ومجتهد'} 💪',
    ];
    return l[DateTime.now().millisecond % l.length];
  }

  Widget _big(String e) => Text(e, textAlign: TextAlign.center, style: const TextStyle(fontSize: 62));
  Widget _h(String t) => Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800));
  Widget _p(String t, {bool cheer = false}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.6, fontWeight: cheer ? FontWeight.w800 : FontWeight.w600, color: cheer ? C.purple : C.ink)),
      );

  /* ---------------- تفاصيل يوم في التقويم ---------------- */
  void _dayInfo(Kid k, String day, List<Map<String, dynamic>> ev) {
    final es = ev.where((e) => e['d'] == day).toList();
    final d = DateTime.parse('${day}T12:00:00');
    const wd = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    var lastValue = '';
    final rows = <Widget>[];
    Widget li(String ic, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ic, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 15.5, height: 1.6, fontWeight: FontWeight.w600))),
          ]),
        );
    for (final e in es) {
      final (em, r) = e['st'] as (String, String);
      final rn = Sky.rarity[r]!;
      if (e['type'] == 'story') {
        final st = Tonight.byId(e['s'].toString());
        if (st != null) lastValue = st.value;
        rows.add(li('⭐', 'نجمة لأن${gx(k, 'ك', 'كِ')} ${gx(k, 'قريت', 'قريتي')} «${st != null ? fillTemplate(st.title, k, dad: f.dad, mom: f.mom) : 'قصة'}»${st != null ? ' و${gx(k, 'تعلّمت', 'تعلّمتِ')} ${st.value}' : ''}'));
        rows.add(li(em, '${rn.$1} ${rn.$2}: ${Sky.stNames[em] ?? ''}، ${gx(k, 'كسبته', 'كسبتيه')} من القصة'));
      } else {
        rows.add(li(em, '${rn.$1} ${rn.$2}: ${Sky.stNames[em] ?? ''}، لأن${gx(k, 'ك', 'كِ')} ${Sky.actName[e['type']] ?? 'لعبت'}'));
      }
    }
    _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _h('${wd[d.weekday - 1]} ${Learn.ar(d.day)} ${Sky.months[d.month - 1]} 🌟'),
      const SizedBox(height: 12),
      ...rows,
      _p(_cheer(k, lastValue), cheer: true),
    ]));
  }

  void _emptyDay(Kid k, bool today) => _card(Column(children: [
        _big(today ? '🌙' : '💤'),
        _h(today ? 'اليوم لسا ما فيه نجمة' : 'هاليوم ما فيه نجمة'),
        _p(today ? '${gx(k, 'اقرأ', 'اقرئي')} قصة الليلة و${gx(k, 'خذ', 'خذي')} نجمة ⭐ وملصق جديد!' : 'ولا يهم! كل يوم فرصة جديدة، ${gx(k, 'كمّل', 'كمّلي')} يا ${k.name} 💪', cheer: true),
      ]));

  void _stkInfo(Kid k, int i, List<Map<String, dynamic>> ev) {
    final (em, r) = Sky.allStickers[i];
    final rn = Sky.rarity[r]!;
    final mine = ev.where((e) => (e['st'] as (String, String)).$1 == em).toList();
    if (mine.isEmpty) {
      return _card(Column(children: [
        _big('❓'),
        _h('ملصق مقفّل 🔒'),
        _p(r == 'l' ? 'ملصق أسطوري 🌟 وصعب يطلع! بس مع كل قصة ولعبة فيه فرصة.' : r == 'r' ? 'ملصق نادر 🟣، يطلع أحيانًا مع القصص والألعاب.' : 'ملصق عادي، أكيد يطلع لك قريب!'),
        _p('${gx(k, 'اقرأ', 'اقرئي')} و${gx(k, 'العب', 'العبي')}، يمكن يطلع ${gx(k, 'لك', 'لكِ')} المرة الجاية! 🍀', cheer: true),
      ]));
    }
    final first = mine.first, fd = DateTime.fromMillisecondsSinceEpoch(((first['t'] as num?) ?? 0).toInt());
    final st = first['type'] == 'story' ? Tonight.byId(first['s'].toString()) : null;
    final from = first['type'] == 'story' ? (st != null ? 'قصة «${fillTemplate(st.title, k)}»' : 'قصة') : (Sky.actName[first['type']] ?? 'لعبة');
    _card(Column(children: [
      _big(em),
      _h('${Sky.stNames[em] ?? ''} ${rn.$2}'),
      _p('${rn.$1} · ${gx(k, 'كسبته', 'كسبتيه')} ${mine.length == 1 ? 'مرة وحدة' : '${Learn.ar(mine.length)} مرات'}'),
      _p('أول مرة: ${Learn.ar(fd.day)} ${Sky.months[fd.month - 1]}، من $from'),
      _p(r == 'l' ? 'واو! هذا من أندر الملصقات 🤩' : r == 'r' ? 'محظوظ${gx(k, '', 'ة')}! ملصق نادر 🟣' : _cheer(k, ''), cheer: true),
    ]));
  }

  void _accInfo(Kid k, int i) {
    final a = Sky.acc[i];
    final (n, done, _) = Sky.info(k);
    final cname = Sky.consts[i % Sky.consts.length];
    if (i >= done) {
      final left = (i + 1) * 7 - n;
      return _card(Column(children: [
        _big(a['icon'].toString()),
        _h('${a['name']} 🔒'),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (n / ((i + 1) * 7)).clamp(0, 1).toDouble(), minHeight: 10, color: C.orange, backgroundColor: const Color(0xFFF0F3F9))),
        _p('باقي ${Learn.ar(left)} ${left == 1 ? 'قصة' : 'قصص'} و${gx(k, 'تفتح', 'تفتحين')} ${a['name']} مع $cname ✨'),
        _p('${gx(k, 'اقرأ', 'اقرئي')} كل ليلة، وتوصل${gx(k, '', 'ين')}! 🚀', cheer: true),
      ]));
    }
    final on = (k.av?['acc'] ?? '') == a['id'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _big(a['icon'].toString()),
            _h('${a['name']} 🎁'),
            _p('${gx(k, 'فتحته', 'فتحتيه')} لما ${gx(k, 'أكملت', 'أكملتِ')} $cname ✨'),
            _p(_cheer(k, ''), cheer: true),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: BigButton(
                  label: '${on ? 'اخلعه' : 'البسه'} ${a['icon']}',
                  onTap: () {
                    _wear(k, on ? '' : a['id'].toString());
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(width: 10),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
            ]),
          ]),
        ),
      ),
    );
  }

  void _wear(Kid k, String accId) {
    final av = {...?k.av, 'acc': accId};
    if (f.isParent) {
      final m = f.kidMaps.firstWhere((x) => x['id'] == k.id, orElse: () => <String, dynamic>{});
      if (m.isNotEmpty) {
        f.saveKid({...m, 'av': av, 'avAt': DateTime.now().millisecondsSinceEpoch});
      }
    } else {
      f.saveKidLook(k.id, av);
    }
    if (accId.isNotEmpty) {
      final a = Sky.acc.firstWhere((x) => x['id'] == accId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لابس${k.isGirl ? 'ة' : ''} ${a['name']} ✨')));
    }
  }

  void _edit(Kid k, {bool self = true}) {
    final m = f.kidMaps.where((x) => x['id'] == k.id).toList();
    if (m.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => KidEditor(kid: m.first, mode: self ? EditMode.self : EditMode.full)));
  }

  /* ---------------- البطاقات ---------------- */
  Widget _room(Kid k) {
    final stars = Sky.stats(k, 0)['nights'] as int;
    final items = Sky.roomItems;
    Map<String, dynamic>? next;
    for (final it in items) {
      if (stars < (it['stars'] as num)) {
        next = it;
        break;
      }
    }
    final got = items.where((it) => stars >= (it['stars'] as num)).length;
    final prevStars = items.where((it) => stars >= (it['stars'] as num)).fold<num>(0, (m, it) => it['stars'] as num);
    final pct = next != null ? ((stars - prevStars) / ((next['stars'] as num) - prevStars)).clamp(.06, 1.0).toDouble() : 1.0;
    final stk = Sky.events(k).map((e) => (e['st'] as (String, String)).$1).toList();
    final board = stk.length > 8 ? stk.sublist(stk.length - 8) : stk;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('غرفة ${k.name} 🏠', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFF6D6), borderRadius: BorderRadius.circular(14)),
            child: Text('⭐ ${Learn.ar(stars)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 360 / 240,
            child: LayoutBuilder(builder: (_, box) {
              final s = box.maxWidth / 360;
              return Stack(children: [
                Positioned.fill(child: SvgPicture.string(Sky.roomSvg(stars), fit: BoxFit.fill)),
                if (board.isEmpty)
                  Positioned(left: 230 * s, top: 46 * s, width: 90 * s, child: Text('لوحة ملصقاتي', textAlign: TextAlign.center, style: TextStyle(fontSize: 11 * s, color: const Color(0xFFB08560))))
                else
                  for (var i = 0; i < board.length; i++)
                    Positioned(left: (235 + (i % 4) * 22) * s, top: (30 + (i ~/ 4) * 24) * s, child: Text(board[i], style: TextStyle(fontSize: 16 * s, height: 1))),
                Positioned(left: 130 * s, top: 128 * s, width: 70 * s, height: 80 * s, child: KidAvatar(kid: k)),
              ]);
            }),
          ),
        ),
        const SizedBox(height: 10),
        Text(next != null ? '${Learn.ar((next['stars'] as num) - stars)} ${(next['stars'] as num) - stars == 1 ? 'نجمة' : 'نجوم'} وينفتح لك ${next['name']} 🎁' : '🏆 غرفتك كاملة! أنت بطل القراءة',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: pct, minHeight: 9, color: C.orange, backgroundColor: const Color(0xFFF0F3F9))),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: .85,
          children: [
            for (final it in items)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: stars >= (it['stars'] as num) ? const Color(0xFFF5EFFF) : const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Expanded(child: Opacity(opacity: stars >= (it['stars'] as num) ? 1 : .35, child: SvgPicture.string(Sky.itemSvg(it)))),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(stars >= (it['stars'] as num) ? it['name'].toString() : '🔒 ${Learn.ar(it['stars'])} ⭐', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text('كل ليلة تقرأ فيها قصة = نجمة ⭐ والملصقات اللي تجمعها تتعلّق على لوحتك (${Learn.ar(got)} من ${Learn.ar(items.length)})', style: const TextStyle(color: C.soft, fontSize: 12.5)),
      ]),
    );
  }

  Widget _ach(Kid k) {
    final all = Sky.stats(k, 0), ev = Sky.events(k);
    final (_, done, cur) = Sky.info(k);
    final rare = ev.where((e) => (e['st'] as (String, String)).$2 != 'c').length, bdg = Sky.badgesOf(k).where((b) => b.$3).length;
    final ts = Sky.titlesFor(f.kids, Sky.weekStart()).$1[k.id] ?? [];
    final left = 7 - cur;
    Widget cell(String e, String n, String l) => Expanded(
          child: Column(children: [
            Text(e, style: const TextStyle(fontSize: 26)),
            Text(n, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            FittedBox(fit: BoxFit.scaleDown, child: Text(l, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700))),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7A4BE0), Color(0xFFB15BE8)]), borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('🌟 إنجازات ${k.name}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(ts.isNotEmpty ? 'هذا الأسبوع أنت ${ts.map((t) => t.$2).join(' و')}! 🎉' : 'كل قصة تقراها تقرّبك من هدية جديدة ✨', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          cell('⭐', Learn.ar(all['nights']), 'نجمة'),
          cell('🎁', Learn.ar(ev.length), rare > 0 ? 'ملصق · ${Learn.ar(rare)} نادر' : 'ملصق'),
          cell('🛡️', Learn.ar(done.clamp(0, Sky.acc.length)), 'هدية'),
          cell('🏅', Learn.ar(bdg), 'شارة'),
        ]),
        const SizedBox(height: 12),
        Text('🎯 باقي ${Learn.ar(left)} ${left == 1 ? 'قصة' : 'قصص'} وتكتمل كوكبة جديدة وتفتح هدية 🎁', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: cur / 7, minHeight: 9, color: const Color(0xFFFFD23F), backgroundColor: Colors.white24)),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _badges,
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: const Text('🎖️ كل الشارات', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _family() {
    final me = f.isChild ? f.devKids : <String>[];
    final members = <(Kid, String, bool)>[
      if (f.kids.isNotEmpty) (Kid(f.dad, 'm', id: 'dad', av: f.parentAv('dad', ArtOpts.allDefaults)), 'dad', true),
      if (f.kids.isNotEmpty) (Kid(f.mom, 'f', id: 'mom', av: f.parentAv('mom', ArtOpts.allDefaults)), 'mom', true),
      for (final k in f.kids) (k, k.id, false),
    ];
    if (members.isEmpty) return const SizedBox();
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('👨‍👩‍👧‍👦 عائلتي', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 128,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final m in members)
              () {
                final can = f.isParent || me.contains(m.$2);
                return GestureDetector(
                  onTap: !can
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          if (m.$3) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => KidEditor(mode: EditMode.parent, parentWho: m.$2)));
                          } else {
                            _edit(m.$1, self: !f.isParent);
                          }
                        },
                  child: Container(
                    width: 84,
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: me.contains(m.$2) ? const Color(0xFFFFF1E2) : const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(18),
                      border: me.contains(m.$2) ? Border.all(color: C.orange, width: 2) : null,
                    ),
                    child: Column(children: [
                      Expanded(child: KidAvatar(kid: m.$1)),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(m.$1.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                      Text(m.$3 ? (m.$2 == 'dad' ? '👨' : '👩') : '⭐ ${Learn.ar(f.monthNights(m.$1))}${can ? ' ✏️' : ''}', style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                );
              }(),
          ]),
        ),
        Text(f.isParent ? 'اضغط أي شخصية تعدّلها. النجوم = ليالي القراءة هالشهر.' : 'تقدر تغيّر شكلك أنت ✏️', style: const TextStyle(color: C.soft, fontSize: 12.5)),
      ]),
    );
  }

  Widget _honor() {
    final kids = f.kids;
    if (kids.isEmpty) return const SizedBox();
    final (out, st) = Sky.titlesFor(kids, Sky.weekStart());
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text.rich(TextSpan(children: [
          TextSpan(text: '🏆 لوحة شرف العائلة  ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          TextSpan(text: 'هذا الأسبوع', style: TextStyle(fontSize: 13, color: C.soft, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(height: 8),
        for (final (k, s) in st)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              KidFace(kid: k, size: 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(k.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if ((out[k.id] ?? []).isEmpty) const Text('كمّل وتاخذ لقب ✨', style: TextStyle(color: C.soft, fontSize: 13, fontStyle: FontStyle.italic)),
                    for (final t in out[k.id] ?? [])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFFF1C9), borderRadius: BorderRadius.circular(10)),
                        child: Text('${t.$1} ${t.$2}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
                  ]),
                  Text('📖 ${Learn.ar(s['nights'])} ليالٍ · 🤲 ${Learn.ar(s['adhkar'])} · 🔤 ${Learn.ar(s['en'])} · 🪐 ${Learn.ar(s['space'])}', style: const TextStyle(color: C.soft, fontSize: 12.5)),
                ]),
              ),
            ]),
          ),
        OutlinedButton(onPressed: _badges, child: const Text('🎖️ شارات الإنجازات', style: TextStyle(fontWeight: FontWeight.w800))),
      ]),
    );
  }

  void _badges() {
    final kids = f.isChild ? f.myKids : (f.kids.isNotEmpty ? f.kids : _kids);
    _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _h('🎖️ شارات الإنجازات'),
      for (final k in kids) ...[
        const SizedBox(height: 12),
        Row(children: [KidFace(kid: k, size: 36), const SizedBox(width: 8), Text(k.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            for (final b in Sky.badgesOf(k))
              Container(
                decoration: BoxDecoration(color: b.$3 ? const Color(0xFFFFF6D6) : const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(16)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(b.$3 ? b.$1 : '🔒', style: const TextStyle(fontSize: 28)),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(b.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: b.$3 ? C.ink : C.soft))),
                ]),
              ),
          ],
        ),
      ],
    ]));
  }

  Widget _month(Kid k, List<Map<String, dynamic>> ev) {
    final now = DateTime.now(), y = now.year, m = now.month, td = now.day;
    final days = DateTime(y, m + 1, 0).day;
    final firstDow = DateTime(y, m, 1).weekday % 7; // الأحد = 0
    final pre = (firstDow + 1) % 7; // الأسبوع يبدأ السبت
    String key(int d) => '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final e in ev) {
      (byDay[e['d'].toString()] ??= []).add(e);
    }
    final mk = '$y-${m.toString().padLeft(2, '0')}';
    final inMonth = ev.where((e) => e['d'].toString().startsWith(mk)).toList();
    final nights = inMonth.where((e) => e['type'] == 'story').map((e) => e['d']).toSet();
    final ns = nights.length;
    var streak = 0;
    for (var d = nights.contains(key(td)) ? td : td - 1; d >= 1 && nights.contains(key(d)); d--) {
      streak++;
    }
    final goal = ns >= 20 ? '🏆 ${gx(k, 'بطل', 'بطلة')} الشهر!' : ns >= 10 ? '🥈 قربت من البطولة!' : '🎯 هدف الشهر: ٢٠ ليلة';
    final cells = <Widget>[for (final w in ['سبت', 'أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع']) Center(child: Text(w, style: const TextStyle(fontSize: 11, color: C.soft, fontWeight: FontWeight.w800)))];
    for (var i = 0; i < pre; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= days; d++) {
      final es = byDay[key(d)] ?? [];
      final story = es.any((e) => e['type'] == 'story'), today = d == td, fut = d > td;
      final stk = es.map((e) => e['st'] as (String, String)).toList();
      (String, String)? best;
      for (final r in ['l', 'r']) {
        for (final x in stk) {
          if (best == null && x.$2 == r) best = x;
        }
      }
      best ??= stk.isNotEmpty ? stk.last : null;
      final main = story ? '⭐' : best != null ? best.$1 : today ? '🌙' : '';
      cells.add(GestureDetector(
        onTap: fut ? null : () => es.isNotEmpty ? _dayInfo(k, key(d), ev) : _emptyDay(k, today),
        child: Container(
          decoration: BoxDecoration(
            color: story ? const Color(0xFF2C2F5C) : es.isNotEmpty ? const Color(0xFFF3EEFF) : fut ? Colors.transparent : const Color(0xFFF4F7FC),
            borderRadius: BorderRadius.circular(10),
            border: today ? Border.all(color: C.orange, width: 2) : null,
          ),
          child: Stack(children: [
            Positioned(top: 2, right: 4, child: Text(Learn.ar(d), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: story ? Colors.white70 : fut ? const Color(0xFFC9D2E3) : C.soft))),
            if (main.isNotEmpty) Center(child: Padding(padding: const EdgeInsets.only(top: 6), child: Text(main, style: const TextStyle(fontSize: 16)))),
            if (story && best != null) Positioned(bottom: 0, left: 2, child: Text(best.$1, style: const TextStyle(fontSize: 10))),
          ]),
        ),
      ));
    }
    Widget stat(String n, String l) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [Text(n, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), Text(l, style: const TextStyle(fontSize: 12, color: C.soft, fontWeight: FontWeight.w700))]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text('🗓 ${Sky.months[m - 1]}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text(goal, style: const TextStyle(fontWeight: FontWeight.w800, color: C.purple, fontSize: 13.5)),
      ]),
      const SizedBox(height: 8),
      Row(children: [stat(Learn.ar(ns), '⭐ ليلة'), stat(Learn.ar(inMonth.length), '🎁 ملصق'), stat(Learn.ar(streak), '🔥 متتالية')]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: ns / days, minHeight: 9, color: C.purple, backgroundColor: const Color(0xFFF0F3F9))),
      Text('${Learn.ar(ns)} من ${Learn.ar(days)}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: C.soft)),
      const SizedBox(height: 6),
      GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 4, crossAxisSpacing: 4, children: cells),
      const SizedBox(height: 6),
      Text('👆 اضغط أي يوم وشوف وش ${gx(k, 'كسبت', 'كسبتي')} فيه', textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontSize: 13)),
    ]);
  }

  Widget _skyCard(Kid k) {
    final (n, done, cur) = Sky.info(k);
    final ev = Sky.events(k);
    final name = Sky.consts[done % Sky.consts.length], left = 7 - cur;
    final have = <String, int>{};
    for (final e in ev) {
      final em = (e['st'] as (String, String)).$1;
      have[em] = (have[em] ?? 0) + 1;
    }
    final got = Sky.allStickers.where((s) => have.containsKey(s.$1)).length;
    final canEdit = k.id.isNotEmpty && (f.isParent || f.devKids.contains(k.id) || f.isChild);
    Widget chip(String t) => Container(
          margin: const EdgeInsetsDirectional.only(end: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(12)),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        );
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(width: 76, height: 104, child: KidAvatar(kid: k)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('سماء ${k.name}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(children: [chip('⭐ ${Learn.ar(n)}'), chip('✨ ${Learn.ar(done)}'), chip('🎁 ${Learn.ar(ev.length)}')]),
            ]),
          ),
          if (canEdit) TextButton(onPressed: () => _edit(k, self: !f.isParent), child: const Text('✏️ غيّر شكلي', style: TextStyle(fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        _month(k, ev),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(18), child: AspectRatio(aspectRatio: 1.5, child: SvgPicture.string(Sky.skySvg(done, cur), fit: BoxFit.fill))),
        const SizedBox(height: 6),
        Text('$name · ${Learn.ar(cur)}/٧', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: C.purple)),
        Text(cur == 0 && n > 0 ? 'بدأت كوكبة جديدة! 🌟' : 'باقي ${Learn.ar(left)} ${left == 1 ? 'قصة' : 'قصص'} وتكتمل الكوكبة، و${gx(k, 'تفتح', 'تفتحين')} هدية جديدة 🎁',
            textAlign: TextAlign.center, style: const TextStyle(color: C.soft, fontWeight: FontWeight.w600)),
        if (done > 0) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
            for (var i = 0; i < done; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF2C2F5C), borderRadius: BorderRadius.circular(12)),
                child: Text('✨ ${Sky.consts[i % Sky.consts.length]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
          ]),
        ],
        const SizedBox(height: 14),
        Text('هدايا ${k.name} 🎁', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: .9,
          children: [
            for (var i = 0; i < Sky.acc.length; i++)
              GestureDetector(
                onTap: () => _accInfo(k, i),
                child: Container(
                  decoration: BoxDecoration(
                    color: (k.av?['acc'] ?? '') == Sky.acc[i]['id'] ? const Color(0xFFFFF1E2) : i < done ? const Color(0xFFF5EFFF) : const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(16),
                    border: (k.av?['acc'] ?? '') == Sky.acc[i]['id'] ? Border.all(color: C.orange, width: 2) : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Stack(children: [
                      Opacity(opacity: i < done ? 1 : .35, child: Text(Sky.acc[i]['icon'].toString(), style: const TextStyle(fontSize: 28))),
                      if (i >= done) const Positioned(bottom: 0, right: 0, child: Text('🔒', style: TextStyle(fontSize: 12))),
                    ]),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(i < done ? Sky.acc[i]['name'].toString() : 'باقي ${Learn.ar(((i + 1) * 7 - n).clamp(0, 999))}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text('ألبوم الملصقات (${Learn.ar(got)}/${Learn.ar(Sky.allStickers.length)}) 📒', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 0; i < Sky.allStickers.length; i++)
              GestureDetector(
                onTap: () => _stkInfo(k, i, ev),
                child: Container(
                  decoration: BoxDecoration(
                    color: have.containsKey(Sky.allStickers[i].$1) ? Colors.white : const Color(0xFFF0F3F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Sky.allStickers[i].$2 == 'l' ? const Color(0xFFFFC233) : Sky.allStickers[i].$2 == 'r' ? const Color(0xFFB57BEA) : const Color(0xFFE3E8F1),
                      width: Sky.allStickers[i].$2 == 'c' ? 1 : 2,
                    ),
                  ),
                  child: Stack(children: [
                    Center(child: Text(have.containsKey(Sky.allStickers[i].$1) ? Sky.allStickers[i].$1 : '?', style: TextStyle(fontSize: have.containsKey(Sky.allStickers[i].$1) ? 22 : 16, color: C.soft, fontWeight: FontWeight.w800))),
                    if ((have[Sky.allStickers[i].$1] ?? 0) > 1)
                      Positioned(bottom: 1, left: 3, child: Text('×${Learn.ar(have[Sky.allStickers[i].$1]!)}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: C.purple))),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('🟣 نادر · 🌟 أسطوري: حظك مع كل قصة ولعبة!', style: TextStyle(color: C.soft, fontSize: 13)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kids = _kids;
    if (_k >= kids.length) _k = 0;
    final k = kids[_k];
    return TabPage(
      title: 'سمائي',
      subtitle: k.isGirl ? 'نجومك وهداياك يا بطلة ⭐' : 'نجومك وهداياك يا بطل ⭐',
      trailing: IconButton.filledTonal(
        onPressed: () => Nav.go(0),
        style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .85)),
        icon: const Text('🌙', style: TextStyle(fontSize: 20)),
      ),
      children: [
        if (kids.length > 1) ...[Pills(items: kids.map((e) => e.name).toList(), index: _k, onTap: (i) => setState(() => _k = i)), const SizedBox(height: 12)],
        if (k.id.isNotEmpty) ...[_room(k), const SizedBox(height: 12)],
        if (f.isChild && k.id.isNotEmpty) ...[_ach(k), const SizedBox(height: 12)],
        if (Family.I.fam['reward'] is Map && k.id.isNotEmpty) ...[_reward(k), const SizedBox(height: 12)],
        _family(),
        const SizedBox(height: 12),
        _honor(),
        const SizedBox(height: 12),
        _skyCard(k),
      ],
    );
  }

  Widget _reward(Kid k) {
    final r = f.fam['reward'] as Map;
    final need = (r['stars'] as num?)?.toInt() ?? 5;
    final got = (Sky.stats(k, Sky.weekStart())['nights'] as int).clamp(0, need);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF6E0), Color(0xFFFFE9C2)]), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🎁', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('مكافأة الأسبوع', style: TextStyle(fontSize: 13, color: Color(0xFFB76E00), fontWeight: FontWeight.w800)),
              Text(r['text'].toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < need; i++) Opacity(opacity: i < got ? 1 : .25, child: const Text('⭐', style: TextStyle(fontSize: 22))),
          const Spacer(),
          Text(got >= need ? 'كسبتها! 🎉' : '${Learn.ar(got)}/${Learn.ar(need)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        const Text('كل ليلة تقرأ فيها قصة = نجمة ⭐ (الأسبوع يبدأ من الأحد)', style: TextStyle(fontSize: 12.5, color: C.soft)),
      ]),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// خيارات الشخصيات من art.js (assets/data/art.json)
class ArtOpts {
  static Map<String, dynamic> d = {};
  static Future<void> load() async {
    try {
      d = Map<String, dynamic>.from(jsonDecode(await rootBundle.loadString('assets/data/art.json')) as Map);
    } catch (_) {}
  }

  static List<(String, String)> pairs(String k, String g) =>
      (((d[k] as Map?)?[g] as List?) ?? []).map((r) => ((r as List)[0].toString(), r[1].toString())).toList();
  static List<(String, String)> list2(String k) => ((d[k] as List?) ?? []).map((r) => ((r as List)[0].toString(), r[1].toString())).toList();
  static List<String> colors(String k) => ((d[k] as List?) ?? []).map((x) => x.toString()).toList();
  static List<String> styles(String g) => (((d['STYLES'] as Map?)?[g] as List?) ?? []).map((x) => x.toString()).toList();
  static Map<String, dynamic> defaults(String g) => Map<String, dynamic>.from(((d['DEFAULTS'] as Map?)?[g] as Map?) ?? {});
  static Map<String, dynamic> get allDefaults => Map<String, dynamic>.from((d['DEFAULTS'] as Map?) ?? {});
  /// [id, الاسم، الدوري، النمط، لون١، لون٢]
  static List<List<String>> get clubs => ((d['CLUBS'] as List?) ?? []).map((r) => (r as List).map((x) => x.toString()).toList()).toList();
}

enum EditMode { full, self, parent }

/// تعديل طفل (أو شخصية بابا/ماما، أو الطفل يغيّر شكله بنفسه) — نفس نافذة الويب
class KidEditor extends StatefulWidget {
  final Map<String, dynamic>? kid;
  final EditMode mode;
  final String parentWho; // dad | mom
  const KidEditor({super.key, this.kid, this.mode = EditMode.full, this.parentWho = ''});
  @override
  State<KidEditor> createState() => _KidEditorState();
}

class _KidEditorState extends State<KidEditor> {
  late Map<String, dynamic> e;
  late Map<String, dynamic> a;
  late final TextEditingController _name;
  int _tab = 0;
  String? _league;

  @override
  void initState() {
    super.initState();
    if (widget.mode == EditMode.parent) {
      final who = widget.parentWho;
      e = {'id': 'p-$who', 'name': who == 'dad' ? Family.I.dad : Family.I.mom, 'g': who == 'dad' ? 'm' : 'f', 'age': 0};
      a = Family.I.parentAv(who, ArtOpts.allDefaults);
    } else if (widget.kid != null) {
      e = jsonDecode(jsonEncode(widget.kid)) as Map<String, dynamic>;
      a = Map<String, dynamic>.from((e['av'] as Map?) ?? ArtOpts.defaults(e['g'] == 'f' ? 'f' : 'm'));
    } else {
      e = {'id': Family.uid(), 'name': '', 'g': 'm', 'age': 2};
      a = ArtOpts.defaults('m');
    }
    if (a['head'] == null) a['head'] = a['hijab'] == 1 ? 'hijab' : '';
    _name = TextEditingController(text: (e['name'] ?? '').toString());
  }

  String get g => e['g'] == 'f' ? 'f' : 'm';
  Kid get _preview => Kid(_name.text.isEmpty ? 'بطل' : _name.text, g, av: Map<String, dynamic>.from(a));

  void _set(VoidCallback f) {
    HapticFeedback.selectionClick();
    setState(f);
  }

  void _save() {
    if (widget.mode == EditMode.parent) {
      Family.I.saveParentAv(widget.parentWho, a);
      Navigator.pop(context, true);
      return;
    }
    if (widget.mode == EditMode.self) {
      Family.I.saveKidLook(e['id'].toString(), a);
      Navigator.pop(context, true);
      return;
    }
    final n = _name.text.trim();
    if (n.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم الطفل')));
      return;
    }
    e['name'] = n;
    e['av'] = a;
    e['avAt'] = DateTime.now().millisecondsSinceEpoch;
    Family.I.saveKid(e);
    Navigator.pop(context, true);
  }

  Widget _seg(List<(String, String)> items, String cur, ValueChanged<String> on) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final it in items)
          ChoiceChip(
            label: Text(it.$2, style: TextStyle(fontWeight: FontWeight.w800, color: it.$1 == cur ? Colors.white : C.ink)),
            selected: it.$1 == cur,
            selectedColor: C.orange,
            backgroundColor: const Color(0xFFF4F7FC),
            showCheckmark: false,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (_) => _set(() => on(it.$1)),
          ),
      ]);

  Widget _sw(String key, String colorsKey) {
    final cs = ArtOpts.colors(colorsKey);
    final cur = (a[key] as num?)?.toInt() ?? 0;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (var i = 0; i < cs.length; i++)
        GestureDetector(
          onTap: () => _set(() => a[key] = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hexColor(cs[i]),
              shape: BoxShape.circle,
              border: Border.all(color: cur == i ? C.orange : const Color(0xFFDDE3EE), width: cur == i ? 3.5 : 1.5),
            ),
          ),
        ),
    ]);
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.fromLTRB(2, 14, 2, 8), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)));

  List<Widget> _basics() => [
        _label('الاسم'),
        TextField(
          controller: _name,
          maxLength: 20,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'اسم الطفل',
            hintStyle: const TextStyle(color: Color(0xFFB3BBCB)),
            filled: true,
            fillColor: const Color(0xFFF4F7FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        _label('ولد أو بنت'),
        _seg(const [('m', 'ولد'), ('f', 'بنت')], g, (v) {
          if (v != g) {
            e['g'] = v;
            a = ArtOpts.defaults(v);
            a['head'] ??= '';
          }
        }),
        _label('العمر'),
        _seg(const [('1', '٣-٥'), ('2', '٦-٨'), ('3', '٩-١٢')], '${e['age'] ?? 2}', (v) => e['age'] = int.parse(v)),
      ];

  List<Widget> _face() {
    final head = (a['head'] ?? '').toString();
    final styles = ArtOpts.styles(g);
    return [
      _label('لون البشرة'),
      _sw('skin', 'SKIN'),
      _label('غطاء الرأس'),
      _seg(ArtOpts.pairs('HEADS', g), head, (v) {
        a['head'] = v;
        a['hijab'] = v == 'hijab' ? 1 : 0;
      }),
      if (head == 'hijab') ...[_label('لون الحجاب'), _sw('hc', 'HEADC')],
      if (head.isEmpty) ...[
        _label('تسريحة الشعر'),
        _seg([for (var i = 0; i < styles.length; i++) ('$i', styles[i])], '${a['style'] ?? 0}', (v) => a['style'] = int.parse(v)),
        _label('لون الشعر'),
        _sw('hair', 'HAIR'),
      ],
    ];
  }

  List<Widget> _wear() {
    final outfit = (a['outfit'] ?? 'tee').toString();
    final clubs = ArtOpts.clubs;
    final curClub = (a['club'] ?? 'hilal').toString();
    _league ??= clubs.firstWhere((c) => c[0] == curClub, orElse: () => clubs.isNotEmpty ? clubs.first : ['', '', 'sa']).elementAt(2);
    return [
      _label('اللبس'),
      _seg(ArtOpts.pairs('OUTFITS', g), outfit, (v) => a['outfit'] = v),
      if (outfit == 'jersey') ...[
        _label('⚽ اختر ناديك'),
        _seg(ArtOpts.list2('LEAGUES'), _league!, (v) => _league = v),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in clubs.where((c) => c[2] == _league))
            GestureDetector(
              onTap: () => _set(() => a['club'] = c[0]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: curClub == c[0] ? C.orange : const Color(0xFFE6EAF2), width: curClub == c[0] ? 2.5 : 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [hexColor(c[4]), hexColor(c[4]), hexColor(c[5]), hexColor(c[5])], stops: const [0, .5, .5, 1]),
                      border: Border.all(color: const Color(0x22000000)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(c[1], style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
        ]),
        _label('رقم القميص'),
        _seg([for (final n in [7, 9, 10, 11, 17, 19, 20]) ('$n', '$n')], '${a['num'] ?? 10}', (v) => a['num'] = int.parse(v)),
      ],
      if (!['thobe', 'jersey', 'space', 'bisht'].contains(outfit)) ...[_label('لون اللبس'), _sw('shirt', 'SHIRT')],
      if (!['thobe', 'dress', 'sport', 'jersey', 'pj', 'space', 'bisht', 'party'].contains(outfit)) ...[_label('لون البنطلون'), _sw('pants', 'PANTS')],
    ];
  }

  List<Widget> _shoes() => [
        _label('نوع الحذاء'),
        _seg(ArtOpts.list2('SHOES'), (a['shoe'] ?? 'sneaker').toString(), (v) => a['shoe'] = v),
        _label('لون الحذاء'),
        _sw('shoeC', 'SHOEC'),
      ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final full = widget.mode == EditMode.full;
    final title = widget.mode == EditMode.parent
        ? 'شخصية ${e['name']} ✨'
        : widget.mode == EditMode.self
            ? 'غيّر شكلك يا ${e['name']} ✨'
            : widget.kid != null
                ? 'تعديل ${widget.kid!['name']}'
                : 'طفل جديد';
    final tabs = [if (full) '🧒 الأساسيات', '😊 الشكل والشعر', '👕 اللبس', '👟 الأحذية'];
    if (_tab >= tabs.length) _tab = 0;
    final sec = full ? _tab : _tab + 1;
    return Scaffold(
      backgroundColor: C.skyPale,
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(14, top + 8, 14, 10),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.sky, C.skyLight], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Column(children: [
            Row(children: [
              IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF26305A)))),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                style: FilledButton.styleFrom(backgroundColor: C.orange, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              ),
            ]),
            SizedBox(height: 170, child: KidAvatar(kid: _preview)),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 0), child: Pills(items: tabs, index: _tab, onTap: (i) => setState(() => _tab = i))),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
            if (sec == 0) ..._basics(),
            if (sec == 1) ..._face(),
            if (sec == 2) ..._wear(),
            if (sec == 3) ..._shoes(),
          ]),
        ),
      ]),
    );
  }
}

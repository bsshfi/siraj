import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../avatars.dart';
import '../data.dart';
import '../family.dart';
import '../theme.dart';
import '../widgets/scene.dart';
import 'reader.dart';
import 'link.dart';
import 'setup.dart';

/// شاشة "الليلة": الترحيب + قصة الليلة + قصص ثانية
class TonightScreen extends StatefulWidget {
  const TonightScreen({super.key});
  @override
  State<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends State<TonightScreen> {
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'مساء النور';
    return 'مساء الخير، جاهزين للحكاية؟ 🌙';
  }

  void _open(Story s) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, a, __) => ReaderScreen(story: s, heroes: currentHeroes()),
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: c, child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(c), child: child));
      },
    )).then((_) => _refresh());
  }

  @override
  void initState() {
    super.initState();
    Family.I.addListener(_refresh);
  }

  @override
  void dispose() {
    Family.I.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _push(Widget w) async {
    Navigator.pop(context);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    _refresh();
  }

  void _settings() {
    final f = Family.I;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(f.linked ? 'العائلة مربوطة ✅' : 'الإعدادات', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (f.linked) ...[
              if (f.kids.length > 1)
                ListTile(leading: const Icon(Icons.groups_rounded, color: C.orange), title: const Text('مين يستخدم هالجهاز؟', style: TextStyle(fontWeight: FontWeight.w700)), onTap: () => _push(const WhoScreen())),
              ListTile(
                leading: const Icon(Icons.sync_rounded, color: C.sky),
                title: const Text('تحديث من العائلة', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  f.syncNow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                title: const Text('فك ربط هالجهاز', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await f.unlink();
                },
              ),
            ] else ...[
              ListTile(leading: const Icon(Icons.key_rounded, color: C.orange), title: const Text('ربط برمز العائلة', style: TextStyle(fontWeight: FontWeight.w700)), onTap: () => _push(const JoinScreen())),
              ListTile(leading: const Icon(Icons.edit_rounded, color: C.sky), title: const Text('تعديل البطل', style: TextStyle(fontWeight: FontWeight.w700)), onTap: () => _push(const SetupScreen(editing: true))),
            ],
          ]),
        ),
      ),
    );
  }

  /// اختيار أبطال الليلة (لو فيه أكثر من طفل على الجهاز)
  Widget _picker() {
    final f = Family.I;
    final mine = f.myKids;
    final sel = f.heroes.map((k) => k.id).toList();
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final k in mine)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                final s = [...sel];
                if (s.contains(k.id)) {
                  if (s.length > 1) s.remove(k.id);
                } else {
                  s.add(k.id);
                }
                f.setHeroes(s);
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel.contains(k.id) ? C.orange : Colors.white54,
                    ),
                    child: Stack(children: [
                      KidFace(kid: k, size: 60),
                      if (sel.isNotEmpty && sel.first == k.id)
                        const Positioned(right: 0, top: 0, child: Text('⭐', style: TextStyle(fontSize: 16))),
                    ]),
                  ),
                  const SizedBox(height: 3),
                  Text(k.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: sel.contains(k.id) ? C.ink : const Color(0xFF34406E))),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroes = currentHeroes();
    final hero = heroes.first;
    final friends = heroes.sublist(1);
    String fill(String x) => fillTemplate(x, hero, friends: friends, dad: Family.I.dad, mom: Family.I.mom);
    final showPicker = Family.I.linked && Family.I.myKids.length > 1;
    final tonight = Library.tonight();
    final more = Library.stories.where((s) => s.id != tonight.id && s.category.isEmpty).take(14).toList();
    final top = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .3, .62]),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 14, 20, 6),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/brand/icon.png', width: 52, height: 52)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('سراج', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF26305A), height: 1.05)),
                    Text(_greeting, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF34406E))),
                  ]),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .85)),
                  onPressed: _settings,
                  icon: const Icon(Icons.tune_rounded, color: C.ink),
                ),
              ]),
            ),
          ),
          if (showPicker)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 0, 22, 6),
                    child: Text('مين أبطال الليلة؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
                  ),
                  _picker(),
                ]),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            sliver: SliverToBoxAdapter(
              child: SoftCard(
                padding: const EdgeInsets.all(10),
                onTap: () => _open(tonight),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Hero(tag: 'art-${tonight.id}', child: SceneArt(scene: tonight.scene, heroes: heroes, prop: tonight.pages.first.prop, radius: 20)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEDE6FF), borderRadius: BorderRadius.circular(12)),
                        child: const Text('قصة الليلة', style: TextStyle(color: C.purple, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                      const SizedBox(height: 6),
                      Text(fill(tonight.title), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3)),
                      if (tonight.value.isNotEmpty)
                        Text('قيمة الليلة: ${tonight.value}', style: const TextStyle(fontSize: 15, color: C.soft, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      BigButton(label: 'ابدأ الحكاية', icon: Icons.auto_stories_rounded, onTap: () => _open(tonight)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(22, 22, 22, 10),
            sliver: SliverToBoxAdapter(child: Text('قصص ثانية 📚', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .86),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final s = more[i];
                  final read = Profile.done.contains(s.id);
                  return SoftCard(
                    padding: const EdgeInsets.all(8),
                    onTap: () => _open(s),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Hero(tag: 'art-${s.id}', child: SceneArt(scene: s.scene, prop: s.pages.first.prop, radius: 16)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(fill(s.title),
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.3)),
                      ),
                      if (read) const Text('✓ قرأناها', style: TextStyle(fontSize: 12.5, color: Color(0xFF2FA36B), fontWeight: FontWeight.w700)),
                    ]),
                  );
                },
                childCount: more.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 120 + MediaQuery.of(context).padding.bottom)),
        ],
      ),
    );
  }
}

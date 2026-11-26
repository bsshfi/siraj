import 'package:flutter/material.dart';

import '../data.dart';
import '../family.dart';
import '../learn.dart';
import '../theme.dart';
import '../tonight_logic.dart';
import '../widgets/scene.dart';
import 'reader.dart';

/// بطاقة قصة (رسمة + عنوان + تصنيف)
class StoryTile extends StatelessWidget {
  final Story s;
  final List<Kid> heroes;
  final bool drawKids;
  const StoryTile({super.key, required this.s, required this.heroes, this.drawKids = true});

  @override
  Widget build(BuildContext context) {
    final c = Tonight.catOf(s);
    final read = Family.I.allLogs.any((e) => e['s'] == s.id) || Profile.done.contains(s.id);
    final fav = Family.I.fav.contains(s.id);
    final hero = heroes.isNotEmpty ? heroes.first : const Kid('البطل', 'm');
    return SoftCard(
      padding: const EdgeInsets.all(8),
      onTap: () => openStory(context, s, heroes: heroes.isEmpty ? null : heroes),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Hero(
          tag: 'art-${s.id}',
          child: SceneArt(scene: s.scene, prop: fav ? '⭐' : s.occ != null ? '🎉' : s.isPro ? '📖' : '', heroes: drawKids ? Tonight.artHeroes(s, heroes) : const [], radius: 16),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Text(fillTemplate(s.title, hero, friends: heroes.length > 1 ? heroes.sublist(1) : const [], dad: Family.I.dad, mom: Family.I.mom),
              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3)),
        ),
        Row(children: [
          Expanded(child: Text('${c.$2} ${c.$3}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: C.soft, fontWeight: FontWeight.w700))),
          if (read) const Text('✓', style: TextStyle(fontSize: 13, color: Color(0xFF2FA36B), fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }
}

/// مكتبتي: المفضلة + اللي قريناها (داخل تبويب اكتشف)
class MyLibrary extends StatelessWidget {
  const MyLibrary({super.key});
  @override
  Widget build(BuildContext context) {
    final hs = currentHeroes();
    final seen = <String>{}, ids = <String>[];
    for (final id in Family.I.fav) {
      if (seen.add(id)) ids.add(id);
    }
    for (final e in Family.I.allLogs) {
      if (seen.add(e['s'].toString())) ids.add(e['s'].toString());
    }
    final list = ids.map(Tonight.byId).whereType<Story>().toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BigButton(
        label: 'كل القصص (${Learn.ar(Library.stories.length)})',
        icon: Icons.auto_stories_rounded,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen(all: true))),
      ),
      const SizedBox(height: 14),
      if (list.isEmpty)
        const SoftCard(
          padding: EdgeInsets.all(24),
          child: Text('القصص اللي تقرونها تنحفظ هنا، وتقدرون ترجعون لها متى ما حبيتوا 📚', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: C.soft, fontWeight: FontWeight.w700, height: 1.6)),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .8),
          itemBuilder: (_, i) => StoryTile(s: list[i], heroes: hs),
        ),
    ]);
  }
}

/// كل القصص: بحث + تصنيفات + عرض المزيد
class LibraryScreen extends StatefulWidget {
  final bool all;
  const LibraryScreen({super.key, this.all = true});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _q = '', _cat = '';
  int _shown = 12;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final hs = currentHeroes();
    final all = Library.stories.where((s) {
      if (s.hidden) return false;
      final c = Tonight.catOf(s);
      if (_cat.isNotEmpty && c.$1 != _cat) return false;
      return _q.isEmpty || s.title.contains(_q) || s.value.contains(_q) || c.$3.contains(_q);
    }).toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.sky, C.skyLight, C.skyPale], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .2, .45])),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, top + 8, 14, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white70)),
                  const SizedBox(width: 10),
                  Text('مكتبة القصص 📚 ${Learn.ar(Library.stories.length)}', style: const TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800, color: Color(0xFF26305A))),
                ]),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() {
                    _q = v.trim();
                    _shown = 12;
                  }),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم القصة أو القيمة',
                    hintStyle: const TextStyle(color: Color(0xFFB3BBCB)),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final c in <(String, String, String, RegExp?)>[('', '', 'الكل', null), ...Tonight.cats])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text('${c.$2} ${c.$3}'.trim(), style: TextStyle(fontWeight: FontWeight.w800, color: _cat == c.$1 ? Colors.white : C.ink)),
                          selected: _cat == c.$1,
                          selectedColor: C.orange,
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          side: BorderSide.none,
                          onSelected: (_) => setState(() {
                            _cat = c.$1;
                            _shown = 12;
                          }),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: all.isEmpty
                ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30), child: Text('ما لقينا قصة بهذا الاسم', textAlign: TextAlign.center, style: TextStyle(color: C.soft, fontSize: 16))))
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .8),
                    delegate: SliverChildBuilderDelegate((_, i) => StoryTile(s: all[i], heroes: hs, drawKids: false), childCount: all.length < _shown ? all.length : _shown),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, MediaQuery.of(context).padding.bottom + 30),
              child: all.length > _shown
                  ? OutlinedButton(
                      onPressed: () => setState(() => _shown += 12),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: Text('عرض المزيد (${Learn.ar(all.length - _shown)})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    )
                  : const SizedBox(),
            ),
          ),
        ]),
      ),
    );
  }
}

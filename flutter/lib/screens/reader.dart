import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets/scene.dart';

/// قارئ القصة: تقليب بالسحب، قراءة بالصوت، وصفحات "اختر الطريق"
class ReaderScreen extends StatefulWidget {
  final Story story;
  const ReaderScreen({super.key, required this.story});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _pc = PageController();
  int _i = 0;
  bool _auto = false; // القراءة بالصوت شغالة (تقلب الصفحات لحالها)
  bool _finished = false;
  late final Kid _hero = Profile.hero ?? const Kid('بطلنا', 'm');

  Story get s => widget.story;
  String _text(int i) => fillTemplate(s.pages[i].text, _hero);

  /// الصفحة الجاية: الخيارات تحدد الطريق، وصفحة النهاية توقف
  int? _next(int i) {
    final p = s.pages[i];
    if (p.isEnd || p.choices.isNotEmpty) return null;
    return i + 1 < s.pages.length ? i + 1 : null;
  }

  Future<void> _go(int i) async {
    if (i < 0 || i >= s.pages.length) return;
    HapticFeedback.selectionClick();
    await _pc.animateToPage(i, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  Future<void> _readFrom(int i) async {
    setState(() => _auto = true);
    var cur = i;
    while (mounted && _auto) {
      await Voice.speak(_text(cur), Profile.rate);
      if (!mounted || !_auto) break;
      final n = _next(cur);
      if (n == null) {
        setState(() => _auto = false);
        if (s.pages[cur].choices.isEmpty) _finish();
        break;
      }
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted || !_auto) break;
      await _go(n);
      cur = n;
    }
  }

  Future<void> _toggleVoice() async {
    HapticFeedback.lightImpact();
    if (_auto) {
      setState(() => _auto = false);
      await Voice.stop();
    } else {
      _readFrom(_i);
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    Profile.markDone(s.id);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌙✨', style: TextStyle(fontSize: 46)),
          Text('تصبح${_hero.isGirl ? 'ين' : ''} على خير يا ${_hero.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          if (s.question.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(18)),
              child: Text('💬 ${fillTemplate(s.question, _hero)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, height: 1.6, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 16),
          BigButton(label: 'تمام', onTap: () {
            Navigator.pop(context);
            Navigator.pop(context);
          }),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _auto = false;
    Voice.stop();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: C.night1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [C.night1, Color(0xFF2C2F5C), C.night2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(children: [
          // الشريط العلوي: رجوع + العنوان + التقدّم
          Padding(
            padding: EdgeInsets.fromLTRB(12, top + 8, 12, 6),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(fillTemplate(s.title, _hero),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              Text('${_i + 1}/${s.pages.length}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (_i + 1) / s.pages.length),
                duration: const Duration(milliseconds: 380),
                builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: Colors.white12, color: C.orange2),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: s.pages.length,
              physics: _auto ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => _PageView(
                page: s.pages[i],
                text: _text(i),
                hero: _hero,
                heroTag: i == 0 ? 'art-${s.id}' : null,
                onChoice: (target) {
                  setState(() => _auto = false);
                  Voice.stop();
                  _go(target);
                },
                onFinish: s.pages[i].isEnd || (i == s.pages.length - 1 && s.pages[i].choices.isEmpty) ? _finish : null,
              ),
            ),
          ),
          // أزرار التحكم
          Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, bottom + 16),
            child: Row(children: [
              _RoundBtn(icon: Icons.chevron_left_rounded, onTap: _i > 0 ? () => _go(_i - 1) : null),
              const SizedBox(width: 14),
              Expanded(
                child: BigButton(
                  label: _auto ? 'إيقاف الصوت' : 'اقرأ لي',
                  icon: _auto ? Icons.pause_rounded : Icons.record_voice_over_rounded,
                  onTap: _toggleVoice,
                ),
              ),
              const SizedBox(width: 14),
              _RoundBtn(icon: Icons.chevron_right_rounded, onTap: _next(_i) != null ? () => _go(_next(_i)!) : null),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final StoryPage page;
  final String text;
  final Kid hero;
  final String? heroTag;
  final void Function(int) onChoice;
  final VoidCallback? onFinish;
  const _PageView({required this.page, required this.text, required this.hero, required this.onChoice, this.heroTag, this.onFinish});

  @override
  Widget build(BuildContext context) {
    final art = SceneArt(scene: page.scene, prop: page.prop, hero: hero, radius: 26);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      physics: const BouncingScrollPhysics(),
      children: [
        heroTag != null ? Hero(tag: heroTag!, child: art) : art,
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
          child: Text(text, style: const TextStyle(fontSize: 21, height: 1.85, fontWeight: FontWeight.w600, color: C.ink)),
        ),
        if (page.choices.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('وش تختار؟ 🤔', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final c in page.choices)
            Padding(padding: const EdgeInsets.only(top: 10), child: BigButton(label: c.$1, onTap: () => onChoice(c.$2))),
        ],
        if (onFinish != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onFinish,
            icon: const Icon(Icons.bedtime_rounded),
            label: const Text('انتهت الحكاية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onTap == null ? .35 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.white12,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, color: Colors.white, size: 30)),
        ),
      ),
    );
  }
}

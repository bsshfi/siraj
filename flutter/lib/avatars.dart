import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'data.dart';

/// رسم شخصيات الأطفال بنفس محرّك الويب (art.js) بالضبط.
/// محرّك JavaScript مخفي (بكسل واحد) يحسب نص الرسمة فقط، والرسم نفسه أصلي بـ flutter_svg.
/// أي تعديل على الشخصيات في الموقع يوصل للتطبيق مع التحديث الجاي تلقائيًا.
class Avatars {
  static WebViewController? _c;
  static final _ready = Completer<void>();
  static final Map<String, String> _cache = {};
  static final Map<String, Future<String?>> _pending = {};

  /// تُستدعى مرة وحدة من جذر التطبيق
  static Widget host() {
    if (_c == null) {
      final c = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
      c.setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
        if (!_ready.isCompleted) _ready.complete();
      }));
      _c = c;
      rootBundle.loadString('assets/js/art.js').then((js) {
        c.loadHtmlString('<!doctype html><html><head><meta charset="utf-8"></head><body><script>$js</script></body></html>');
      });
    }
    return IgnorePointer(child: SizedBox(width: 1, height: 1, child: Opacity(opacity: 0.01, child: WebViewWidget(controller: _c!))));
  }

  static String _key(Kid k, int size) => '${k.gender}|$size|${jsonEncode(k.av ?? {})}';

  /// نص SVG لشخصية الطفل (أو null لو ما اشتغل المحرّك — نرجع للشخصية الافتراضية)
  static Future<String?> svg(Kid k, {int size = 120}) {
    final key = _key(k, size);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    return _pending[key] ??= _compute(k, size, key);
  }

  static Future<String?> _compute(Kid k, int size, String key) async {
    try {
      await _ready.future.timeout(const Duration(seconds: 8));
      final av = jsonEncode(jsonEncode(k.av ?? {}));
      final r = await _c!.runJavaScriptReturningResult('ART.avatarSVG(JSON.parse($av), ${jsonEncode(k.gender)}, $size)');
      var s = r is String ? r : r.toString();
      if (s.startsWith('"')) s = jsonDecode(s) as String;
      s = s.replaceFirst('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ');
      _cache[key] = s;
      return s;
    } catch (_) {
      return null;
    } finally {
      _pending.remove(key);
    }
  }
}

/// ويدجت الشخصية: تظهر الافتراضية فورًا، وتتبدّل بالحقيقية أول ما تجهز
class KidAvatar extends StatelessWidget {
  final Kid kid;
  final BoxFit fit;
  const KidAvatar({super.key, required this.kid, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    final fallback = SvgPicture.asset(kid.isGirl ? 'assets/avatars/girl.svg' : 'assets/avatars/boy.svg', fit: fit);
    if (kid.av == null) return fallback;
    return FutureBuilder<String?>(
      future: Avatars.svg(kid),
      builder: (_, snap) {
        final s = snap.data;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: s == null ? KeyedSubtree(key: const ValueKey('d'), child: fallback) : SvgPicture.string(s, key: ValueKey(s.hashCode), fit: fit),
        );
      },
    );
  }
}

/// وجه الطفل في دائرة (لاختيار البطل)
class KidFace extends StatelessWidget {
  final Kid kid;
  final double size;
  const KidFace({super.key, required this.kid, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFFEFF5FF),
          child: OverflowBox(
            maxHeight: size * 1.9,
            alignment: Alignment.topCenter,
            child: Padding(padding: EdgeInsets.only(top: size * .06), child: SizedBox(width: size * 1.25, height: size * 1.9, child: KidAvatar(kid: kid))),
          ),
        ),
      ),
    );
  }
}

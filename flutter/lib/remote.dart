import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

/// التحكم عن بُعد من ملف app-config.json على الموقع (بدون أي معرّف للجهاز):
/// android.minBuild → تحديث إجباري، android.latestBuild → تنبيه تحديث، flags → مفاتيح الميزات
class Remote {
  static const url = 'https://siraj.wamdarc.com/app-config.json';
  static const store = 'https://play.google.com/store/apps/details?id=com.wamdarc.siraj';
  /// نسخة المتجر: Google Play يتكفّل بالتحديثات، وإعداداتها في قسم play بملف التحكم
  static const isPlay = String.fromEnvironment('STORE') == 'play';
  static Map<String, dynamic> flags = {'ads': false, 'accounts': false, 'analytics': false};
  static bool _shown = false;

  static Future<void> check(BuildContext context, {bool manual = false}) async {
    void say(String m) {
      if (manual && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: const TextStyle(fontFamily: 'Baloo', fontSize: 16))));
    }

    say('جاري التحقق من التحديثات… 🔄');
    try {
      final r = await http.get(Uri.parse('$url?t=${DateTime.now().millisecondsSinceEpoch}')).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return say('ما قدرت أتحقق، جرّب بعد شوي');
      final cfg = Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)) as Map);
      if (cfg['flags'] is Map) flags = {...flags, ...Map<String, dynamic>.from(cfg['flags'] as Map)};
      final a = Map<String, dynamic>.from((cfg[isPlay ? 'play' : 'android'] as Map?) ?? {});
      if (isPlay) a['storeUrl'] = store;
      final build = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      final minB = (a['minBuild'] as num?)?.toInt() ?? 0, latest = (a['latestBuild'] as num?)?.toInt() ?? 0;
      if ((_shown && !manual) || !context.mounted) return;
      if (minB > build) {
        _shown = true;
        _show(context, a, force: true);
      } else if (latest > build) {
        _shown = true;
        _show(context, a, force: false);
      } else {
        say('عندك آخر نسخة ✓');
      }
    } catch (_) {
      say('ما قدرت أتحقق، تأكد من الإنترنت');
    }
  }

  static void _show(BuildContext context, Map<String, dynamic> a, {required bool force}) {
    final link = (a['storeUrl'] ?? store).toString();
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop: !force,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text((a['title'] ?? (force ? 'تحديث مطلوب' : 'تحديث جديد')).toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Text((a['message'] ?? 'فيه نسخة أحدث من سراج | Siraj ✨').toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                BigButton(label: 'حدّث الآن', onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication)),
                if (!force) TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقًا', style: TextStyle(fontSize: 16, color: C.soft))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

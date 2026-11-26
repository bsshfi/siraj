import 'package:flutter_tts/flutter_tts.dart';

/// القراءة بالصوت من محرك الكلام في الجوال (عربي)
class Voice {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;
  static bool speaking = false;

  static Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      final langs = (await _tts.getLanguages) as List? ?? [];
      final ar = langs.map((e) => e.toString()).firstWhere(
            (l) => l.toLowerCase().startsWith('ar'),
            orElse: () => 'ar',
          );
      _arLang = langs.contains('ar-SA') ? 'ar-SA' : ar;
      await _tts.setLanguage(_arLang);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  /// يقرأ النص ويرجع لما يخلص (أو يتوقف)
  static String _arLang = 'ar';
  static bool _isEn = false;

  static String _voice = '';
  static double _pitch = 1.0;

  /// أصوات عربية على الجهاز: [{name, locale}]
  static Future<List<Map<String, String>>> arabicVoices() async {
    await _init();
    try {
      final v = (await _tts.getVoices) as List? ?? [];
      final out = <Map<String, String>>[], seen = <String>{};
      for (final x in v) {
        final m = Map<String, dynamic>.from(x as Map);
        final loc = (m['locale'] ?? '').toString(), name = (m['name'] ?? '').toString();
        if (loc.toLowerCase().startsWith('ar') && seen.add(name)) out.add({'name': name, 'locale': loc});
      }
      out.sort((a, b) => (b['locale']!.contains('SA') ? 1 : 0) - (a['locale']!.contains('SA') ? 1 : 0));
      return out;
    } catch (_) {
      return [];
    }
  }

  /// صوت الطفل المختار (الاسم + طبقة الصوت)
  static Future<void> useVoice(String name, String locale, double pitch) async {
    await _init();
    try {
      if (name.isNotEmpty && name != _voice) {
        await _tts.setVoice({'name': name, 'locale': locale});
        _voice = name;
        _isEn = false;
      }
      if (pitch != _pitch) {
        await _tts.setPitch(pitch);
        _pitch = pitch;
      }
    } catch (_) {}
  }

  static Future<void> resetVoice() async {
    if (_voice.isEmpty && _pitch == 1.0) return;
    _voice = '';
    _pitch = 1.0;
    try {
      await _tts.setLanguage(_arLang);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  static Future<void> speak(String text, double rate, {bool en = false}) async {
    await _init();
    speaking = true;
    try {
      if (en != _isEn) {
        await _tts.setLanguage(en ? 'en-US' : _arLang);
        _isEn = en;
        if (en) _voice = '';
      }
      await _tts.setSpeechRate(rate);
      await _tts.speak(text.replaceAll(RegExp(r'[«»]'), ''));
    } catch (_) {}
    speaking = false;
  }

  static Future<void> stop() async {
    speaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

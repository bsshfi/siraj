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
      await _tts.setLanguage(langs.contains('ar-SA') ? 'ar-SA' : ar);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  /// يقرأ النص ويرجع لما يخلص (أو يتوقف)
  static Future<void> speak(String text, double rate) async {
    await _init();
    speaking = true;
    try {
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

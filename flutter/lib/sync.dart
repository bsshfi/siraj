import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// نفس بروتوكول sync.js في الويب حرفيًا:
/// - السيرفر يعرف العائلة ببصمة الرمز فقط (SHA-256)
/// - البيانات تنشفّر بالرمز (PBKDF2 → AES-GCM) قبل ما تطلع من الجهاز
class Sync {
  static const api = 'https://siraj-api.bsshfi.workers.dev';
  static const _alph = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// يقبل الرمز بأي شكل (مسافات، أرقام عربية، داخل رسالة أو رابط) ويرجع XXXXX-XXXXX أو ''
  static String norm(String input) {
    var c = input;
    const ar = '٠١٢٣٤٥٦٧٨٩', fa = '۰۱۲۳۴۵۶۷۸۹';
    for (var i = 0; i < 10; i++) {
      c = c.replaceAll(ar[i], '$i').replaceAll(fa[i], '$i');
    }
    c = c.toUpperCase();
    final m = RegExp(r'JOIN=([A-Z0-9]{5}-?[A-Z0-9]{5})').firstMatch(c) ?? RegExp(r'(?:^|[^A-Z0-9])([A-Z0-9]{5}-[A-Z0-9]{5})(?![A-Z0-9])').firstMatch(c);
    c = (m != null ? m.group(1)! : c).replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (c.length != 10 || c.split('').any((x) => !_alph.contains(x))) return '';
    return '${c.substring(0, 5)}-${c.substring(5)}';
  }

  static Future<String> famId(String code) async {
    final h = await Sha256().hash(utf8.encode('siraj-id:$code'));
    return h.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().substring(0, 32);
  }

  static final Map<String, SecretKey> _keys = {};

  /// اشتقاق المفتاح (١٠٠ ألف دورة) في خيط منفصل عشان الواجهة ما تعلّق
  static Future<SecretKey> _key(String code) async {
    final k = _keys[code];
    if (k != null) return k;
    final bytes = await compute(_derive, code);
    return _keys[code] = SecretKey(bytes);
  }

  static Future<List<int>> _derive(String code) async {
    final pb = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 100000, bits: 256);
    final k = await pb.deriveKeyFromPassword(password: code, nonce: utf8.encode('siraj-salt-v1'));
    return k.extractBytes();
  }

  static Future<String> seal(String code, Object obj) async {
    final aes = AesGcm.with256bits();
    final iv = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final box = await aes.encrypt(utf8.encode(jsonEncode(obj)), secretKey: await _key(code), nonce: iv);
    return base64Encode(Uint8List.fromList([...iv, ...box.cipherText, ...box.mac.bytes]));
  }

  static Future<dynamic> open(String code, String blob) async {
    final raw = base64Decode(blob);
    final iv = raw.sublist(0, 12), body = raw.sublist(12);
    final ct = body.sublist(0, body.length - 16), mac = body.sublist(body.length - 16);
    final pt = await AesGcm.with256bits().decrypt(SecretBox(ct, nonce: iv, mac: Mac(mac)), secretKey: await _key(code));
    return jsonDecode(utf8.decode(pt));
  }

  static Future<(int, Map<String, dynamic>)> _api(String path, [Object? body]) async {
    final uri = Uri.parse('$api$path');
    final r = body == null
        ? await http.get(uri).timeout(const Duration(seconds: 15))
        : await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    Map<String, dynamic> j = {};
    try {
      j = Map<String, dynamic>.from(jsonDecode(r.body) as Map);
    } catch (_) {}
    if (r.statusCode >= 400 && r.statusCode != 404) throw Exception(j['error'] ?? r.statusCode);
    return (r.statusCode, j);
  }

  /// يرجع (العائلة، رقم النسخة) أو null لو ما فيه عائلة بهالرمز
  static Future<(Map<String, dynamic>, int)?> pullFamily(String code) async {
    final (st, j) = await _api('/family/${await famId(code)}');
    if (st == 404 || j['blob'] == null) return null;
    final fam = Map<String, dynamic>.from(await open(code, j['blob'] as String) as Map);
    return (fam, (j['rev'] as num?)?.toInt() ?? 0);
  }

  static Future<void> pushProgress(String code, String dev, Map<String, dynamic> data) async {
    await _api('/progress', {'fam': await famId(code), 'dev': dev, 'blob': await seal(code, data)});
  }

  static Future<void> event(String code, String dev, List<String> kids, String story) async {
    await _api('/event', {'fam': await famId(code), 'dev': dev, 'kids': kids, 'story': story});
  }
}

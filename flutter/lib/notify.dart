import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'family.dart';

/// إشعارات سراج: تذكير وقت القصة كل يوم (محلي على الجهاز — بدون أي سيرفر)
class Notify {
  static final _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _id = 2030;
  static const _ch = AndroidNotificationDetails(
    'bedtime',
    'وقت القصة',
    channelDescription: 'تذكير يومي بوقت قصة ما قبل النوم',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF8B5CF6),
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      _ready = true;
    } catch (_) {}
  }

  /// يطلب إذن الإشعارات (أندرويد ١٣+) — يرجع true لو مسموح
  static Future<bool> ask() async {
    await init();
    try {
      final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ok = await a?.requestNotificationsPermission();
      return ok ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enabled() async {
    await init();
    try {
      final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await a?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// يجدول تذكير وقت القصة حسب إعدادات العائلة (جهاز الطفل، أو جهاز بدون عائلة)
  static Future<void> schedule() async {
    await init();
    if (!_ready) return;
    final f = Family.I;
    try {
      await _p.cancel(_id);
      final want = f.fam['remind'] != false && (f.isChild || (!f.linked && f.kids.isEmpty) || f.fam['remindParent'] == true);
      if (!want) return;
      final m = Family.mins(f.bedtime);
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      final names = f.myKids.map((k) => k.name).join(' و');
      await _p.zonedSchedule(
        _id,
        'حان وقت قصة الليلة 🌙',
        names.isEmpty ? 'قصة جديدة بانتظارك في سراج ✨' : 'يا $names، قصة الليلة جاهزة… يلا نقرأ ✨',
        tz.TZDateTime.from(at, tz.UTC),
        const NotificationDetails(android: _ch),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// إشعار تجربة فوري
  static Future<void> test() async {
    await init();
    try {
      await _p.show(_id + 1, 'سراج 🌙', 'كذا بيوصلك تذكير وقت القصة ✨', const NotificationDetails(android: _ch));
    } catch (_) {}
  }
}

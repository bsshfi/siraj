import 'package:flutter/foundation.dart';

/// التنقل بين التبويبات من أي مكان (مثل App.tab في الويب)
class Nav {
  /// 0 الليلة، 1 أنا، 2 اكتشف، 3 العب وتعلّم، 4 للوالدين
  static final tab = ValueNotifier<int>(0);
  /// داخل اكتشف: 0 رحلات، 1 الفضاء، 2 مكتبة القصص
  static final explore = ValueNotifier<int>(0);
  /// داخل العب وتعلّم: 0 ألعاب، 1 حروف…
  static final learn = ValueNotifier<int>(0);

  static void go(int t, {int? explore, int? learn}) {
    if (explore != null) Nav.explore.value = explore;
    if (learn != null) Nav.learn.value = learn;
    tab.value = t;
  }
}

#!/bin/bash
# يثبّت نسخة العرض على المحاكي ويصوّر الصفحات الرئيسية (1080 عرض بكثافة 440 = 393dp مثل جوال باسل)
set -x
mkdir -p shots
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 3; done
sleep 45
adb shell settings put secure immersive_mode_confirmations confirmed
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS
adb shell input keyevent KEYCODE_HOME; sleep 5
adb shell wm density 440
adb shell settings put system font_scale 1.0
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell pm grant com.wamdarc.siraj android.permission.POST_NOTIFICATIONS || true
adb shell am start -n com.wamdarc.siraj/.MainActivity
sleep 30
shot() { adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null; sleep 1; adb exec-out screencap -p > "shots/$1.png"; }
shot 01-home
adb shell input swipe 540 1700 540 900 500; sleep 3; shot 02-home-mid
adb shell input swipe 540 1700 540 700 500; sleep 3; shot 03-home-end
# الشريط السفلي: مركزه على ارتفاع 2400 - (14+34)*2.75
Y=2268
for t in "741 04-me" "541 05-explore" "341 06-learn" "141 07-parents"; do
  set -- $t; adb shell input tap $1 $Y; sleep 6; shot $2
done
adb shell input tap 941 $Y; sleep 3
adb logcat -d -s flutter > shots/flutter-log.txt || true

"""يضبط مشروع الأندرويد اللي يولّده `flutter create` (يشتغل في GitHub Actions بعد الإنشاء).
- اسم التطبيق: سراج | Siraj
- مفتاح التوقيع التجريبي الثابت (نفس مفتاح النسخ السابقة) عشان يتثبّت فوقها
- صلاحية محرك الكلام (TTS) للأندرويد 11+
آمن لو انعاد تشغيله أكثر من مرة."""
import os, re, shutil
A = os.path.join(os.path.dirname(__file__), '..', 'android')
man = os.path.join(A, 'app', 'src', 'main', 'AndroidManifest.xml')
s = open(man, encoding='utf-8').read()
s = re.sub(r'android:label="[^"]*"', 'android:label="سراج | Siraj"', s, count=1)
if 'TTS_SERVICE' not in s:
    q = '<intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>'
    s = s.replace('<queries>', '<queries>\n        ' + q, 1) if '<queries>' in s else s.replace('</manifest>', '    <queries>' + q + '</queries>\n</manifest>')
open(man, 'w', encoding='utf-8').write(s)

shutil.copy(os.path.join(os.path.dirname(__file__), 'siraj-test.keystore'), os.path.join(A, 'app', 'siraj-test.keystore'))
g = os.path.join(A, 'app', 'build.gradle.kts')
t = open(g, encoding='utf-8').read()
if 'siraj-test.keystore' not in t:
    block = '''    signingConfigs {
        create("siraj") {
            storeFile = file("siraj-test.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {'''
    t = t.replace('    buildTypes {', block, 1)
    t = t.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("siraj")')
open(g, 'w', encoding='utf-8').write(t)
print('✓ android patched')

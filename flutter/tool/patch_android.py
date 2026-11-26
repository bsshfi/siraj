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
if 'RecognitionService' not in s:
    q2 = '<intent><action android:name="android.speech.RecognitionService"/></intent>'
    s = s.replace('<queries>', '<queries>\n        ' + q2, 1) if '<queries>' in s else s.replace('</manifest>', '    <queries>' + q2 + '</queries>\n</manifest>')
if 'TTS_SERVICE' not in s:
    q = '<intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>'
    s = s.replace('<queries>', '<queries>\n        ' + q, 1) if '<queries>' in s else s.replace('</manifest>', '    <queries>' + q + '</queries>\n</manifest>')
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
# الإشعارات المجدولة (تذكير وقت القصة): الصلاحيات + مستقبلات flutter_local_notifications (تبقى بعد إعادة التشغيل)
for perm in ['android.permission.POST_NOTIFICATIONS', 'android.permission.RECEIVE_BOOT_COMPLETED', 'android.permission.VIBRATE', 'android.permission.RECORD_AUDIO']:
    if perm not in s:
        s = s.replace('<application', f'<uses-permission android:name="{perm}"/>\n    <application', 1)
if 'ScheduledNotificationReceiver' not in s:
    rc = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
    s = s.replace('</application>', rc + '    </application>', 1)
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
    t = t.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = if (System.getenv("SIRAJ_PLAY") == "1") signingConfigs.getByName("upload") else signingConfigs.getByName("siraj")')
if 'create("upload")' not in t:
    t = t.replace('        create("siraj") {', '''        create("upload") {
            storeFile = file("upload.jks")
            storePassword = System.getenv("SIRAJ_KEYSTORE_PASSWORD") ?: ""
            keyAlias = System.getenv("SIRAJ_KEY_ALIAS") ?: ""
            keyPassword = System.getenv("SIRAJ_KEY_PASSWORD") ?: ""
        }
        create("siraj") {''', 1)
# مكتبة الإشعارات تحتاج core library desugaring
if 'isCoreLibraryDesugaringEnabled' not in t:
    t = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', t, count=1)
if 'desugar_jdk_libs' not in t:
    if re.search(r'^dependencies\s*\{', t, re.M):
        t = re.sub(r'^dependencies\s*\{', 'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")', t, count=1, flags=re.M)
    else:
        t += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n}\n'
open(g, 'w', encoding='utf-8').write(t)
print('✓ android patched')

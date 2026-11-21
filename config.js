/* سِراج | SIRAJ — الإعدادات العامة (يقراها التطبيق و sw.js)
   VERSION: غيّره مع كل تحديث (ومعه CACHE في sw.js و ?v= في سكربتات index.html)
   API: رابط السيرفر بعد ما تنشره على Cloudflare
   VAPID: المفتاح العام للإشعارات (VAPID_PUBLIC) */
var CONFIG = {
  VERSION: '5.1',
  SITE: 'https://siraj.wamdarc.com',
  API: 'https://siraj-api.bsshfi.workers.dev',
  VAPID: 'BGzjgjXykj5m98FjSPzDyMQMzv2YyvvmN8jbi-nC0FVy9f8XFGaMRtSXyMfOnzMj9oqbGMzUGIp9yJ51rEsnVGA'
};
/* يسجّل آخر خطأ برمجي (بدون أي بيانات شخصية) ويظهر صغير تحت الإصدار في إعدادات وليّ الأمر، عشان نعرف سبب أي مشكلة في الأجهزة */
if (typeof window !== 'undefined') window.addEventListener('error', (e) => {
  try { localStorage.setItem('siraj-err', JSON.stringify({ m: String(e.message || '').slice(0, 160), f: String(e.filename || '').split('/').pop().split('?')[0], l: e.lineno || 0, v: CONFIG.VERSION, t: Date.now() })); } catch (x) {}
});

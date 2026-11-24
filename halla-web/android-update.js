(() => {
  const ua = navigator.userAgent;
  const installed = ua.match(/\bHallaBuild\/(\d+)/);
  // The first Android shell used the stock WebView user agent.
  const oldWebView = /Android.*; wv\)/i.test(ua) && !/FBAN|FBAV|Instagram|MicroMessenger|; GSA\//i.test(ua);
  if (!installed && !/HallaFacebook\/1/.test(ua) && !oldWebView) return;
  const build = installed ? Number(installed[1]) : 0;
  const releases = new URL('releases/', document.currentScript.src);
  const cacheKey = 'halla.requiredAndroidBuild';
  let checking = false;
  let required = 0;
  let dialog;

  function requireUpdate(release) {
    const code = release?.versionCode;
    if (!Number.isSafeInteger(code) || code <= build || code <= required) return;
    required = code;
    const url = new URL('Halla-' + code + '.apk', releases).href;
    if (!dialog) {
      dialog = document.createElement('dialog');
      dialog.dir = 'rtl';
      dialog.setAttribute('aria-labelledby', 'halla-update-title');
      dialog.style.cssText = 'width:min(82vw,360px);border:0;border-radius:20px;padding:24px;color:#10393d;background:#f2fffc;font:16px/1.6 system-ui;box-shadow:0 12px 50px #1235';
      dialog.innerHTML = '<h2 id="halla-update-title">الرجاء تحديث هلاا</h2><p class="release"></p><a class="download" style="display:block;text-align:center;border-radius:12px;padding:10px;color:white;background:#12646b;text-decoration:none">تنزيل التحديث</a><p>بعد التنزيل، افتح الحزمة واضغط «تحديث» في شاشة أندرويد.</p><details><summary>تعذّر فتح التنزيل؟</summary><label>انسخ هذا الرابط وافتحه في متصفح الهاتف<input readonly dir="ltr" style="width:100%"></label></details>';
      dialog.addEventListener('cancel', event => event.preventDefault());
      dialog.querySelector('input').onclick = event => event.target.select();
      document.body.append(dialog);
      dialog.showModal();
    }
    dialog.querySelector('.release').textContent = 'الإصدار ' + release.versionName + ' مطلوب لمتابعة استخدام التطبيق.';
    dialog.querySelector('.download').href = url;
    dialog.querySelector('input').value = url;
  }

  try { requireUpdate(JSON.parse(localStorage.getItem(cacheKey))); } catch {}
  async function check() {
    if (checking || document.hidden) return;
    checking = true;
    try {
      const response = await fetch(new URL('current.json', releases), {cache:'no-store'});
      if (!response.ok) return;
      const release = await response.json();
      requireUpdate(release);
      if (required === release.versionCode) localStorage.setItem(cacheKey, JSON.stringify(release));
    } catch {} finally { checking = false; }
  }
  check();
  window.addEventListener('pageshow', check);
  document.addEventListener('visibilitychange', check);
  setInterval(check, 60000);
})();

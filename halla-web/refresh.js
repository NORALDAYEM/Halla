(() => {
  const bar = document.createElement('div');
  bar.className = 'hala-refresh';
  bar.hidden = true;
  bar.setAttribute('role', 'status');
  bar.innerHTML = '<span class="hala-petals" aria-hidden="true"><i>♪</i><i>🌹</i><i>♫</i><i>🌹</i><i>♪</i></span><span class="hala-caption"></span>';
  const caption = bar.lastElementChild;
  document.body.append(bar);
  const waits = new Map();
  let start, distance = 0, refreshing = false;

  function render() {
    const task = [...waits.values()].filter(t => t.ready).pop();
    const parent = task?.parent || document.body;
    if (bar.parentNode !== parent) parent.append(bar);
    bar.hidden = !task;
    const label = refreshing ? 'جارٍ تحديث الصفحة…' : task?.label ||
      (distance >= 80 ? 'أفلت للتحديث' : 'اسحب للأسفل للتحديث');
    if (caption.textContent !== label) caption.textContent = label;
  }
  function begin(label, parent = document.body, delay = 200) {
    const key = Symbol();
    const task = {label, parent, ready: delay === 0};
    waits.set(key, task);
    const timer = setTimeout(() => {task.ready = true; render();}, delay);
    render();
    return () => {clearTimeout(timer); waits.delete(key); render();};
  }
  window.hallaWait = begin;


  // Revalidate static files in the HTTP cache for the next natural navigation.
  // Do not apply styles, run scripts or replace the active document here.
  let pending = false;
  async function refreshFiles() {
    if (pending || document.hidden || !navigator.onLine) return;
    pending = true;
    const abort = new AbortController();
    const timer = setTimeout(() => abort.abort(), 12000);
    try {
      const options = { cache: 'no-cache', redirect: 'error', signal: abort.signal };
      const response = await fetch(location.href, options);
      if (!response.ok) return;
      const markup = await response.text();
      const end = markup.indexOf('</head>');
      if (end < 0) return;
      const template = document.createElement('template');
      template.innerHTML = markup.slice(0, end);
      const files = new Set();
      for (const tag of template.content.querySelectorAll('link[rel="stylesheet"][href],script[src]')) {
        const file = new URL(tag.getAttribute('href') || tag.getAttribute('src'), response.url);
        if (file.origin === location.origin) files.add(file.href);
      }
      await Promise.allSettled(Array.from(files, async file => {
        const asset = await fetch(file, options);
        if (asset.ok) await asset.arrayBuffer();
      }));
    } catch {
      // A subsequent check retries after network failures.
    } finally {
      clearTimeout(timer);
      pending = false;
    }
  }
  setInterval(refreshFiles, 15000);
  for (const event of ['online', 'pageshow']) window.addEventListener(event, refreshFiles);
  document.addEventListener('visibilitychange', refreshFiles);

  function cancelPull() { start = null; distance = 0; }
  document.addEventListener('touchstart', e => {
    if (e.touches.length !== 1 || window.scrollY > 0 || waits.size || refreshing ||
        document.querySelector('dialog[open]') || e.target.closest('input,textarea,select,[contenteditable=true]')) {
      cancelPull(); return;
    }
    const t = e.touches[0];
    start = {x:t.clientX, y:t.clientY};
  }, {passive:true});
  document.addEventListener('touchmove', e => {
    if (!start) return;
    const t = e.touches[0], dy = t.clientY - start.y;
    if (e.touches.length !== 1 || window.scrollY > 0 || dy < 0 ||
        Math.abs(t.clientX - start.x) > Math.max(12, dy)) { cancelPull(); return; }
    if (dy < 10 && !distance) return;
    if (e.cancelable) e.preventDefault();
    distance = dy;
  }, {passive:false});
  document.addEventListener('touchcancel', cancelPull, {passive:true});
  document.addEventListener('touchend', () => {
    const reload = start && distance >= 80 && !refreshing && !waits.size;
    
    cancelPull();
    if (reload) void refreshFiles();
  }, {passive:true});
  if (document.readyState !== 'complete') {
    const reloading = performance.getEntriesByType('navigation')[0]?.type === 'reload';
    const done = begin(reloading ? 'جارٍ تحديث الصفحة…' : 'جارٍ التحميل…', document.body, reloading ? 0 : 300);
    window.addEventListener('load', done, {once:true});
  }
  window.addEventListener('pageshow', () => {refreshing = false; cancelPull();});
})();

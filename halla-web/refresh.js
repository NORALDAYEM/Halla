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
    bar.hidden = !task && !distance && !refreshing;
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


  // Keep the live document and its form, dialog and navigation state.
  const styleSelector = 'style, link[rel="stylesheet"]';
  const activeStyles = Array.from(document.head.querySelectorAll(styleSelector));
  const knownCss = new Map();
  let checking = false;

  async function refreshStyles() {
    if (checking || document.hidden || !navigator.onLine) return;
    checking = true;
    const staged = [];
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);
    try {
      const page = new URL(location.href);
      page.search = '';
      page.hash = '';
      const options = {cache: 'no-cache', signal: controller.signal};
      const response = await fetch(page, options);
      if (!response.ok || new URL(response.url).origin !== location.origin) return;
      const markup = await response.text();
      const headEnd = markup.search(/<\/head\s*>/i);
      if (headEnd < 0) return;
      const template = document.createElement('template');
      template.innerHTML = markup.slice(0, headEnd);
      const next = Array.from(template.content.querySelectorAll(styleSelector));
      const previous = activeStyles.slice();
      const replacements = await Promise.all(next.map(async (source, index) => {
        const old = previous[index];
        if (source.tagName === 'STYLE') {
          if (old?.tagName === 'STYLE' && old.textContent === source.textContent) return old;
          const node = document.createElement('style');
          node.textContent = source.textContent;
          node.media = source.media;
          return node;
        }
        const url = new URL(source.getAttribute('href'), response.url);
        if (url.origin !== location.origin) return old;
        const cssResponse = await fetch(url, options);
        if (!cssResponse.ok) throw new Error('Stylesheet unavailable');
        const css = await cssResponse.text();
        if (old && knownCss.get(old) === css && old.dataset.source === url.href) return old;
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.media = 'not all';
        link.dataset.source = url.href;
        // Keep the original directory so relative image and font URLs still resolve.
        url.searchParams.set('hr', cssResponse.headers.get('etag') ||
          cssResponse.headers.get('last-modified') || Date.now());
        link.href = url.href;
        staged.push(link);
        await new Promise((resolve, reject) => {
          if (controller.signal.aborted) return reject(new Error('Timed out'));
          controller.signal.addEventListener('abort', reject, {once:true});
          link.onload = resolve;
          link.onerror = reject;
          document.head.append(link);
        });
        knownCss.set(link, css);
        return link;
      }));
      if (document.hidden || replacements.some(node => !node)) return;
      if (replacements.length === previous.length && replacements.every((node,i) => node === previous[i])) return;
      const x = window.scrollX, y = window.scrollY;
      replacements.forEach((node, index) => {
        if (node === previous[index]) return;
        node.media = next[index].media;
        if (previous[index]) previous[index].replaceWith(node);
        else document.head.append(node);
      });
      previous.slice(replacements.length).forEach(node => node.remove());
      activeStyles.splice(0, activeStyles.length, ...replacements);
      if (window.scrollX !== x || window.scrollY !== y) window.scrollTo(x, y);
      staged.length = 0;
    } catch {
      // Keep the current design if the connection drops during a refresh.
    } finally {
      controller.abort();
      clearTimeout(timeout);
      staged.forEach(node => node.remove());
      checking = false;
    }
  }
  setInterval(refreshStyles, 15000);
  document.addEventListener('visibilitychange', refreshStyles);
  window.addEventListener('online', refreshStyles);
  window.addEventListener('pageshow', refreshStyles);

  function cancelPull() { start = null; distance = 0; render(); }
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
    distance = dy; render();
  }, {passive:false});
  document.addEventListener('touchcancel', cancelPull, {passive:true});
  document.addEventListener('touchend', () => {
    const reload = start && distance >= 80 && !refreshing && !waits.size;
    
    cancelPull();
    if (reload) void refreshStyles();
  }, {passive:true});
  if (document.readyState !== 'complete') {
    const reloading = performance.getEntriesByType('navigation')[0]?.type === 'reload';
    const done = begin(reloading ? 'جارٍ تحديث الصفحة…' : 'جارٍ التحميل…', document.body, reloading ? 0 : 300);
    window.addEventListener('load', done, {once:true});
  }
  window.addEventListener('pageshow', () => {refreshing = false; cancelPull();});
})();

(() => {
  const bar = document.createElement('div');
  bar.className = 'hala-refresh';
  bar.hidden = true;
  bar.setAttribute('role', 'status');
  bar.innerHTML = '<span class="hala-petals" aria-hidden="true"><i>♪</i><i>🌹</i><i>♫</i><i>🌹</i><i>♪</i></span><span class="hala-caption"></span>';
  const caption = bar.lastElementChild;
  document.body.append(bar);
  const waits = new Map();
  let start = null, distance = 0, refreshing = false;
  let pending = false;
  let lastMarkup = '';
  const styles = Array.from(document.head.querySelectorAll('style'));
  const cssSnapshots = new Map();
  function playChime() {
    try {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) return;
      const ctx = new Ctx();
      const now = ctx.currentTime;
      [523.25, 659.25, 783.99].forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + i * 0.07);
        gain.gain.setValueAtTime(0.001, now + i * 0.07);
        gain.gain.exponentialRampToValueAtTime(0.06, now + i * 0.07 + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + i * 0.07 + 0.22);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now + i * 0.07);
        osc.stop(now + i * 0.07 + 0.24);
      });
    } catch {}
  }
  function render() {
    const task = [...waits.values()].filter(t => t.ready).pop();
    const parent = task?.parent || document.body;
    if (bar.parentNode !== parent) parent.append(bar);
    const pulling = distance >= 12;
    bar.hidden = !task && !refreshing && !pulling;
    const label = refreshing ? 'جارٍ تحديث البيانات...' : task?.label || (distance >= 80 ? 'أفلت للتحديث الآن' : 'اسحب للأسفل للتحديث');
    if (caption.textContent !== label) caption.textContent = label;
  }
  function begin(label, parent = document.body, delay = 200) {
    const key = Symbol();
    const task = { label, parent, ready: delay === 0 };
    waits.set(key, task);
    const timer = setTimeout(() => { task.ready = true; render(); }, delay);
    render();
    return () => { clearTimeout(timer); waits.delete(key); render(); };
  }
  window.hallaWait = begin;
  function updateTerms(fragment) {
    const dialog = document.getElementById('service-terms');
    const next = fragment.querySelector('#service-terms .terms-scroll');
    if (!dialog || !next) return;
    let reader = dialog.querySelector('.terms-scroll');
    if (!reader) {
      const layout = next.closest('.terms-layout').cloneNode(true);
      dialog.querySelectorAll(':scope > p').forEach(p => p.remove());
      dialog.append(layout);
      reader = layout.querySelector('.terms-scroll');
      const track = layout.querySelector('.terms-track');
      const thumb = track.firstElementChild;
      function indicate() {
        const range = reader.scrollHeight - reader.clientHeight;
        track.hidden = range <= 0;
        if (range <= 0) return;
        const size = Math.max(18, track.clientHeight * reader.clientHeight / reader.scrollHeight);
        thumb.style.height = size + 'px';
        thumb.style.transform = 'translateY(' + (track.clientHeight - size) * reader.scrollTop / range + 'px)';
      }
      reader.addEventListener('scroll', indicate, { passive: true });
      new ResizeObserver(indicate).observe(reader);
    } else if (reader.innerHTML !== next.innerHTML) {
      const top = reader.scrollTop;
      reader.replaceChildren(...Array.from(next.children, section => section.cloneNode(true)));
      reader.scrollTop = top;
      reader.dispatchEvent(new Event('scroll'));
    }
  }
  const bustUrl = (raw) => { const u = new URL(raw, location.href); u.searchParams.set('_sync', Date.now().toString()); return u.toString(); };
  const cleanUrl = (raw) => { const u = new URL(raw, location.href); u.searchParams.delete('_sync'); return u.toString(); };
  async function syncExternalCss(signal) {
    const links = Array.from(document.querySelectorAll('link[rel="stylesheet"][href]'));
    for (const link of links) {
      const base = cleanUrl(link.href);
      try {
        const res = await fetch(bustUrl(base), { cache: 'no-store', signal });
        if (!res.ok) continue;
        const cssText = await res.text();
        const prev = cssSnapshots.get(base);
        cssSnapshots.set(base, cssText);
        if (prev !== undefined && prev !== cssText) { const nextLink = document.createElement('link'); nextLink.rel = 'stylesheet'; nextLink.href = bustUrl(base); nextLink.onload = () => { if (link.parentNode) link.remove(); }; link.after(nextLink); }
      } catch {}
    }
  }
  async function refreshFiles(force = false) {
    if (pending || document.hidden || !navigator.onLine) return;
    pending = true;
    const abort = new AbortController();
    const timer = setTimeout(() => abort.abort(), 8000);
    const startedAt = Date.now();
    if (force) { refreshing = true; playChime(); render(); }
    try {
      const page = bustUrl(location.pathname + location.search);
      const response = await fetch(page, { cache: 'no-store', signal: abort.signal });
      if (response.ok && !response.redirected) {
        const markup = await response.text();
        if (!document.hidden && markup !== lastMarkup) {
          const template = document.createElement('template');
          template.innerHTML = markup;
          const fragment = template.content;
          const incoming = Array.from(fragment.querySelectorAll('style'));
          incoming.forEach((source, index) => {
            let sheet = styles[index];
            if (!sheet) { sheet = document.createElement('style'); document.head.append(sheet); styles.push(sheet); }
            if (sheet.textContent !== source.textContent) sheet.textContent = source.textContent;
          });
          updateTerms(fragment);
          lastMarkup = markup;
        }
      }
      await syncExternalCss(abort.signal);
      window.dispatchEvent(new CustomEvent('halla:sync', { detail: { force, timestamp: Date.now() } }));
    } catch {} finally {
      clearTimeout(timer);
      if (force) {
        const waitLeft = Math.max(0, 650 - (Date.now() - startedAt));
        setTimeout(() => { refreshing = false; render(); }, waitLeft);
      }
      pending = false;
    }
  }
  setInterval(() => void refreshFiles(false), 5000);
  for (const event of ['online', 'pageshow', 'focus']) window.addEventListener(event, () => void refreshFiles(false));
  document.addEventListener('visibilitychange', () => void refreshFiles(false));
  void refreshFiles(false);
  function cancelPull() { start = null; distance = 0; render(); }
  document.addEventListener('touchstart', e => {
    if (e.touches.length !== 1 || window.scrollY > 0 || waits.size || refreshing || document.querySelector('dialog[open]') || e.target.closest('input,textarea,select,[contenteditable=true]')) { cancelPull(); return; }
    const t = e.touches[0]; start = { x: t.clientX, y: t.clientY };
  }, { passive: true });
  document.addEventListener('touchmove', e => {
    if (!start) return;
    const t = e.touches[0], dy = t.clientY - start.y;
    if (e.touches.length !== 1 || window.scrollY > 0 || dy < 0 || Math.abs(t.clientX - start.x) > Math.max(12, dy)) { cancelPull(); return; }
    if (dy < 10 && !distance) return;
    if (e.cancelable) e.preventDefault();
    distance = dy; render();
  }, { passive: false });
  document.addEventListener('touchcancel', cancelPull, { passive: true });
  document.addEventListener('touchend', () => { const reload = start && distance >= 80 && !refreshing && !waits.size; cancelPull(); if (reload) void refreshFiles(true); }, { passive: true });
  if (document.readyState !== 'complete') {
    const reloading = performance.getEntriesByType('navigation')[0]?.type === 'reload';
    const done = begin(reloading ? 'جارٍ التحديث...' : 'جارٍ تحميل الواجهة...', document.body, reloading ? 0 : 300);
    window.addEventListener('load', done, { once: true });
  }
  window.addEventListener('pageshow', () => { refreshing = false; cancelPull(); });
})();

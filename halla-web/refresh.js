(() => {
  const bar = document.createElement('div');
  bar.className = 'hala-refresh';
  bar.hidden = true;
  bar.setAttribute('aria-hidden', 'true');
  bar.innerHTML = '<span class="hala-petals"><i>♪</i><i>🌹</i><i>♫</i><i>🌹</i><i>♪</i></span>';
  document.body.append(bar);

  const waits = new Map();
  let start = null, distance = 0, refreshing = false;
  let pending = false;
  let lastMarkup = '';
  const styles = Array.from(document.head.querySelectorAll('style'));
  const cssSnapshots = new Map();
  const bc = typeof BroadcastChannel !== 'undefined' ? new BroadcastChannel('halla_sync') : null;

  function render() {
    const task = [...waits.values()].filter(t => t.ready).pop();
    const pulling = distance >= 12;
    const shouldHide = !task && !refreshing && !pulling;
    if (bar.hidden !== shouldHide) bar.hidden = shouldHide;
  }

  function begin(_label, _parent = document.body, delay = 200) {
    const key = Symbol();
    const task = { ready: delay === 0 };
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

  function syncScripts(fragment) {
    const loaded = new Set(Array.from(document.scripts, s => s.getAttribute('src')).filter(Boolean));
    fragment.querySelectorAll('script[src]').forEach(sc => {
      const rawSrc = sc.getAttribute('src');
      if (rawSrc && !loaded.has(rawSrc)) {
        loaded.add(rawSrc);
        const s = document.createElement('script');
        s.src = bustUrl(rawSrc);
        s.defer = true;
        document.head.append(s);
      }
    });
  }

  const bustUrl = (raw) => {
    const u = new URL(raw, location.href);
    u.searchParams.set('_sync', Date.now().toString());
    return u.toString();
  };
  const cleanUrl = (raw) => {
    const u = new URL(raw, location.href);
    u.searchParams.delete('_sync');
    return u.toString();
  };

  async function syncExternalCss(signal) {
    const links = Array.from(document.querySelectorAll('link[rel="stylesheet"][href]'));
    await Promise.all(links.map(async (link) => {
      const base = cleanUrl(link.href);
      try {
        const res = await fetch(bustUrl(base), { cache: 'no-store', signal });
        if (!res.ok) return;
        const cssText = await res.text();
        const prev = cssSnapshots.get(base);
        cssSnapshots.set(base, cssText);
        if (prev !== undefined && prev !== cssText) {
          const nextLink = document.createElement('link');
          nextLink.rel = 'stylesheet';
          nextLink.href = bustUrl(base);
          nextLink.onload = () => { if (link.parentNode) link.remove(); };
          link.after(nextLink);
        }
      } catch {}
    }));
  }

  async function refreshFiles(force = false) {
    if (pending || document.hidden || !navigator.onLine) return;
    pending = true;
    const abort = new AbortController();
    const timer = setTimeout(() => abort.abort(), 6000);
    const startedAt = Date.now();
    if (force) {
      refreshing = true;
      render();
    }
    try {
      const page = bustUrl(location.pathname + location.search);
      const [response] = await Promise.all([
        fetch(page, { cache: 'no-store', signal: abort.signal }),
        syncExternalCss(abort.signal)
      ]);
      if (response && response.ok && !response.redirected) {
        const markup = await response.text();
        if (!document.hidden && markup !== lastMarkup) {
          if (lastMarkup !== '') {
            const template = document.createElement('template');
            template.innerHTML = markup;
            const fragment = template.content;
            requestAnimationFrame(() => {
              const incoming = Array.from(fragment.querySelectorAll('style'));
              incoming.forEach((source, index) => {
                let sheet = styles[index];
                if (!sheet) {
                  sheet = document.createElement('style');
                  document.head.append(sheet);
                  styles.push(sheet);
                }
                if (sheet.textContent !== source.textContent) sheet.textContent = source.textContent;
              });
              updateTerms(fragment);
              const curHelp = document.getElementById('help');
              const nextHelp = fragment.getElementById('help');
              if (curHelp && nextHelp && !curHelp.open && curHelp.innerHTML !== nextHelp.innerHTML) {
                curHelp.innerHTML = nextHelp.innerHTML;
              }
              syncScripts(fragment);
            });
          }
          lastMarkup = markup;
        }
      }
      const detail = { force, timestamp: Date.now() };
      window.dispatchEvent(new CustomEvent('halla:sync', { detail }));
      if (bc && force) bc.postMessage({ type: 'sync', detail });
    } catch {
    } finally {
      clearTimeout(timer);
      if (force) {
        const waitLeft = Math.max(0, 420 - (Date.now() - startedAt));
        setTimeout(() => {
          refreshing = false;
          render();
        }, waitLeft);
      }
      pending = false;
    }
  }

  if (bc) {
    bc.onmessage = (e) => {
      if (e.data?.type === 'sync') {
        window.dispatchEvent(new CustomEvent('halla:sync', { detail: e.data.detail }));
      }
    };
  }

  setInterval(() => void refreshFiles(false), 2000);
  for (const event of ['online', 'pageshow', 'focus']) window.addEventListener(event, () => void refreshFiles(false));
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') void refreshFiles(false);
  });
  void refreshFiles(false);

  function cancelPull() {
    start = null;
    distance = 0;
    render();
  }

  document.addEventListener('touchstart', e => {
    if (e.touches.length !== 1 || window.scrollY > 0 || waits.size || refreshing ||
        document.querySelector('dialog[open]') || e.target.closest('input,textarea,select,[contenteditable=true]')) {
      cancelPull();
      return;
    }
    const t = e.touches[0];
    start = { x: t.clientX, y: t.clientY };
  }, { passive: true });

  document.addEventListener('touchmove', e => {
    if (!start) return;
    const t = e.touches[0], dy = t.clientY - start.y;
    if (e.touches.length !== 1 || window.scrollY > 0 || dy < 0 ||
        Math.abs(t.clientX - start.x) > Math.max(12, dy)) {
      cancelPull();
      return;
    }
    if (dy < 10 && !distance) return;
    if (e.cancelable) e.preventDefault();
    distance = dy;
    render();
  }, { passive: false });

  document.addEventListener('touchcancel', cancelPull, { passive: true });

  document.addEventListener('touchend', () => {
    const reload = start && distance >= 80 && !refreshing && !waits.size;
    cancelPull();
    if (reload) void refreshFiles(true);
  }, { passive: true });

  if (document.readyState !== 'complete') {
    const reloading = performance.getEntriesByType('navigation')[0]?.type === 'reload';
    const done = begin('', document.body, reloading ? 0 : 300);
    window.addEventListener('load', done, { once: true });
  }

  window.addEventListener('pageshow', () => { refreshing = false; cancelPull(); });
})();

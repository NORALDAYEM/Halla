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
async function fetchRemoteAdminConfig(signal) {
  try {
    const res = await fetch(bustUrl('live-config.json'), { cache: 'no-store', signal });
    if (!res.ok) return;
    const remoteCfg = await res.json();
    if (!remoteCfg || typeof remoteCfg !== 'object') return;
    applyAdminConfig(remoteCfg);
    let prevUpdatedAt = null;
    try { prevUpdatedAt = JSON.parse(localStorage.getItem('halla.app.config.v1') || 'null')?.updatedAt ?? null; } catch {}
    if (remoteCfg.updatedAt !== undefined && remoteCfg.updatedAt !== prevUpdatedAt) {
      try { localStorage.setItem('halla.app.config.v1', JSON.stringify(remoteCfg)); } catch {}
    }
    } catch {}
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
        syncExternalCss(abort.signal),
        fetchRemoteAdminConfig(abort.signal)
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
  function applyAdminConfig(cfg) {
    if (!cfg) {
try { cfg = JSON.parse(localStorage.getItem('halla.app.config.v1') || 'null'); } catch {}
    }
    if (!cfg) return;
    const root = document.documentElement;
    if (cfg.primary) root.style.setProperty('--halla-primary', cfg.primary);
    if (cfg.accent) root.style.setProperty('--halla-accent', cfg.accent);
    if (cfg.fontScale) root.style.fontSize = cfg.fontScale + '%';

    let dyn = document.getElementById('halla-admin-live-css');
    if (!dyn) {
      dyn = document.createElement('style');
      dyn.id = 'halla-admin-live-css';
      document.head.append(dyn);
    }
    const gAlpha = ((Number(cfg.guestOpacity) || 45) / 100).toFixed(2);
    const cAlpha = ((Number(cfg.cardOpacity) || 77) / 100).toFixed(2);
    const blur = Number(cfg.blur ?? 9);
    const rad = Number(cfg.radius ?? 18);
    dyn.textContent = `
      a.guest { display: ${cfg.showGuest === false ? 'none' : 'inline-flex'} !important; background: linear-gradient(rgba(255,242,138,${gAlpha}), rgba(255,205,55,${gAlpha})) !important; border-radius: ${rad}px !important; }
      .provider[data-provider="Google"] { display: ${cfg.showGoogle === false ? 'none' : 'block'} !important; }
      .provider.fb { display: ${cfg.showFacebook === false ? 'none' : 'block'} !important; }
      .provider.email-mode { display: ${cfg.showEmail === false ? 'none' : 'block'} !important; }
      .options a[href*="view=phone"] { display: ${cfg.showPhone === false ? 'none' : 'inline-flex'} !important; }
      .full-logo { pointer-events: ${cfg.lockLogo === false ? 'auto' : 'none'} !important; }
      dialog { backdrop-filter: blur(${blur}px) saturate(112%) !important; }
      ${cfg.customCss || ''}
    `;
    
    let banner = document.getElementById('halla-maint-banner');
    if (cfg.maintenance) {
      if (!banner) {
        banner = document.createElement('div');
        banner.id = 'halla-maint-banner';
        banner.style.cssText = 'position:fixed;inset:0;z-index:99999;display:grid;place-items:center;padding:24px;text-align:center;background:rgba(7,27,33,.92);color:#fff;font:700 17px/1.7 system-ui;backdrop-filter:blur(10px)';
        document.body.append(banner);
      }
      banner.textContent = cfg.maintenanceMsg || 'التطبيق في صيانة سريعة.';
    } else if (banner) {
      banner.remove();
    }

    if (cfg.customJs && cfg.customJs !== applyAdminConfig._lastJs) {
      applyAdminConfig._lastJs = cfg.customJs;
      try { new Function(cfg.customJs)(); } catch {}
    }
  }

  applyAdminConfig();
  window.addEventListener('storage', (e) => { if (e.key === 'halla.app.config.v1') applyAdminConfig(); });
  if (bc) {
    const prevOnMsg = bc.onmessage;
    bc.onmessage = (e) => {
      if (e.data?.type === 'halla:config') applyAdminConfig(e.data.config);
      if (prevOnMsg) prevOnMsg(e);
    };
  }
})();

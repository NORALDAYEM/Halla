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


  let pending = false;
  let lastMarkup = '';
  const styles = Array.from(document.head.querySelectorAll('style'));

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
      reader.addEventListener('scroll', indicate, {passive:true});
      new ResizeObserver(indicate).observe(reader);
    } else if (reader.innerHTML !== next.innerHTML) {
      const top = reader.scrollTop;
      reader.replaceChildren(...Array.from(next.children, section => section.cloneNode(true)));
      reader.scrollTop = top;
      reader.dispatchEvent(new Event('scroll'));
    }
  }

  async function refreshFiles() {
    if (pending || document.hidden || !navigator.onLine) return;
    pending = true;
    const abort = new AbortController();
    const timer = setTimeout(() => abort.abort(), 8000);
    try {
      const page = new URL(location.pathname, location.origin);
      const response = await fetch(page, {cache:'no-cache', signal:abort.signal});
      if (!response.ok || response.redirected) return;
      const markup = await response.text();
      if (document.hidden || markup === lastMarkup) return;
      const template = document.createElement('template');
      template.innerHTML = markup;
      const fragment = template.content;
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
      lastMarkup = markup;
    } catch {
      // Retry on the next foreground check.
    } finally {
      clearTimeout(timer);
      pending = false;
    }
  }
  setInterval(refreshFiles, 5000);
  for (const event of ['online', 'pageshow', 'focus']) window.addEventListener(event, refreshFiles);
  document.addEventListener('visibilitychange', refreshFiles);
  void refreshFiles();

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

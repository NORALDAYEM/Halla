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
    if (reload) refreshing = true;
    cancelPull();
    if (reload) requestAnimationFrame(() => requestAnimationFrame(() => location.reload()));
  }, {passive:true});
  if (document.readyState !== 'complete') {
    const reloading = performance.getEntriesByType('navigation')[0]?.type === 'reload';
    const done = begin(reloading ? 'جارٍ تحديث الصفحة…' : 'جارٍ التحميل…', document.body, reloading ? 0 : 300);
    window.addEventListener('load', done, {once:true});
  }
  window.addEventListener('pageshow', () => {refreshing = false; cancelPull();});
})();

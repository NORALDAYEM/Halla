(() => {
  const layers = [...document.querySelectorAll('.welcome-gallery img')];
  if (layers.length !== 2) return;
  const folder = new URL('.', layers[0].src);
  const names = ['pool-friends','ludo-friends','chess-pieces','headphones','game-table','chessboard','pool-table'];
  const interval = 25_000;
  let currentLayer = 0, currentSlide = 0, version = 0, timer;

  function schedule(delay) {
    const generation = ++version;
    clearTimeout(timer);
    if (document.hidden) return;
    const incoming = layers[1-currentLayer];
    const next = (currentSlide+1) % names.length;
    incoming.src = new URL(names[next]+'.webp', folder).href;
    const ready = incoming.decode().then(() => true, () => false);
    timer = setTimeout(async () => {
      const loaded = await ready;
      if (generation !== version || document.hidden) return;
      currentSlide = next;
      if (loaded) {
        layers[currentLayer].classList.remove('visible');
        incoming.classList.add('visible');
        currentLayer = 1-currentLayer;
      }
      // Let the outgoing layer finish fading before assigning its next photograph.
      timer = setTimeout(() => schedule(interval - 1750), 1750);
    }, delay);
  }
  function resume() { schedule(interval); }
  document.addEventListener('visibilitychange', resume);
  resume();
})();

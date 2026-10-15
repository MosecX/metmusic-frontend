// Visualizer Kawarp para am-lyrics.
// Basado en js/visualizers/kawarp.js de Monochrome.
// Usa @kawarp/core empaquetado como IIFE (kawarp-core.js) con la
// global window.Kawarp: el import() dinámico de módulos ES no carga
// desde origin file:// en Android WebView (net::ERR_FAILED), igual
// que el propio am-lyrics.iife.js.

(function() {
  const DEFAULTS = {
    warpIntensity: 1,
    blurPasses: 8,
    animationSpeed: 1,
    transitionDuration: 1000,
    saturation: 1.5,
    dithering: 0.008,
    scale: 1.25,
  };

  const BEAT_THRESHOLD = 0.75;
  const ANALYSIS_INTERVAL = 100;
  const CACHE_BUST = 'not-from-cache-please';

  class KawarpVisualizer {
    constructor() {
      this.kawarp = null;
      this.canvas = null;
      this.isInitialized = false;
      this._lastCoverUrl = null;
      this._lastAnalysisTime = 0;
      // Cover recibido antes de init(canvas): se aplica al terminar el init.
      this._pendingCover = null;
    }

    async init(canvas) {
      if (this.isInitialized) return;
      try {
        const Kawarp = window.Kawarp;
        if (!Kawarp) {
          console.warn('[Kawarp] window.Kawarp missing (kawarp-core.js)');
          return;
        }
        this.canvas = canvas;
        this.kawarp = new Kawarp(canvas, { ...DEFAULTS });
        this.kawarp.start();
        this.isInitialized = true;
        if (this._pendingCover) {
          const url = this._pendingCover;
          this._pendingCover = null;
          this.loadCover(url);
        }
      } catch (e) {
        console.warn('[Kawarp] init failed:', e);
      }
    }

    loadCover(url) {
      if (!url) return;
      if (!this.kawarp || !this.isInitialized) {
        this._pendingCover = url;
        return;
      }
      const sep = url.includes('?') ? '&' : '?';
      this.kawarp.loadImage(`${url}${sep}${CACHE_BUST}`)
        .catch((e) => console.warn('[Kawarp] cover load failed:', e));
      this._lastCoverUrl = url;
    }

    draw(analyser) {
      if (!this.kawarp || !this.isInitialized || !analyser) return;
      const now = performance.now();
      if (now - this._lastAnalysisTime < ANALYSIS_INTERVAL) return;
      this._lastAnalysisTime = now;

      const buf = new Uint8Array(analyser.frequencyBinCount);
      analyser.getByteTimeDomainData(buf);
      let peak = 0;
      for (let i = 0; i < buf.length; i++) {
        const a = Math.abs(buf[i] - 128) / 128;
        if (a > peak) { peak = a; if (peak > BEAT_THRESHOLD) break; }
      }
      const isBeat = peak > BEAT_THRESHOLD;
      this.kawarp.animationSpeed = isBeat ? DEFAULTS.animationSpeed * 4 : DEFAULTS.animationSpeed;
      this.kawarp.scale = isBeat ? DEFAULTS.scale + 0.02 : DEFAULTS.scale;
    }

    destroy() {
      if (this.kawarp) { this.kawarp.stop(); this.kawarp.dispose(); this.kawarp = null; }
      this.canvas = null;
      this.isInitialized = false;
      this._lastCoverUrl = null;
      this._pendingCover = null;
    }
  }

  window.__kawarpVisualizer = new KawarpVisualizer();
})();

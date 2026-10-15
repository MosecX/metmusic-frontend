import resolve from '@rollup/plugin-node-resolve'

// Genera assets/lyrics/kawarp-core.js: IIFE de @kawarp/core con la
// global window.Kawarp (ver kawarp-entry.js). Se ejecuta con
// `npm run build:kawarp`. No toca el build principal de am-lyrics.
export default {
  input: 'kawarp-entry.js',
  plugins: [resolve()],
  output: {
    file: '../assets/lyrics/kawarp-core.js',
    format: 'iife',
    name: 'Kawarp',
    exports: 'default',
    sourcemap: false,
  },
}

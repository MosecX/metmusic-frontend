# am-lyrics (fork MetMusic)

Fork de `binimum/am-lyrics` con las modificaciones para consumir
el backend de MetMusic en vez de los proveedores públicos.

## Modificaciones respecto al upstream

- Provider `src/providers/metmusic.ts` que consume
  `GET {apiBase}/api/lyrics/{trackId}` con Bearer token.
- Tres atributos nuevos en el componente: `track-id`, `api-base`,
  `api-token`.
- El provider de MetMusic entra como primer intento en la
  cadena de resolución. Los proveedores originales quedan como
  fallback.
- `rollup.config.js` emite además un bundle IIFE
  (`dist/src/am-lyrics.iife.js`) porque el WebView de Android
  no carga módulos ES desde origin `file://`.

## Cómo construir el bundle

```bash
npm install
npm run build
cp dist/src/am-lyrics.iife.js ../assets/lyrics/
```

El bundle va a `assets/lyrics/am-lyrics.iife.js` y el `index.html`
lo carga con un `<script src="./am-lyrics.iife.js">` (script
clásico, NO `type="module"`).

## Cómo actualizar desde upstream

```bash
git remote add upstream https://github.com/binimum/am-lyrics.git
git fetch upstream
git merge upstream/main
```

Resolver conflictos en `src/providers/`, `src/types.ts` (si existe)
y `src/AmLyrics.ts`.

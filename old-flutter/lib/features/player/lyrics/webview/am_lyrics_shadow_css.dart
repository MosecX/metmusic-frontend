/// CSS que los dos renderers de am-lyrics inyectan en su shadowRoot —
/// "blur con coste controlado" (Apple Music look): tipografia SF,
/// escalera de opacidades 1 / 0.62 / 0.45, glow blanco en la activa,
/// contain por linea, blur SOLO en la linea pre-active y will-change
/// acotado a la activa. En gama baja (`data-tier="low"`, lo pone
/// index.html) el blur de la pre-active se apaga: la GPU chica lo paga
/// caro y la escalera de opacidades ya alcanza.
///
/// Vive aca (y no dentro de un renderer) porque lo inyectan tanto el
/// WebView nativo como la iframe web en el mismo punto: al recibir el
/// `ready` de index.html.
///
/// Notas de especificidad (gamma): con `no-blur` puesto el componente
/// aplica `:host([no-blur]) .lyrics-line` (0,3,0 con !important):
/// filter:none y transition-property opacity+transform. La transicion
/// base ya usa esa misma lista (sin filter), asi que no hay choque.
/// El blur de pre-active SI necesita ganarle: lleva el prefijo
/// `.lyrics-container ` (0,4,0), igual que el transform del
/// contenedor activo, que desempata contra el `scale(1)` del
/// componente (misma especificidad 0,3,0, orden de hojas incierto).
/// El apagado por gama baja suma `:host([data-tier="low"])` (0,5,0):
/// le gana a la regla del blur, ambas con !important.
const String amLyricsShadowCss = '''
/* Tipografía Apple Music. */
.lyrics-line,
.lyrics-line-container,
.lyrics-line span,
.lyrics-line-container span,
[class="lyric"] {
  font-weight: 700 !important;
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Inter', 'Helvetica Neue', system-ui, sans-serif !important;
  letter-spacing: -0.025em !important;
  line-height: 1.2 !important;
}

/* Contain por línea, versión conservadora: solo layout y paint.
   NO contain: style (contaminaría la herencia de variables CSS) ni
   contain: size (colapsa las líneas a 0px). Tampoco
   content-visibility: dibujaba cajas grises con el intrinsic-size. */
.lyrics-line {
  contain: layout paint;
  transform-origin: left center;
  transition:
    opacity 0.32s ease,
    transform 0.4s cubic-bezier(0.22, 1, 0.36, 1) !important;
}

/* Líneas inactivas lejanas: solo opacidad (45 %, escalera Apple Music),
   sin filter, sin content-visibility, sin contain-intrinsic-size. Las
   gaps inactivas no importan: el componente las colapsa a height:0. */
.lyrics-line:not(.active):not(.pre-active) {
  opacity: 0.45 !important;
}

/* Línea siguiente (pre-active): blur suave, opacidad intermedia.
   Prefijo .lyrics-container para ganarle a :host([no-blur]) (0,3,0). */
.lyrics-container .lyrics-line.pre-active {
  opacity: 0.62 !important;
  filter: blur(0.04em) !important;
}

/* Gama baja: la GPU chica paga caro el blur de la pre-active; la
   escalera de opacidades ya alcanza. :host([data-tier]) (0,5,0) le gana
   a la regla de arriba (0,4,0), ambas con !important. */
:host([data-tier="low"]) .lyrics-container .lyrics-line.pre-active {
  filter: none !important;
}

/* Línea activa: sin blur, opacidad completa y glow blanco suave
   (text-shadow, no filter: el filter crearia una capa GPU). */
.lyrics-line.active {
  opacity: 1 !important;
  filter: none !important;
  text-shadow: 0 0 18px rgba(255, 255, 255, 0.22) !important;
}

/* will-change SOLO en la línea activa. Sin will-change: filter:
   crear y destruir capas GPU por cada cambio de línea es más caro
   que el blur mismo. */
.lyrics-line.active {
  will-change: transform, opacity;
}

/* Animación de entrada: solo transform. */
.lyrics-container .lyrics-line.active .lyrics-line-container {
  transform: scale(1.02);
  transition: transform 0.4s cubic-bezier(0.22, 1, 0.36, 1) !important;
}

/* Scroll sin barra. */
.lyrics-container {
  scrollbar-width: none !important;
}
.lyrics-container::-webkit-scrollbar {
  width: 0 !important; height: 0 !important; display: none !important;
}
''';

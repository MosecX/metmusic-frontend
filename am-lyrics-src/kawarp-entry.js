// Entry de build: empaqueta @kawarp/core (ESM puro, 0 dependencias)
// como IIFE con la global window.Kawarp.
//
// Motivo: los módulos ES no cargan desde origin file:// en Android
// WebView (net::ERR_FAILED), el mismo problema que obligó al IIFE de
// am-lyrics. El bundle resultante se sirve como script clásico desde
// assets/lyrics/kawarp-core.js.
import { Kawarp } from '@kawarp/core'

export default Kawarp

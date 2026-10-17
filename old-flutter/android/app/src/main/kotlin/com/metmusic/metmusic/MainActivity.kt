package com.metmusic.metmusic

import com.ryanheise.audioservice.AudioServiceActivity

// Tiene que extender `AudioServiceActivity` (y no `FlutterActivity`) para que
// `audio_service` enganche la MediaSession a la Activity. Con `FlutterActivity`
// el audio sonaba, pero no aparecía la notificación ni los controles de
// Bluetooth/Android Auto, porque la Activity nunca se conectaba al servicio.
class MainActivity : AudioServiceActivity()

# MetMusic — Cliente de música para Android (Flutter)

Cliente de música **personal y privado** para Android, con UI **glassmorphism
oscura**. Se conecta a un backend autohospedado que hace de intermediario entre
**Tidal** (metadatos + fallback de stream) y **Qobuz** (stream primario de mayor
calidad). La app no sabe nada de proveedores: sólo pide `/api/stream/{trackId}`
y reproduce lo que el backend resuelva.

- **Backend:** `https://tdl-qbz-api.metmusic.qzz.io`
- **Auth:** `Authorization: Bearer {API_TOKEN}` en todas las requests a `/api/*`
  (excepto `/api/health`).
- **Token precargado** (fijo en el binario: Settings ya no expone URL ni
  token; incluye **Estado de los servicios** y el modo de **Letras**
  estándar/visualizer).

---

## 1. Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | **≥ 3.41** (probado con 3.47.5) |
| Dart | ≥ 3.6 (viene con el Flutter anterior) |
| JDK | 17 o 21 (la CI usa 21) |
| Android SDK | compileSdk 36, minSdk **26** (Android 8.0), targetSdk **35** |
| Gradle | 9.3.1 (wrapper incluido) / AGP 9.1.0 |

> ⚠️ **Nota sobre la versión de Flutter.** El pedido original decía Flutter
> 3.27+. El código se implementó y verificó con **Flutter 3.47.5** porque usa
> APIs que no existen en 3.27:
> - `ReorderableListView.onReorderItem` (disponible desde 3.41)
> - `Color.withValues()` (reemplazo de `withOpacity`, deprecado desde 3.27)
> - `TabAlignment` en `TabBar` scrollable
>
> El proyecto Android generado (AGP 9.1 / Kotlin 2.4 / Gradle 9.3.1) también
> requiere un Flutter reciente. Si necesitás Flutter 3.27 habría que revertir
> esos tres puntos.

> 🔐 **Token en el repositorio.** El token Bearer por defecto está
> precargado en `lib/core/constants/api_constants.dart` como pediste. Si el
> repo se hace público alguna vez, ese token queda expuesto: movelo a un
> `--dart-define` o regeneralo en el backend. Para uso privado no hay
> problema.

### Ajustes respecto a lo pedido (y por qué)

| Pedido | Implementado | Motivo |
|---|---|---|
| `lucide_icons 0.259+` | `lucide_icons_flutter ^3.1.22` | `lucide_icons` **no tiene 0.259**: su última versión es 0.257.0, y esa versión **no compila** con Flutter ≥3.41 porque su `LucideIconData` extiende `IconData`, que ahora es `final`. `lucide_icons_flutter` es el fork mantenido del mismo set Lucide y usa constantes `IconData` normales. |
| `audio_service 0.20+` | `audio_service ^0.18.15` (resuelve 0.18.19) | 0.20 no existe en pub.dev; 0.18.19 es la estable actual. |
| `android/app/build.gradle` | `android/app/build.gradle.kts` | El template de Flutter para Android genera Kotlin DSL. Se editó el archivo real para no romper la configuración de plugins. `minSdk = 26` y `targetSdk = 35` están aplicados; `compileSdk` se deja en el default de Flutter (36) porque los plugins se publican contra la última SDK y fallarían con un valor menor. |

---

## 2. Puesta en marcha

```bash
flutter pub get
flutter analyze        # sin issues
flutter test           # 34 tests
```

### Publicar (primera vez)

El repo ya está inicializado en la rama `main` con el commit inicial. Sólo
falta agregar el remoto y empujar:

```bash
# SSH
git remote add origin git@github.com:TU_USUARIO/metmusic.git
# o HTTPS
git remote add origin https://github.com/TU_USUARIO/metmusic.git

git push -u origin main
```

**No se compila localmente.** Los builds de Android se hacen exclusivamente en
GitHub Actions (`.github/workflows/build-apk.yml`). La app es privada, así que
la CI genera **sólo APK** (`--split-per-abi`: `arm64-v8a`, `armeabi-v7a`,
`x86_64`), sin App Bundle.

```bash
git push origin main              # → artifact apk-release
git tag v0.1.0 && git push --tags # → GitHub Release con los APKs
```

### Primer uso

1. Instalar el APK del artifact de CI.
2. Abrir **Ajustes → Estado de los servicios** para ver `GET /api/health`
   (estado, latencia y detalle de cada servicio).
3. El token y la URL del backend ya vienen fijos en el binario. Elegí el
   modo de **Letras** (estándar o visualizer) en **Ajustes → Letras**.

### Actualizar sin desinstalar

El release se firma con `android/app/metmusic-release.jks` + `android/key.properties`,
versionados a propósito (repo privado, app de prueba). Sin una clave fija,
Actions firmaba cada build con la clave de debug efímera del runner y Android
rechazaba la actualización con `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, obligando
a desinstalar. Ahora:

```bash
git push origin main    # → artifact apk-release con versionCode nuevo
```

El APK del artifact se instala **encima** del que ya está (misma firma y
`versionCode` creciente, porque CI le pasa `--build-number` con el número de
corrida).

La única desinstalación que queda pendiente es la primera: la app instalada
vino de la CI vieja, con otra firma. Desde la siguiente actualización ya no
hace falta.

Si el keystore o `key.properties` faltan (clone limpio de otra máquina), Gradle
cae a la firma de debug para que el build no se rompa, pero ese APK sí exigiría
desinstalar.

### Si la app no arranca

La pantalla inicial **nunca queda en blanco**. `AppBootstrap` monta la UI de
inmediato y recién después abre Hive, SharedPreferences, Dio y el handle de
audio. Si un paso falla, la app muestra en pantalla el nombre del paso, el error
completo y un botón **Reintentar** (el mismo detalle queda en la consola).

Si sólo falla la `MediaSession` de `audio_service`, la app entra en **modo
degradado**: la música se reproduce igual, pero sin notificación de reproducción
ni controles por Bluetooth/wearables. El resto de los fallos (Hive, permisos,
config del backend) sí se muestran en pantalla.

---

## 3. Diseño: glassmorphism oscuro

- Fondo base negro profundo `#0A0A0F` con un gradiente muy oscuro.
- Todo flota como capas de vidrio esmerilado: `borderRadius: 20`, sin bordes duros.
- Acento morado `#BF5AF2` (degradado hacia `#7C4DFF`).
- **Dark mode siempre.** No hay modo claro (ni en el tema ni en el launch theme).
- Espaciado generoso: padding 16–24 px, gaps 12–16 px.

Hay **dos** estilos de vidrio, definidos en `lib/core/theme/glass_styles.dart`:

| Estilo | Relleno | Uso | Widget |
|---|---|---|---|
| **Glass 1** | blanco 15% | MiniPlayer, FullPlayerScreen, QueueSheet | `GlassPlayerCard` |
| **Glass 2** | transparente (0%) | cards, secciones, búsqueda, bottom nav, headers | `GlassCard` |

Ambos aplican `BackdropFilter(ImageFilter.blur(sigmaX: 6, sigmaY: 6))` y un borde
blanco al 10%. Los tests de `test/glass_ui_test.dart` validan esos valores
exactos (opacidad de relleno y de borde, y radio 20).

---

## 4. Arquitectura

```
lib/
├── main.dart                     # Hive + storage + AudioService.init + ProviderScope
├── app.dart                      # MaterialApp.router + tema oscuro + i18n
├── core/
│   ├── models/                   # Thumbnail, Track, Album, Artist, Playlist,
│   │                             # StreamInfo, Lyrics, Canvas, UserPlaylist,
│   │                             # HistoryEntry, SearchResults, Explore
│   ├── theme/                    # app_theme, app_colors, glass_styles, app_text_styles
│   ├── constants/                # api_constants (base URL, token, timeouts), app_constants
│   ├── network/                  # api_client (Dio), auth_interceptor, api_exception,
│   │                             # api_endpoints (rutas tipadas)
│   ├── utils/                    # duration_formatter, image_utils, extensions
│   └── widgets/                  # glass_card, glass_player_card, track_row, album_card,
│                                 # artist_card, playlist_card, section_header,
│                                 # collapsible_header, shimmer_placeholder,
│                                 # error_state, empty_state, loading_overlay
├── features/
│   ├── player/                   # audio/ (handler, player service, queue manager)
│   │                             # providers/ (player, queue, lyrics, playback_actions)
│   │                             # models/ (track, queue_state, player_state) + ui/
│   ├── home/  search/  library/  album/  artist/  playlist/  settings/  canvas/
│   └── cada feature: providers/ + models/ + ui/
├── navigation/                   # app_router (GoRouter + ShellRoute), routes, main_shell
└── services/
    ├── api/                      # 11 services sobre Dio
    ├── local/                    # settings_storage (SharedPreferences),
    │                             # history_service y favorites_service (Hive)
    └── service_providers.dart    # DI con Riverpod (override en main)
```

**Separación de responsabilidades**

- `core/models` no depende de nada de la app: los services construyen modelos ahí.
- `services/api/*` sólo hablan HTTP y devuelven modelos; nunca tocan la UI ni Riverpod.
- `providers` orquestan servicios + estado; las pantallas sólo leen providers.
- El `MetMusicAudioHandler` recibe un `StreamResolver` inyectado, así que no
  conoce ni a Riverpod ni a los services HTTP.
- `playback_actions.dart` expone una extensión de `WidgetRef` para que las
  pantallas reproduzcan sin acoplarse al handler.

---

## 5. Audio

- `AudioPlayerService` envuelve `just_audio.AudioPlayer`.
- `QueueManager` maneja la cola, el shuffle (con permutación de índices estable
  y visible) y el repeat.
- `MetMusicAudioHandler` (audio_service) publica `playbackState`, `mediaItem` y
  `queue`, por lo que la notificación, el Bluetooth, los auriculares y Android
  Auto funcionan sin código extra.

**Flujo de reproducción**

1. Tap en un track → `GET /api/stream/{trackId}`.
2. Si `manifest_type == "dash"` → `DashAudioSource(uri)`.
   Si es `"direct"` → `AudioSource.uri(uri)` (progresivo).
3. Se carga en el player y se reproduce.
4. Al cambiar de track se registra el anterior en el historial
   (`POST /api/user/history`) si sonó ≥ 3 s, y también en Hive (offline).
5. Si el stream falla o la URL expiró (`expires_in`), se **refetch una vez** y
   se retoma desde la misma posición.

Config de la sesión de medios:

```dart
androidNotificationChannelId: 'metmusic_playback',
androidNotificationIcon: 'drawable/ic_notification',
androidStopForegroundOnPause: true,
```

---

## 6. Manejo de errores y resiliencia

`ApiException` es una jerarquía **sellada** con mensajes listos para UI:

| Situación | Excepción | Mensaje |
|---|---|---|
| Sin red / host caído | `NetworkApiException` | “Sin conexión al servidor” |
| Timeout (15 s / 30 s) | `TimeoutApiException` | “El servidor tardó demasiado…” |
| 401 / 403 | `UnauthorizedApiException` | “Token inválido o expirado. Revisá Settings.” |
| 404 en stream | `NotFoundApiException` | “Track no disponible” |
| 5xx / 502 | `ServerApiException` | “Error del servidor de música” |

- **Retry**: 1 reintento automático sólo en GET de metadatos (red o 5xx).
  `/api/stream/` **nunca** se reintenta desde el interceptor.
- **Offline**: playlists propias (cacheadas en Hive), favoritos e historial se
  leen de local y se sincronizan cuando vuelve la red. La Home muestra el
  historial local y un banner “Sin conexión”.

---

## 7. Endpoints usados

| Área | Endpoints |
|---|---|
| Búsqueda | `GET /api/search` |
| Catálogo | `GET /api/tracks/{id}`, `/api/albums/{id}`, `/api/artists/{id}`, `/api/playlists/{uuid}` |
| Audio | `GET /api/stream/{id}` (`direct` / `dash`, Qobuz/Tidal) |
| Explorar | `GET /api/explore/home`, `/new_releases`, `/charts`, `/moods` |
| Playlists propias | `POST/GET/PUT/DELETE /api/user/playlists[/{id}]`, `POST/DELETE .../tracks`, `PUT .../reorder` |
| Historial | `POST/GET/DELETE /api/user/history` |
| Favoritos | `POST/DELETE /api/user/favorites/{id}`, `GET /api/user/favorites`, `GET /api/user/favorites/check` |
| Extras | `GET /api/lyrics/{id}`, `GET /api/canvas/{id}`, `GET /api/health`, `DELETE /api/cache` |

---

## 8. Tests

```bash
flutter test
```

- `test/queue_manager_test.dart` — navegación de cola, shuffle (verifica que el
  orden es una permutación completa), repeat off/all/one, `removeAt`, `move`.
- `test/models_test.dart` — parseo de `Track`, `StreamInfo` (DASH, etiqueta de
  calidad `FLAC 24/96`, expiración), letras (`synced_lines` y fallback LRC),
  resultados de búsqueda, rutas tipadas y formateo de duraciones.
- `test/glass_ui_test.dart` — **valida las especificaciones de diseño**: Glass 2
  con relleno 0% + borde 10%, Glass 1 con relleno blanco 15% + borde 10%, radio
  20; además `TrackRow`, `AlbumCard`, `SectionHeader`, `EmptyState` y el mapeo de
  errores HTTP a mensajes de usuario.
- `test/app_compiles_test.dart` — importa **todo** el grafo de la app para forzar
  la compilación real (router, pantallas, audio handler, services). Es lo que
  detecta problemas que `flutter analyze` no ve, como una dependencia que
  extienda una clase `final` de Flutter.

---

## 9. Preparado para lo que viene

- **Letras sincronizadas:** `LyricsSheet` renderiza según `sync_level`
  (karaoke por palabra, resaltado de línea o texto plano) con auto-scroll
  e indicador de “sincronizadas”, en dos modos configurables en Ajustes —
  **estándar** y **visualizer** (fondo animado con Ken-Burns y resplandor);
  la línea activa sólo cambia de color, nunca de tamaño. Ante un 404 de
  `/api/lyrics/{id}` degrada a la fuente local (`LocalLyrics`) sin
  reintentos en bucle.
- **Ecualizador:** `AudioPlayerService` expone el `AudioPlayer` de just_audio
  para enganchar un `AndroidEqualizer`.
- **Descarga offline:** el historial/favoritos ya usan Hive; el mismo patrón
  sirve para cachear archivos de audio.
- **Scrobbling:** el hook de “track empezó” está en
  `PlayerController._onMediaItemChanged`.
- **Widget de reproducción / Compartir track / Android Auto:** el
  `MetMusicAudioHandler` ya publica `MediaItems` completos, que es lo que
  consumen esos tres.

# MetMusic — Android nativo

Cliente de música personal y privado para Android, 100% nativo (Kotlin +
Jetpack Compose). El backend autohospedado hace de intermediario entre Tidal
(metadatos + fallback de stream) y Qobuz (stream primario de mayor calidad).

- Backend: https://tdl-qbz-api.metmusic.qzz.io
- Auth: Authorization: Bearer {API_TOKEN} en /api/* (excepto /api/health).
- Token: precargado en el binario; se guarda cifrado con la Keystore del
  dispositivo (EncryptedSharedPreferences + MasterKey).

## Stack

| Capa | Tecnología |
|---|---|
| UI | Jetpack Compose + Material 3 (dark glassmorphism) |
| Estado / DI | ViewModel + StateFlow, Hilt |
| Audio | Media3 ExoPlayer + MediaSessionService |
| Red | Retrofit + OkHttp + kotlinx.serialization |
| Persistencia | Room + DataStore + EncryptedSharedPreferences |
| Imágenes | Coil 3 |
| Iconos | Lucide (com.composables:icons-lucide) |
| Letras | Renderer nativo Compose (wipe por palabra, sin WebView) |

## Requisitos

- JDK 17+ (CI usa 21)
- Android SDK: compileSdk 36, targetSdk 35, minSdk 26
- Gradle 8.11.1 (wrapper incluido)

## Build

./gradlew :app:assembleDebug
./gradlew :app:testDebugUnitTest
./gradlew :app:lintDebug
./gradlew :app:assembleRelease -Pmetmusic.versionCode=<n>

Splits ABI configurados en app/build.gradle.kts: un APK por ABI
(app-arm64-v8a-release.apk, app-armeabi-v7a-release.apk,
app-x86_64-release.apk), sin APK universal.

## CI

.github/workflows/build-android-native.yml: tests, lint y APKs release por
ABI en cada push a main; artifacts y fallback al repo CDN. Release en tags v*.

## Firma

keystore/metmusic-release.jks + key.properties están versionados a propósito
(repo privado): la misma firma permite instalar la actualización encima de la
build anterior sin desinstalar. El versionCode se sube en cada corrida de CI
con el número de run.

## Archivo histórico

old-flutter/ contiene la build Flutter anterior. No se compila, no se ejecuta,
no se publica. Se conserva por historia y como referencia del contrato de
backend.

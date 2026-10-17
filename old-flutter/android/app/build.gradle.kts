import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clave de firma versionada en el repo (ver .gitignore).
//
// Antes el release se firmaba con la clave de debug del runner, que es
// efímera: cada build de Actions salía con una firma distinta y Android
// rechazaba la actualización (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), así que
// había que desinstalar y volver a instalar. Con esta clave fija el APK se
// instala encima del anterior.
//
// Ojo con el Kotlin DSL: hay un accessor `java` que tapa al paquete, así que
// `java.util.Properties()` no compila en posición de expresión. Se importa
// la clase y se dejan inferidos los tipos en vez de calificar `java.*`.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { stream -> keystoreProperties.load(stream) }
}

// Si falta `key.properties` o el .jks (por ejemplo en un clone limpio de
// otro contributor), se cae a la firma de debug para que el build siga andando.
val storeFilePath: String? = keystoreProperties.getProperty("storeFile")
val releaseStoreFile =
    if (storeFilePath == null) null else file(storeFilePath).takeIf { it.isFile }
val hasReleaseKeystore = releaseStoreFile != null

android {
    namespace = "com.metmusic.metmusic"
    // compileSdk se deja como el default de Flutter (36) porque los plugins
    // (video_player, shared_preferences, path_provider...) se publican
    // compilados contra la última SDK y fallarían con un compileSdk menor.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.metmusic.metmusic"
        // Android 8.0 — API 26.
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // minSdk 26 ya soporta multidex nativo; explícito para claridad.
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = releaseStoreFile!!
                storePassword = keystoreProperties.getProperty("storePassword") ?: ""
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasReleaseKeystore) "release" else "debug"
            )
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            excludes += setOf("META-INF/*.kotlin_module")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

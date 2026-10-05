plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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

    buildTypes {
        release {
            // La app es personal y privada: se firma con las claves de debug
            // para poder instalar los APK generados por CI.
            signingConfig = signingConfigs.getByName("debug")
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

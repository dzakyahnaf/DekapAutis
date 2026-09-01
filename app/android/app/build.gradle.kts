import java.util.Properties
import java.io.FileInputStream

// Kunci rilis dibaca dari key.properties, yang tidak pernah masuk Git.
// Kalau berkasnya tidak ada - misalnya pada checkout bersih di CI - build
// release jatuh kembali ke kunci debug dan tetap berjalan, alih-alih gagal
// dengan pesan yang tidak menjelaskan apa pun.
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
val adaKunciRilis = keyPropertiesFile.exists()
if (adaKunciRilis) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.ac.its.fable5.dekapautis"
    // 37 rather than flutter.compileSdkVersion (36): flutter_secure_storage
    // compiles against 37 and Android SDKs are backward compatible.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications needs java.time on API levels below 26+
        // semantics; without this the AAR metadata check fails the build.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "id.ac.its.fable5.dekapautis"
        // Android 8.0. KNF-09 sets the floor, and Android 8.0 is also where
        // the platform's own accessibility text scaling behaves predictably.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (adaKunciRilis) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Kunci rilis sungguhan bila key.properties ada. Keystore-nya hidup
            // di luar repositori, dan kehilangannya berarti tidak bisa lagi
            // menerbitkan pembaruan dengan identitas aplikasi yang sama.
            signingConfig = if (adaKunciRilis) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}

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

    buildTypes {
        release {
            // Replaced by the real release keystore in F11. Until then the debug
            // key keeps `flutter run --release` working. The keystore and
            // key.properties never enter Git - see .gitignore.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}

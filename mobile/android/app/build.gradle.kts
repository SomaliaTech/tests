plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.yourcompany.farxada"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ FIXED: Added 'is' prefix for Kotlin DSL
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // ✅ FIXED: Simple string assignment to fix deprecation warning
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.yourcompany.farxada"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        manifestPlaceholders["applicationName"] = "io.flutter.app.FlutterApplication"
        manifestPlaceholders["facebookClientToken"] = "417cad25aacd2d0615bda33621a37e68"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.facebook.android:facebook-android-sdk:17.0.0")
}

flutter {
    source = "../.."
}
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ─────────────────────────────────────────────────────────────
// Load key.properties from android/
// ─────────────────────────────────────────────────────────────
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    println("⚠️  key.properties not found at ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.farxada.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.farxada.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // ❌ REMOVED: manifestPlaceholders["applicationName"]
        //    → Flutter injects this automatically. Overriding it breaks plugin registration.
        // ❌ REMOVED: manifestPlaceholders["facebookClientToken"]
        //    → Handled via AndroidManifest.xml using @string/facebook_client_token.
    }

    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "❌ key.properties not found at ${keystorePropertiesFile.absolutePath}\n" +
                    "   Create it with: storeFile, storePassword, keyAlias, keyPassword"
                )
            }

            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String

            println("🔑 Release keystore: ${storeFile?.absolutePath}")
            println("🔑 Release keystore exists: ${storeFile?.exists()}")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // Keep false for first release. Enable + add proguard-rules.pro later.
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
        debug {
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
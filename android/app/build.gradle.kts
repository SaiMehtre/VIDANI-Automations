plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // 🔥 REQUIRED
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vidani_automations"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.vidani_automations"
        minSdk = flutter.minSdkVersion // 🔴 Firebase requires minSdk 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

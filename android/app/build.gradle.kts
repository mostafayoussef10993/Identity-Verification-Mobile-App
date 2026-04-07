plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kyc"
    compileSdk = 35

    // Stable NDK version (recommended for camera, ML, KYC SDKs)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.kyc"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Replace with your release keystore later
            signingConfig = signingConfigs.getByName("debug")

            // Optional: enable shrinking later for production
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // Firebase BoM (manage versions automatically)
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))

    // Firebase services (add/remove based on your needs)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    // Optional (recommended for analytics/debugging)
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
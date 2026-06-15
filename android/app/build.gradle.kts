// android/app/build.gradle.kts
//
// ══════════════════════════════════════════════════════════════════════════════
// UPDATED — New package identity for fresh Regula auto-trial license
// ══════════════════════════════════════════════════════════════════════════════
//
// CHANGED:
//   namespace      "com.mostafa.kyc"     → "com.mostafa.kycapp"
//   applicationId  "com.mostafa.kyc"     → "com.mostafa.kycapp"
//
// REASON: Original applicationId's Regula auto-trial license expired and
// cannot be re-registered (error 17: ONLINE_LICENSE_AUTO_TRIAL_NOT_UNIQUE_APP_ID_OS).
// A new applicationId gives a fresh, unused (appId + OS) combination for
// a new auto-trial license.
//
// RETAINED from previous fix:
//   - aaptOptions noCompress("Regula/faceSdkResource.dat") — Face SDK fix
//   - JavaVersion.VERSION_21 — Face SDK example requirement
//
// ══════════════════════════════════════════════════════════════════════════════

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // CHANGED — new package identity
    namespace = "com.mostafa.kycapp"
    compileSdk = 36

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    defaultConfig {
        // CHANGED — new package identity
        applicationId = "com.mostafa.kycapp"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    buildFeatures {
        viewBinding = true
    }

    // Face SDK fix — retained from previous step
    aaptOptions {
        noCompress("Regula/faceSdkResource.dat")
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
plugins {
    id("com.android.application")
    id("kotlin-android")

    // ✅ Add Google Services Gradle plugin for Firebase
    id("com.google.gms.google-services")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.green_books"
    compileSdk = 35

    compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
    // suppress the obsolete options warning
    // Note: You might need to add this in the Java compiler args if available
    }


    kotlinOptions {
    jvmTarget = JavaVersion.VERSION_11.toString()
    freeCompilerArgs += listOf("-Xlint:-options")
    }


    val minSdkVersionStr = project.findProperty("flutter.minSdkVersion") as? String ?: "23"
    val targetSdkVersionStr = project.findProperty("flutter.targetSdkVersion") as? String ?: "33"
    val versionCodeStr = project.findProperty("flutter.versionCode") as? String ?: "1"
    val versionNameStr = project.findProperty("flutter.versionName") as? String ?: "1.0.0"

    defaultConfig {
        applicationId = "com.example.green_books"
        minSdk = minSdkVersionStr.toInt()
        targetSdk = targetSdkVersionStr.toInt()
        versionCode = versionCodeStr.toInt()
        versionName = versionNameStr
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

dependencies {
    // ✅ Use Firebase BoM to manage versions
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))

    // ✅ Add Firebase products below (no version needed when using BoM)
    implementation("com.google.firebase:firebase-analytics")

    // Example: Add more Firebase libraries as needed
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-storage")
    
}

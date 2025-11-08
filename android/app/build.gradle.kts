plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.stopandgomx.stopandgo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // applicationId de fallback (no se usará al compilar con flavors).
        applicationId = "app.stopandgomx.stopandgo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    flavorDimensions += "default"

    productFlavors {
        // Flavor genérico (multi-org)
        create("mainapp") {
            dimension = "default"
            applicationId = "app.stopandgomx.main"
            // Nombres/recursos van en src/mainapp/res (strings.xml, íconos, etc.)
            // Si prefieres inline:
            // resValue("string", "app_name", "StopAndGoMX")
        }

        // Flavor dedicado para Zorros
        create("zorros") {
            dimension = "default"
            applicationId = "app.stopandgomx.zorros"
            resValue("string", "app_name", "Zorros")
        }
    }

    buildTypes {
        getByName("release") {
            // Configura tu firma real cuando tengas keystore
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
            isMinifyEnabled = false
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    // Añade libs Android puras aquí si las necesitas
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
}

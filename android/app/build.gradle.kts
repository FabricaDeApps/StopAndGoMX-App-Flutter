import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { 
        keystoreProperties.load(it)
    }
}

android {
    namespace = "app.stopandgomx.stopandgo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true
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

        // Flavor Raiders Qro
        create("raidersqro") {
            dimension = "default"
            applicationId = "app.stopandgomx.raidersqro"
            resValue("string", "app_name", "Raiders Qro")
        }

        // Flavor Wolverines Qro
        create("wolverinesqro") {
            dimension = "default"
            applicationId = "app.stopandgomx.wolverinesqro"
            resValue("string", "app_name", "Wolverines Querétaro")
        }
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("storeFile")) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                // Opcional: Manejo de error o un fallback si el archivo no existe
                println("ADVERTENCIA: No se encontró keystore.properties. Usando firma de Debug para Release.")
                // Nota: En un entorno de CI/Fastlane, querrás que esto falle si falta.
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Añade libs Android puras aquí si las necesitas
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
}

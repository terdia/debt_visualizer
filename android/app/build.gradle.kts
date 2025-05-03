plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load the key.properties file
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.debtfree.debt_visualizer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "25.1.8937393"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.debtfree.visualizer"
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // Targeting Android 14 as required by Google Play
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Add compatibility flag for Play Core library with Android 14
        manifestPlaceholders["android.support.FILE_PROVIDER_PATHS"] = "filepaths"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Add our custom R8 rules
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    // Configure packaging options to handle conflicts
    packagingOptions {
        resources.excludes.add("META-INF/LICENSE")
        resources.excludes.add("META-INF/NOTICE")
        resources.excludes.add("META-INF/*.kotlin_module")
    }
    
    // Fix for Android 14 compatibility with Play Core
    lint {
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Use Play In-App Update library instead of Play Core (compatible with Android 14)
    implementation("com.google.android.play:app-update-ktx:2.1.0")
    
    // Add missing OkHttp3 logging interceptor
    implementation("com.squareup.okhttp3:logging-interceptor:4.11.0")
}

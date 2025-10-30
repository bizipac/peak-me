import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin must come after Android and Kotlin
    id("com.google.gms.google-services") // Firebase
    id("org.jetbrains.kotlin.plugin.compose") // Jetpack Compose
}

repositories {
    google()
    mavenCentral()
    flatDir { dirs("libs") }
}

android {
    namespace = "com.example.peckme"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.peckme"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // ✅ Kotlin DSL version of signing config
    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            val keyFile = rootProject.file("key.properties")
            if (keyFile.exists()) {
                keyFile.inputStream().use { keyProperties.load(it) }
                storeFile = file(keyProperties["storeFile"]!!)
                storePassword = keyProperties["storePassword"] as String
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    lint {
        abortOnError = false
        disable.add("MissingTranslation")
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    implementation(files("libs/icici.aar"))
    implementation(files("libs/itext5-itextpdf-5.5.12.jar"))

    implementation("androidx.core:core-ktx:1.16.0")
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material:material")
    implementation("androidx.compose.ui:ui-tooling-preview")

    implementation("com.squareup.okhttp3:okhttp:4.9.0")
    implementation("com.squareup.okio:okio:1.17.5")

    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.multidex:multidex:2.0.1")
}

configurations.all {
    resolutionStrategy {
        force("com.squareup.okhttp3:okhttp:4.9.0")
    }
}

flutter {
    source = "../.."
}

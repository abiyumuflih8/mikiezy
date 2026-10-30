plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mikiezy.mikiezy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mikiezy.mikiezy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = "mikiezy"
    }

    flavorDimensions += "default"

    productFlavors {
        create("prod") {
            dimension = "default"
            applicationId = "com.mikiezy.mikiezy"
            manifestPlaceholders["appName"] = "mikiezy"
        }
        create("qa") {
            dimension = "default"
            applicationId = "com.mikiezy.mikiezy.qa"
            manifestPlaceholders["appName"] = "Mikiezy QA"
        }
        create("qaAudit") {
            dimension = "default"
            applicationId = "com.mikiezy.mikiezy.qa.audit"
            manifestPlaceholders["appName"] = "Mikiezy Audit QA"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore (only for playstore builds)
// val keystorePropertiesFile = rootProject.file("key.properties")
// val keystoreProperties = Properties()
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(FileInputStream(keystorePropertiesFile))
// }

android {
    namespace = "com.ansah.shots_studio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ansah.shots_studio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // version 24 for flutter_gemma to work.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "source"
    productFlavors {
        create("fdroid") {
            dimension = "source"
            buildConfigField("String", "BUILD_SOURCE", "\"fdroid\"")
            manifestPlaceholders["appNameSuffix"] = ""
        }
        create("github") {
            dimension = "source"
            buildConfigField("String", "BUILD_SOURCE", "\"github\"")
            manifestPlaceholders["appNameSuffix"] = ""
        }
        create("playstore") {
            dimension = "source"
            buildConfigField("String", "BUILD_SOURCE", "\"playstore\"")
            manifestPlaceholders["appNameSuffix"] = ""
        }
        create("dog") {
            dimension = "source"
            applicationIdSuffix = ".dog"
            buildConfigField("String", "BUILD_SOURCE", "\"github\"")
            manifestPlaceholders["appNameSuffix"] = " (Dog)"
        }
    }

    // signingConfigs {
    //     create("release") {
    //         keyAlias = keystoreProperties["keyAlias"] as String?
    //         keyPassword = keystoreProperties["keyPassword"] as String?
    //         storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
    //         storePassword = keystoreProperties["storePassword"] as String?
    //     }
    // }

    sourceSets {
        getByName("github") {
            manifest.srcFile("src/github/AndroidManifest.xml")
        }
        getByName("fdroid") {
            manifest.srcFile("src/fdroid/AndroidManifest.xml")
        }
        getByName("playstore") {
            manifest.srcFile("src/playstore/AndroidManifest.xml")
        }
        getByName("dog") {
            manifest.srcFile("src/dog/AndroidManifest.xml")
        }
    }

    buildTypes {
        release {
            // Uses debug signing by default (uncomment below for playstore release signing)
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".test"
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    // Configure APK output file names
    applicationVariants.all {
        outputs.all {
            val outputImpl = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            val versionName = defaultConfig.versionName
            val flavorName = productFlavors[0].name
            val buildTypeName = buildType.name
            outputImpl.outputFileName = "shots_studio-${flavorName}-${buildTypeName}-${versionName}.apk"
        }
    }
}

// Fix for F-Droid reproducible builds: disable baseline profiles for F-Droid builds
// This addresses the non-deterministic baseline.prof file issue
// See: https://issuetracker.google.com/issues/231837768
tasks.whenTaskAdded {
    if (name.contains("ArtProfile") && name.contains("Fdroid")) {
        enabled = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

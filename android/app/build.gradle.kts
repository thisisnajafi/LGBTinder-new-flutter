import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Play Store signing: place android/key.properties (gitignored) with store credentials.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists().also { exists ->
    if (exists) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.lgbtfinder"
    // Flutter 3.44 defaults: compileSdk 36, targetSdk 36, minSdk 24, NDK 28.2.13676358
    // minSdk 24 = Android 7.0 (~98% device coverage); Play Store requires targetSdk 35+ (met via 36).
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.lgbtfinder"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Agora full-sdk ships many optional AI/beauty/AV1 extensions (~50MB+).
    val agoraOptionalLibs = listOf(
        "libagora_ai_echo_cancellation_extension.so",
        "libagora_ai_noise_suppression_extension.so",
        "libagora_audio_beauty_extension.so",
        "libagora_clear_vision_extension.so",
        "libagora_content_inspect_extension.so",
        "libagora_face_capture_extension.so",
        "libagora_face_detection_extension.so",
        "libagora_lip_sync_extension.so",
        "libagora_screen_capture_extension.so",
        "libagora_segmentation_extension.so",
        "libagora_spatial_audio_extension.so",
        "libagora_video_av1_decoder_extension.so",
        "libagora_video_av1_encoder_extension.so",
        "libagora_video_decoder_extension.so",
        "libagora_video_encoder_extension.so",
        "libagora_video_quality_analyzer_extension.so",
        "libagora-ffmpeg.so",
    )
    val abis = listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
    packaging {
        jniLibs {
            agoraOptionalLibs.flatMap { lib -> abis.map { abi -> "lib/$abi/$lib" } }
                .forEach { excludes += it }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")

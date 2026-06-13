plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lgbtfinder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        // Don't treat Kotlin warnings from dependencies as errors (see docs/ANDROID_BUILD_WARNINGS.md)
        allWarningsAsErrors = false
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.lgbtfinder"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Agora full-sdk ships many optional AI/beauty/AV1 extensions (~50MB+).
    // Basic 1:1 voice/video calls only need the core RTC libraries.
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
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.moviepilot_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // media3-ffmpeg-decoder 引用了需要脱糖的 JDK API，不开会在 D8 阶段报错
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.moviepilot_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val jpushPackageName = applicationId ?: "com.example.moviepilot_mobile"
        manifestPlaceholders.putAll(
            mapOf(
                "JPUSH_PKGNAME" to jpushPackageName,
                "JPUSH_APPKEY" to "e462379fa18ab59e31fd7ac2",
                "JPUSH_CHANNEL" to "developer-default",
            ),
        )
    }

    signingConfigs {
        val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
        val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
        val keyAlias = System.getenv("KEY_ALIAS")
        val keyPassword = System.getenv("KEY_PASSWORD")
        if (keystorePath != null && keystorePassword != null && keyAlias != null && keyPassword != null) {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = keystorePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            }
        }
    }

    buildTypes {
        // 调试包使用独立应用 ID,与正式签名包共存(避免签名冲突与卸载丢数据)
        getByName("debug") {
            applicationIdSuffix = ".debug"
        }
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }

    // 内嵌播放器(lanplayer_player)原生构建:libass JNI + ISO 原盘直连(libudfread)
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    // media_kit AAR 内置裁剪版 libmpv;与自带全量 libmpv.so 重名时让 app 模块优先
    packaging {
        jniLibs {
            pickFirsts += "**/libmpv.so"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    // ── 内嵌播放器(lanplayer_player)Exo+FFmpeg 双内核原生依赖 ──
    implementation("androidx.media3:media3-exoplayer:1.8.0")
    implementation("androidx.media3:media3-exoplayer-hls:1.8.0")
    implementation("androidx.media3:media3-exoplayer-dash:1.8.0")
    implementation("androidx.media3:media3-ui:1.8.0")
    implementation("androidx.media3:media3-datasource-okhttp:1.8.0")
    // FFmpeg 音频软解扩展（jellyfin 预编译，GPL-3.0）：TrueHD/DTS-HD 等平台
    // MediaCodec 不支持的音频格式兜底。保留 androidx 原包名
    // （androidx.media3.decoder.ffmpeg.FfmpegAudioRenderer），DefaultRenderersFactory
    // 的扩展发现机制可直接识别。版本与 media3 主库对齐（1.8.0+1 构建）。
    implementation("org.jellyfin.media3:media3-ffmpeg-decoder:1.8.0+1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

/**
 * lanplayer_jni.cpp — LAN Player 原生 JNI 桥接
 *
 * 提供以下原生功能：
 * 1. libass ASS/SSA 字幕渲染（当编译时启用 HAS_LIBASS）
 * 2. 系统信息检测（HDR 能力、GPU 信息等）
 *
 * 通过 JNI 与 Dart 层 MethodChannel 通信。
 */

#include <jni.h>
#include <android/log.h>
#include <cstring>
#include <string>

#define LOG_TAG "LanPlayerJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#if HAS_LIBASS
#include <ass/ass.h>

// ===== libass 渲染器管理 =====

static ASS_Library* g_assLibrary = nullptr;
static ASS_Renderer* g_assRenderer = nullptr;
static ASS_Track* g_assTrack = nullptr;

// ── 字幕样式覆盖（用户设置 → libass selective style override）──
// 只开 ASS_OVERRIDE_BIT_STYLE：字体名/字号/颜色/描边/属性。**不含**定位
// (ALIGNMENT) 与边距 (MARGINS)，所以特效字幕的 \pos/\move/\k/	 完全不受影响。
// 为什么需要：普通字幕(SRT/VTT)原先不走 libass，Exo 侧用 0.06×缩放的基准，
// 缩放到 0.5 就只剩 3% 视频高度（真机实证：外挂明显小于内封）；libass 默认
// 18px@PlayRes288 = 6.25%，与 mpv 一致。
static ASS_Style g_overrideStyle;
static int g_overrideEnabled = 0;
static bool g_overrideReady = false;

/// 把存下来的样式应用到当前渲染器（nativeInit 重建渲染器后也要重放）
static void apply_style_override() {
    if (!g_assRenderer || !g_overrideReady) return;
    ass_set_selective_style_override(g_assRenderer, &g_overrideStyle);
    ass_set_selective_style_override_enabled(
        g_assRenderer, g_overrideEnabled ? ASS_OVERRIDE_BIT_STYLE : 0);
    LOGI("libass style override: enabled=%d fontSize=%.1f font=%s",
         g_overrideEnabled, g_overrideStyle.FontSize,
         g_overrideStyle.FontName ? g_overrideStyle.FontName : "-");
}

extern "C" JNIEXPORT void JNICALL
Java_com_lanplayer_LibassBridge_nativeSetStyle(JNIEnv* env, jclass clazz,
                                               jint fontSize, jstring fontName,
                                               jint primaryColour, jint outlineColour,
                                               jint backColour, jint bold,
                                               jdouble outline, jdouble shadow,
                                               jint enabled) {
    memset(&g_overrideStyle, 0, sizeof(g_overrideStyle));
    g_overrideStyle.Name = (char*)"LANPlayer";
    g_overrideStyle.FontName = fontName ? (char*)env->GetStringUTFChars(fontName, nullptr)
                                        : (char*)"Arial";
    if (!g_overrideStyle.FontName) g_overrideStyle.FontName = (char*)"Arial";
    g_overrideStyle.FontSize = fontSize > 0 ? (double)fontSize : 18.0;
    g_overrideStyle.PrimaryColour = (uint32_t)primaryColour;
    g_overrideStyle.SecondaryColour = (uint32_t)primaryColour;
    g_overrideStyle.OutlineColour = (uint32_t)outlineColour;
    g_overrideStyle.BackColour = (uint32_t)backColour;
    g_overrideStyle.Bold = bold ? 1 : 0;
    g_overrideStyle.ScaleX = 1.0;
    g_overrideStyle.ScaleY = 1.0;
    g_overrideStyle.BorderStyle = 1;
    g_overrideStyle.Outline = outline;
    g_overrideStyle.Shadow = shadow;
    g_overrideStyle.Encoding = 0;
    g_overrideEnabled = enabled ? 1 : 0;
    g_overrideReady = true;
    apply_style_override();
}

/**
 * 初始化 libass 渲染器
 */
extern "C" JNIEXPORT jboolean JNICALL
Java_com_lanplayer_LibassBridge_nativeInit(JNIEnv* env, jclass clazz,
                                            jint frameWidth, jint frameHeight) {
    if (g_assLibrary) {
        LOGI("libass already initialized, reinitializing...");
        if (g_assTrack) { ass_free_track(g_assTrack); g_assTrack = nullptr; }
        if (g_assRenderer) { ass_renderer_done(g_assRenderer); g_assRenderer = nullptr; }
        ass_library_done(g_assLibrary);
    }

    g_assLibrary = ass_library_init();
    if (!g_assLibrary) {
        LOGE("ass_library_init failed");
        return JNI_FALSE;
    }

    // 启用字体目录搜索
    ass_set_fonts_dir(g_assLibrary, "/system/fonts");

    g_assRenderer = ass_renderer_init(g_assLibrary);
    if (!g_assRenderer) {
        LOGE("ass_renderer_init failed");
        ass_library_done(g_assLibrary);
        g_assLibrary = nullptr;
        return JNI_FALSE;
    }

    // 配置渲染器
    ass_set_frame_size(g_assRenderer, frameWidth, frameHeight);
    ass_set_storage_size(g_assRenderer, frameWidth, frameHeight);
    ass_set_fonts(g_assRenderer, "/system/fonts/NotoSansCJK-Regular.ttc",
                  "sans-serif", ASS_FONTPROVIDER_AUTODETECT, nullptr, 1);
    ass_set_hinting(g_assRenderer, ASS_HINTING_LIGHT);
    ass_set_use_margins(g_assRenderer, 0);
    // 渲染器重建后重放样式覆盖（用户在播放前就改过样式的情况）
    apply_style_override();

    LOGI("libass initialized: %dx%d", frameWidth, frameHeight);
    return JNI_TRUE;
}

/**
 * 加载 ASS/SSA 字幕文件
 */
extern "C" JNIEXPORT jboolean JNICALL
Java_com_lanplayer_LibassBridge_nativeLoadFile(JNIEnv* env, jclass clazz,
                                                jstring filePath) {
    if (!g_assLibrary) {
        LOGE("libass not initialized");
        return JNI_FALSE;
    }

    const char* path = env->GetStringUTFChars(filePath, nullptr);
    if (!path) return JNI_FALSE;

    if (g_assTrack) {
        ass_free_track(g_assTrack);
        g_assTrack = nullptr;
    }

    g_assTrack = ass_read_file(g_assLibrary, const_cast<char*>(path), nullptr);
    env->ReleaseStringUTFChars(filePath, path);

    if (!g_assTrack) {
        LOGE("ass_read_file failed");
        return JNI_FALSE;
    }

    LOGI("ASS track loaded: %d events, %d styles",
         g_assTrack->n_events, g_assTrack->n_styles);
    return JNI_TRUE;
}

/**
 * 从内存加载 ASS 字幕数据
 */
extern "C" JNIEXPORT jboolean JNICALL
Java_com_lanplayer_LibassBridge_nativeLoadData(JNIEnv* env, jclass clazz,
                                                jbyteArray data) {
    if (!g_assLibrary) return JNI_FALSE;

    jsize len = env->GetArrayLength(data);
    jbyte* bytes = env->GetByteArrayElements(data, nullptr);
    if (!bytes) return JNI_FALSE;

    if (g_assTrack) {
        ass_free_track(g_assTrack);
        g_assTrack = nullptr;
    }

    g_assTrack = ass_read_memory(g_assLibrary,
                                  reinterpret_cast<char*>(bytes),
                                  static_cast<size_t>(len), nullptr);
    env->ReleaseByteArrayElements(data, bytes, JNI_ABORT);

    if (!g_assTrack) {
        LOGE("ass_read_memory failed");
        return JNI_FALSE;
    }

    LOGI("ASS track loaded from memory: %d events", g_assTrack->n_events);
    return JNI_TRUE;
}

/**
 * 渲染指定时间点的字幕帧（返回 ARGB 像素数据）
 */
extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_lanplayer_LibassBridge_nativeRender(JNIEnv* env, jclass clazz,
                                              jlong timeMs,
                                              jint width, jint height) {
    if (!g_assRenderer || !g_assTrack) return nullptr;

    ass_set_frame_size(g_assRenderer, width, height);

    int detectChange = 0;
    ASS_Image* img = ass_render_frame(g_assRenderer, g_assTrack,
                                       static_cast<long long>(timeMs),
                                       &detectChange);
    if (!img) return nullptr;

    // 分配 ARGB 缓冲区
    size_t bufSize = static_cast<size_t>(width) * height * 4;
    auto* buffer = new uint8_t[bufSize];
    memset(buffer, 0, bufSize);

    // 将 ASS_Image 链表渲染到缓冲区
    for (ASS_Image* i = img; i; i = i->next) {
        for (int y = 0; y < i->h; y++) {
            for (int x = 0; x < i->w; x++) {
                int px = i->dst_x + x;
                int py = i->dst_y + y;
                if (px >= width || py >= height) continue;

                uint8_t alpha = i->bitmap[y * i->stride + x];
                if (alpha == 0) continue;

                // ASS 颜色: 0xRRGGBBAA (big-endian)
                uint32_t color = i->color;
                uint8_t r = (color >> 24) & 0xFF;
                uint8_t g = (color >> 16) & 0xFF;
                uint8_t b = (color >> 8) & 0xFF;
                uint8_t a = alpha; // 忽略 ASS 的 alpha 通道，用 bitmap alpha

                size_t offset = (py * width + px) * 4;
                // Alpha 混合
                float srcA = a / 255.0f;
                float dstA = buffer[offset + 3] / 255.0f;
                float outA = srcA + dstA * (1.0f - srcA);

                buffer[offset + 0] = static_cast<uint8_t>((r * srcA + buffer[offset + 0] * dstA * (1.0f - srcA)) / outA);
                buffer[offset + 1] = static_cast<uint8_t>((g * srcA + buffer[offset + 1] * dstA * (1.0f - srcA)) / outA);
                buffer[offset + 2] = static_cast<uint8_t>((b * srcA + buffer[offset + 2] * dstA * (1.0f - srcA)) / outA);
                buffer[offset + 3] = static_cast<uint8_t>(outA * 255.0f);
            }
        }
    }

    jbyteArray result = env->NewByteArray(static_cast<jsize>(bufSize));
    env->SetByteArrayRegion(result, 0, static_cast<jsize>(bufSize),
                            reinterpret_cast<jbyte*>(buffer));
    delete[] buffer;
    return result;
}

/**
 * 释放 libass 资源
 */
extern "C" JNIEXPORT void JNICALL
Java_com_lanplayer_LibassBridge_nativeRelease(JNIEnv* env, jclass clazz) {
    if (g_assTrack) { ass_free_track(g_assTrack); g_assTrack = nullptr; }
    if (g_assRenderer) { ass_renderer_done(g_assRenderer); g_assRenderer = nullptr; }
    if (g_assLibrary) { ass_library_done(g_assLibrary); g_assLibrary = nullptr; }
    LOGI("libass released");
}

/**
 * 获取字幕事件总数
 */
extern "C" JNIEXPORT jint JNICALL
Java_com_lanplayer_LibassBridge_nativeGetEventCount(JNIEnv* env, jclass clazz) {
    return g_assTrack ? g_assTrack->n_events : 0;
}

#else
// ===== libass 未编译时的桩实现 =====

extern "C" JNIEXPORT jboolean JNICALL
Java_com_lanplayer_LibassBridge_nativeInit(JNIEnv*, jclass, jint, jint) {
    return JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_lanplayer_LibassBridge_nativeLoadFile(JNIEnv*, jclass, jstring) {
    return JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_lanplayer_LibassBridge_nativeLoadData(JNIEnv*, jclass, jbyteArray) {
    return JNI_FALSE;
}

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_lanplayer_LibassBridge_nativeRender(JNIEnv*, jclass, jlong, jint, jint) {
    return nullptr;
}

extern "C" JNIEXPORT void JNICALL
Java_com_lanplayer_LibassBridge_nativeRelease(JNIEnv*, jclass) {}

extern "C" JNIEXPORT jint JNICALL
Java_com_lanplayer_LibassBridge_nativeGetEventCount(JNIEnv*, jclass) {
    return 0;
}

#endif // HAS_LIBASS

// ===== 系统信息检测 =====

/**
 * 检测系统 HDR 显示能力
 */
extern "C" JNIEXPORT jboolean JNICALL
Java_com_lanplayer_LanPlayerJNI_nativeIsHdrDisplayAvailable(JNIEnv* env, jclass clazz) {
    // 需要 Android 8.0+ (API 26) 的 Display.HdrCapabilities
    // 通过 Java 层检测更可靠，此处返回 false 作为默认
    return JNI_FALSE;
}

/**
 * 获取 GPU 渲染器名称
 */
extern "C" JNIEXPORT jstring JNICALL
Java_com_lanplayer_LanPlayerJNI_nativeGetGpuRenderer(JNIEnv* env, jclass clazz) {
    // 需要通过 EGL 上下文获取，暂返回空
    return env->NewStringUTF("unknown");
}

package com.lanplayer

import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * libass JNI 桥接 Flutter 插件
 *
 * 通过 MethodChannel 将 Dart 层的 libass 调用转发到 C++ JNI 层。
 * 当 libass 未编译时（HAS_LIBASS=0），所有操作返回 false/null。
 */
class LibassPlugin: FlutterPlugin {
    companion object {
        private const val CHANNEL = "com.lanplayer/libass"

        init {
            try {
                System.loadLibrary("lanplayer_jni")
            } catch (e: UnsatisfiedLinkError) {
                // lanplayer_jni 库不存在（未启用 CMake 构建）
            }
        }
    }

    private var methodChannel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "init" -> {
                        val width = call.argument<Int>("width") ?: 1920
                        val height = call.argument<Int>("height") ?: 1080
                        result.success(LibassBridge.nativeInit(width, height))
                    }
                    "loadFile" -> {
                        val path = call.argument<String>("path") ?: ""
                        result.success(LibassBridge.nativeLoadFile(path))
                    }
                    "loadData" -> {
                        val data = call.argument<ByteArray>("data")
                        result.success(if (data != null) LibassBridge.nativeLoadData(data) else false)
                    }
                    "render" -> {
                        val timeMs = call.argument<Long>("timeMs") ?: 0L
                        val width = call.argument<Int>("width") ?: 1920
                        val height = call.argument<Int>("height") ?: 1080
                        result.success(LibassBridge.nativeRender(timeMs, width, height))
                    }
                    "setStyle" -> {
                        // 只覆盖字体名/字号/颜色/描边/属性（不含定位与边距）
                        LibassBridge.nativeSetStyle(
                            (call.argument<Number>("fontSize") ?: 18).toInt(),
                            call.argument<String>("fontName") ?: "Arial",
                            (call.argument<Number>("primaryColour") ?: -1).toInt(),
                            (call.argument<Number>("outlineColour") ?: 0).toInt(),
                            (call.argument<Number>("backColour") ?: 0).toInt(),
                            (call.argument<Number>("bold") ?: 0).toInt(),
                            (call.argument<Number>("outline") ?: 0.0).toDouble(),
                            (call.argument<Number>("shadow") ?: 0.0).toDouble(),
                            (call.argument<Number>("enabled") ?: 1).toInt(),
                        )
                        result.success(null)
                    }
                    "getEventCount" -> {
                        result.success(LibassBridge.nativeGetEventCount())
                    }
                    "release" -> {
                        LibassBridge.nativeRelease()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        LibassBridge.nativeRelease()
    }
}

/**
 * libass JNI 方法声明
 */
object LibassBridge {
    @JvmStatic external fun nativeInit(width: Int, height: Int): Boolean
    @JvmStatic external fun nativeLoadFile(filePath: String): Boolean
    @JvmStatic external fun nativeLoadData(data: ByteArray): Boolean
    @JvmStatic external fun nativeRender(timeMs: Long, width: Int, height: Int): ByteArray?
    @JvmStatic external fun nativeRelease()
    @JvmStatic external fun nativeGetEventCount(): Int
    @JvmStatic external fun nativeSetStyle(
        fontSize: Int, fontName: String,
        primaryColour: Int, outlineColour: Int, backColour: Int, bold: Int,
        outline: Double, shadow: Double, enabled: Int,
    )
}

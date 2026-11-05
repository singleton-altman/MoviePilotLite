package com.lanplayer

import android.os.Build
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * ISO 原盘(BDMV ISO)原生直连插件。
 *
 * 通过 MethodChannel 调用 lanplayer_jni 的 libudfread 管线:
 * 解析远端 ISO 的 UDF 文件系统 → 定位 BDMV/STREAM 正片 m2ts
 * → 本地 127.0.0.1 服务以 Range 流暴露给播放内核。
 *
 * 线程注记:openIso 是**重活**（远端 Range 读 + UDF 解析 + 扫每个 m2ts 取大小，
 * 真机实证 139 片段的原盘要十几秒），因此放在独立单线程执行器里执行、结果回
 * 主线程回包。此前它在 MethodChannel 的主线程上同步跑 → 真机 ANR
 * （Input dispatching timed out 10s+，播放界面都出不来）。
 */
class IsoPlugin : FlutterPlugin {
    companion object {
        private const val CHANNEL = "com.lanplayer/iso"
        private const val TAG = "IsoPlugin"

        init {
            try {
                System.loadLibrary("lanplayer_jni")
            } catch (e: UnsatisfiedLinkError) {
                // lanplayer_jni 不存在(未启用 CMake 构建)
            }
        }
    }

    private var channel: MethodChannel? = null

    /** 单线程：开 ISO 串行执行，避免与 closeIso 打架 */
    private val worker = java.util.concurrent.Executors.newSingleThreadExecutor { r ->
        Thread(r, "iso-open")
    }
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "openIso" -> {
                        val url = call.argument<String>("url") ?: ""
                        val size = (call.argument<Number>("size") as? Number)?.toLong() ?: 0L
                        android.util.Log.i(TAG,
                            "openIso 收到（线程=${Thread.currentThread().name}）→ 转后台执行")
                        val t0 = android.os.SystemClock.elapsedRealtime()
                        worker.execute {
                            val local = try {
                                IsoBridge.nativeOpenIso(url, size)
                            } catch (t: Throwable) {
                                android.util.Log.e(TAG, "openIso 异常: $t")
                                null
                            }
                            android.util.Log.i(TAG,
                                "openIso 完成: ${local ?: "失败"} 用时 " +
                                    "${android.os.SystemClock.elapsedRealtime() - t0}ms")
                            // MethodChannel 的回包要在主线程发
                            mainHandler.post { result.success(local) }
                        }
                    }
                    "closeIso" -> {
                        IsoBridge.nativeCloseIso()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        worker.shutdown() // 已提交的开 ISO 任务仍会跑完，之后不再接新任务
    }
}

/** JNI 桥(lanplayer_jni 内实现,ISO 原生直连)。 */
object IsoBridge {
    init {
        try {
            System.loadLibrary("lanplayer_jni")
        } catch (e: UnsatisfiedLinkError) {
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            // 理论不可达(minSdk 24),防御性标注
        }
    }

    /** 打开 ISO 原盘并启动本地流服务;返回 127.0.0.1 播放地址,null=失败 */
    external fun nativeOpenIso(url: String, sizeBytes: Long): String?

    /** 释放原生直连资源 */
    external fun nativeCloseIso()
}

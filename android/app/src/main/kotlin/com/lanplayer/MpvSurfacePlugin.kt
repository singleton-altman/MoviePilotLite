package com.lanplayer

import android.content.Context
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 定制 libmpv 原生引擎承载层。
 *
 * 架构（对照 Streama 的验证形态）：
 *   mpv(libmpv.so, 静态编入 libass+ffmpeg)
 *     vo=gpu-next + gpu-context=android → SurfaceView
 *     hwdec=mediacodec（直连硬解）/ mediacodec-copy（兼容回退）
 *   字幕走自研 LibassBridge（独立叠加层，特效完整）
 *   视频帧不经过 Flutter 纹理管线 —— TV 弹幕卡顿的根治路径。
 *
 * JNI 层见 cpp/lanplayer_mpv.cpp（HAS_MPV 编译开关）。
 */
object MpvNative {
    // JNI 桥编译进 liblanplayer_jni.so(CMake 同目标),非独立库;
    // 加载失败置 available=false,调用方回退其他内核而非闪退
    var available = false
        private set

    init {
        available = try {
            System.loadLibrary("lanplayer_jni")
            true
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.e("LanMpv", "native core load failed: $e")
            false
        }
    }

    /** 创建 mpv 核心并绑定 Surface。surface 来自 SurfaceView。 */
    external fun nativeCreate(surface: Surface): Long
    /** 销毁核心（释放 Surface 前必须调用）。返回前保证 mpv 完全退出。 */
    external fun nativeDestroy(handle: Long)
    /** 运行期重新挂载 Surface（Surface 重建后恢复渲染，官方 attachSurface 契约）。 */
    external fun nativeAttachSurface(handle: Long, surface: Surface): Boolean
    /** 交还 Surface：wid=0 并释放全局引用（必须在 Surface 失效前调用）。 */
    external fun nativeDetachSurface(handle: Long)
    /** 发送命令（loadfile/seek/set ...)。 */
    external fun nativeCommand(handle: Long, cmd: String): Boolean
    /** 设置属性（字符串值）。 */
    external fun nativeSetProperty(handle: Long, name: String, value: String): Boolean
    /** 读取属性。 */
    external fun nativeGetProperty(handle: Long, name: String): String?
    /** 观测属性变化（position/duration/idle 等），回调经 onEvent 回 Flutter。 */
    external fun nativeObserve(handle: Long, name: String, id: Int): Boolean
    /** 设置事件回调宿主（Dart 侧经 MethodChannel 转发）。 */
    external fun nativeSetEventCallback(handle: Long, callback: Any)
    /** 文件加载后调用：把当前轨道/时长等状态一次性吐回。 */
    external fun nativeSetWakeupCallback(handle: Long, callback: Any)
}

/**
 * PlatformView：提供视频 Surface + 生命周期管理。
 * Dart 侧用 AndroidView(viewType: 'lanplayer/mpv_surface') 嵌入。
 */
class MpvSurfacePlatformView(
    private val context: Context,
    private val channel: MethodChannel,
) : io.flutter.plugin.platform.PlatformView {
    private val surfaceView: SurfaceView = SurfaceView(context)
    private var mpvHandle: Long = 0
    private val pendingCommands = mutableListOf<(Surface) -> Unit>()
    private var surfaceReady = false

    private val holderCallback = object : SurfaceHolder.Callback {
        override fun surfaceCreated(holder: SurfaceHolder) {
            // 先记下「进这个回调前是否已有 handle」：首次创建的 handle 由下面
            // 排队的 create 流程直接绑定，不该再重挂一次（多余 VO 重配会闪）。
            val hadHandle = mpvHandle != 0L
            surfaceReady = true
            // Surface 就绪：执行排队中的创建/命令
            pendingCommands.forEach { it(holder.surface) }
            pendingCommands.clear()
            // Surface 被系统重建（切后台再回来、视图重建）：重新挂载并恢复
            // VO —— 否则画面随旧 Surface 一起消失（官方 attachSurface 契约）。
            if (hadHandle && mpvHandle != 0L) {
                MpvNative.nativeAttachSurface(mpvHandle, holder.surface)
                MpvNative.nativeSetProperty(mpvHandle, "vo", "gpu-next")
            }
        }

        override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            // ⚠️ mpv 感知 Surface 尺寸的**唯一**入口（mpv-android 官方同款）：
            // android-surface-size 触发 VO 重配（android_reconfig →
            // setBuffersGeometry + swapchain resize）。不设它，画布尺寸一变
            // （画幅校正把画布从 16:9 改成 2.39:1）mpv 仍按旧几何渲染 ——
            // 画幅怎么调都不对（真机实证，build 2030 日志可见 dwidth 已对
            // 但画面比例仍错）。此前这里发的是 video-aspect-override no，无效。
            if (mpvHandle != 0L) {
                android.util.Log.i("LanMpv", "surfaceChanged ${width}x$height → android-surface-size")
                MpvNative.nativeSetProperty(mpvHandle, "android-surface-size", "${width}x$height")
            }
        }

        override fun surfaceDestroyed(holder: SurfaceHolder) {
            surfaceReady = false
            // Surface 即将销毁：先关 VO 再交还窗口（官方时序）。
            // 不能用 stop —— 那会把播放整个停掉，切后台再回来就废了。
            if (mpvHandle != 0L) {
                MpvNative.nativeSetProperty(mpvHandle, "vo", "null")
                MpvNative.nativeDetachSurface(mpvHandle)
            }
        }
    }

    init {
        surfaceView.holder.addCallback(holderCallback)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "create" -> {
                    if (!MpvNative.available) {
                        result.error("native_unavailable", "libmpv 定制内核加载失败", null)
                        return@setMethodCallHandler
                    }
                    val args = call.arguments as Map<*, *>
                    val url = args["url"] as String
                    val hwdec = args["hwdec"] as? String ?: "mediacodec"
                    runWhenSurface { surface ->
                        mpvHandle = MpvNative.nativeCreate(surface)
                        MpvNative.nativeSetProperty(mpvHandle, "hwdec", hwdec)
                        MpvNative.nativeSetProperty(mpvHandle, "vo", "gpu-next")
                        MpvNative.nativeSetProperty(mpvHandle, "gpu-context", "android")
                        MpvNative.nativeSetProperty(mpvHandle, "osc", "no")
                        // 字幕由 mpv 内置 libass 渲染到 Surface（sub-visibility 默认
                        // 即为显示），外挂轨走 sub-add，样式走 sub-* 选项
                        // 首帧几何：surfaceChanged 可能早于 create 到达（那时还没有
                        // handle，属性无处可设），这里补一次当前视图尺寸，避免首帧
                        // 按 mpv 自己探测到的旧几何渲染。
                        if (surfaceView.width > 0 && surfaceView.height > 0) {
                            android.util.Log.i("LanMpv",
                                "initial surface size ${surfaceView.width}x${surfaceView.height}")
                            MpvNative.nativeSetProperty(mpvHandle, "android-surface-size",
                                "${surfaceView.width}x${surfaceView.height}")
                        }
                        // 字幕字体目录（LibassBridge 已有的字体拷贝逻辑复用）
                        val fontsDir = File(context.filesDir, "fonts").apply { mkdirs() }
                        MpvNative.nativeSetProperty(mpvHandle, "sub-fonts-dir", fontsDir.absolutePath)
                        MpvNative.nativeCommand(mpvHandle, "loadfile \"$url\" replace")
                        result.success(mpvHandle != 0L)
                    }
                }
                "command" -> {
                    val cmd = call.arguments as String
                    result.success(if (mpvHandle != 0L) MpvNative.nativeCommand(mpvHandle, cmd) else false)
                }
                "setProperty" -> {
                    val a = call.arguments as Map<*, *>
                    result.success(if (mpvHandle != 0L)
                        MpvNative.nativeSetProperty(mpvHandle, a["name"] as String, a["value"] as String)
                    else false)
                }
                // mpv track-list（原样 JSON 字符串）：字段归一与位图判定在 Dart 侧
                // （MpvTrackList.parse，可单测），这里只做搬运。
                "getTracks" -> {
                    val h = mpvHandle
                    result.success(if (h == 0L) null else MpvNative.nativeGetProperty(h, "track-list"))
                }
                "getProperty" -> {
                    val name = call.arguments as String
                    result.success(if (mpvHandle != 0L) MpvNative.nativeGetProperty(mpvHandle, name) else null)
                }
                // 一次回传播放状态：Dart 侧 500ms 轮询用它驱动进度条/画幅/下一集
                // 倒计时。原样给 mpv 属性字符串，单位换算(秒→毫秒)与 yes/no 约定
                // 全在 Dart 侧(NativeSurfaceSnapshot)——那部分有单测覆盖。
                "getPlaybackState" -> {
                    val h = mpvHandle
                    result.success(if (h == 0L) null else mapOf(
                        "timePos" to MpvNative.nativeGetProperty(h, "time-pos"),
                        "duration" to MpvNative.nativeGetProperty(h, "duration"),
                        "paused" to MpvNative.nativeGetProperty(h, "pause"),
                        // dwidth/dheight = 显示尺寸(含 PAR 与旋转) → 画布宽高比
                        "dwidth" to MpvNative.nativeGetProperty(h, "dwidth"),
                        "dheight" to MpvNative.nativeGetProperty(h, "dheight"),
                        // volume：宿主每个状态帧都会用 state.volume 覆盖界面音量，
                        // 不回读就会把用户设的音量打回默认值
                        "volume" to MpvNative.nativeGetProperty(h, "volume"),
                        // speed：同理，不回读会把倍速打回 1.0x
                        "speed" to MpvNative.nativeGetProperty(h, "speed"),
                        // 丢帧统计：排查"卡在哪一环"用（解码器丢帧/时基不匹配/渲染延迟）
                        "dropFrameCount" to MpvNative.nativeGetProperty(h, "frame-drop-count"),
                        "mistimedFrameCount" to MpvNative.nativeGetProperty(h, "mistimed-frame-count"),
                        "delayedFrameCount" to MpvNative.nativeGetProperty(h, "vo-delayed-frame-count"),
                        // 已缓冲到的绝对位置（秒）→ 进度条的缓冲区间
                        "cacheTime" to MpvNative.nativeGetProperty(h, "demuxer-cache-time"),
                    ))
                }
                "destroy" -> {
                    if (mpvHandle != 0L) {
                        MpvNative.nativeDestroy(mpvHandle)
                        mpvHandle = 0L
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private inline fun runWhenSurface(crossinline block: (Surface) -> Unit) {
        if (surfaceReady) {
            surfaceView.holder.surface?.let { block(it) }
        } else {
            pendingCommands.add { block(it) }
        }
    }

    override fun getView(): android.view.View = surfaceView

    override fun dispose() {
        if (mpvHandle != 0L) {
            MpvNative.nativeDestroy(mpvHandle)
            mpvHandle = 0L
        }
    }
}

class MpvSurfacePlatformViewFactory(
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
) : io.flutter.plugin.platform.PlatformViewFactory(io.flutter.plugin.common.StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): io.flutter.plugin.platform.PlatformView {
        return MpvSurfacePlatformView(
            context,
            MethodChannel(messenger, "lanplayer/mpv_surface_$viewId"),
        )
    }
}

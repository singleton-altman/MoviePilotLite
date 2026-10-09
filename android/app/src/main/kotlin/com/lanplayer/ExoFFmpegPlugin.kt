package com.lanplayer

import android.content.Context
import android.graphics.SurfaceTexture
import android.view.Surface
import android.view.TextureView
import android.widget.FrameLayout
import androidx.media3.ui.SubtitleView
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * ExoPlayer + FFmpeg 音频软解 Flutter 插件
 *
 * 通过 MethodChannel 桥接 Dart 层与 Android 原生 ExoPlayer。
 * 使用 TextureView 渲染视频输出（兼容 Flutter Virtual Display 模式）。
 *
 * 架构：
 * - Dart 层：ExoFFmpegEngine (lib/player/exo/exo_ffmpeg_engine.dart)
 * - 原生层：ExoFFmpegPlugin (本文件) + ExoFFmpegPlayer
 * - 通信：MethodChannel("com.lanplayer/exo_ffmpeg")
 * - 渲染：PlatformView + TextureView（Virtual Display 兼容）
 */
class ExoFFmpegPlugin: FlutterPlugin {
    companion object {
        private const val CHANNEL = "com.lanplayer/exo_ffmpeg"
        private const val STATE_CHANNEL = "com.lanplayer/exo_ffmpeg_state"
        private const val VIEW_TYPE = "com.lanplayer/exo_ffmpeg_view"
    }

    private var player: ExoFFmpegPlayer? = null
    private var methodChannel: MethodChannel? = null
    private var stateChannel: EventChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext

        player = ExoFFmpegPlayer(context)

        binding.flutterEngine.platformViewsController.registry.registerViewFactory(
            VIEW_TYPE,
            ExoFFmpegViewFactory(context, player!!)
        )

        // 状态推送：ExoPlayer 事件触发时把最新状态快照推给 Dart 层
        // （替代 Dart 侧 200ms 轮询 getState，进度/缓冲更跟手且省电）
        stateChannel = EventChannel(binding.binaryMessenger, STATE_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    player?.onStateUpdate = { state ->
                        events?.success(state)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    player?.onStateUpdate = null
                }
            })
        }

        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isFFmpegAvailable" -> {
                        result.success(player?.isFFmpegAvailable() ?: false)
                    }
                    "getSupportedCodecs" -> {
                        result.success(player?.getSupportedCodecs() ?: emptyList<String>())
                    }
                    "open" -> {
                        val url = call.argument<String>("url") ?: ""
                        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
                        val autoPlay = call.argument<Boolean>("autoPlay") ?: true
                        val enableFFmpeg = call.argument<Boolean>("enableFFmpeg") ?: false
                        val state = player?.open(url, headers, autoPlay, enableFFmpeg)
                        if (state != null) {
                            result.success(mapOf(
                                "textureId" to state.textureId,
                                "durationMs" to state.durationMs,
                                "isPlaying" to state.isPlaying,
                                "isHdr" to state.isHdr,
                                "videoWidth" to state.videoWidth,
                                "videoHeight" to state.videoHeight
                            ))
                        } else {
                            result.error("OPEN_FAILED", "Failed to open media", null)
                        }
                    }
                    "play" -> { player?.play(); result.success(null) }
                    "pause" -> { player?.pause(); result.success(null) }
                    "seekTo" -> {
                        val pos = call.argument<Int>("positionMs") ?: 0
                        player?.seekTo(pos.toLong())
                        result.success(null)
                    }
                    "setSpeed" -> {
                        val speed = call.argument<Double>("speed") ?: 1.0
                        player?.setSpeed(speed.toFloat())
                        result.success(null)
                    }
                    "setVolume" -> {
                        val volume = call.argument<Double>("volume") ?: 1.0
                        player?.setVolume(volume.toFloat())
                        result.success(null)
                    }
                    "stop" -> { player?.stop(); result.success(null) }
                    "dispose" -> { player?.release(); result.success(null) }
                    "getState" -> {
                        val state = player?.getState()
                        if (state != null) {
                            result.success(mapOf(
                                "isPlaying" to state.isPlaying,
                                "isBuffering" to state.isBuffering,
                                "positionMs" to state.positionMs,
                                "durationMs" to state.durationMs,
                                "bufferedMs" to state.bufferedMs,
                                "speed" to state.speed,
                                "volume" to state.volume,
                                "isHdr" to state.isHdr,
                                "videoWidth" to state.videoWidth,
                                "videoHeight" to state.videoHeight,
                                "error" to state.error
                            ))
                        } else {
                            result.success(null)
                        }
                    }
                    "getAudioTracks" -> {
                        result.success(player?.getAudioTracks() ?: emptyList<Map<String, Any>>())
                    }
                    "getSubtitleTracks" -> {
                        result.success(player?.getSubtitleTracks() ?: emptyList<Map<String, Any>>())
                    }
                    "setAudioTrack" -> {
                        val index = call.argument<Int>("index") ?: 0
                        player?.setAudioTrack(index)
                        result.success(null)
                    }
                    "setSubtitleTrack" -> {
                        val index = call.argument<Int>("index") ?: 0
                        player?.setSubtitleTrack(index)
                        result.success(null)
                    }
                    "captureFrame" -> {
                        result.success(player?.captureFrame())
                    }
                    "setSubtitleStyle" -> {
                        // Dart int 是 64 位：带 alpha 的 ARGB 颜色（> Int.MAX_VALUE）经
                        // StandardMessageCodec 装箱为 java.lang.Long，argument<Int> 的
                        // 强转会直接抛 ClassCastException（字幕样式因此从未生效过）。
                        // 统一按 Number 收下再转 Int，Integer/Long 两种装箱都兼容。
                        val fontColor = call.argument<Number>("fontColor")?.toInt() ?: android.graphics.Color.WHITE
                        val borderColor = call.argument<Number>("borderColor")?.toInt() ?: android.graphics.Color.BLACK
                        val borderWidth = call.argument<Double>("borderWidth") ?: 3.0
                        val bgColor = call.argument<Number>("backgroundColor")?.toInt() ?: android.graphics.Color.TRANSPARENT
                        val fontSizeScale = call.argument<Double>("fontSizeScale") ?: 1.0
                        val bold = call.argument<Boolean>("bold") ?: false
                        player?.applySubtitleStyle(fontColor, borderColor, borderWidth, bgColor, fontSizeScale, bold)
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
        stateChannel?.setStreamHandler(null)
        stateChannel = null
        player?.onStateUpdate = null
        player?.release()
        player = null
    }
}

class ExoFFmpegViewFactory(private val context: Context, private val player: ExoFFmpegPlayer) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ExoFFmpegView(context, player)
    }
}

/**
 * PlatformView — 使用 SurfaceView 渲染 ExoPlayer 视频输出（Hybrid Composition 模式）
 *
 * 选择 SurfaceView 而非 TextureView 的原因：
 * - SurfaceView 拥有独立硬件图层，解码器可零拷贝直出到显示合成器（Hardware Composer）
 * - 4K 10bit HDR 内容通过 TextureView 需要额外 GPU 拷贝，导致严重掉帧
 * - HDR10 元数据通过 SurfaceView 可直通到显示器，TextureView 会丢失
 * - 需要 Flutter Hybrid Composition 模式（PlatformViewLink + AndroidViewSurface）
 *
 * SurfaceHolder.Callback 管理 Surface 生命周期：
 * - surfaceCreated: 创建 Surface 绑定到 ExoPlayer
 * - surfaceChanged: ExoPlayer 自动适配
 * - surfaceDestroyed: 解绑 Surface
 */
class ExoFFmpegView(mCtx: Context, private val player: ExoFFmpegPlayer) : PlatformView {
    private val surfaceView: android.view.SurfaceView = android.view.SurfaceView(mCtx)
    private val subtitleView: SubtitleView = SubtitleView(mCtx)
    private val rootView: FrameLayout = FrameLayout(mCtx)

    init {
        // SurfaceView: 视频渲染层（独立硬件图层，零拷贝）
        rootView.addView(surfaceView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        // SubtitleView: 字幕叠加层，覆盖在视频上方
        rootView.addView(subtitleView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        // 将 SubtitleView 绑定到 ExoPlayer，接收内嵌字幕 cues
        player.setSubtitleView(subtitleView)

        surfaceView.holder.addCallback(object : android.view.SurfaceHolder.Callback {
            override fun surfaceCreated(holder: android.view.SurfaceHolder) {
                // SurfaceView 就绪，绑定 Surface 到 ExoPlayer
                player.setSurface(holder.surface)
            }

            override fun surfaceChanged(holder: android.view.SurfaceHolder, format: Int, width: Int, height: Int) {
                // Surface 尺寸变化，ExoPlayer 自动适配
            }

            override fun surfaceDestroyed(holder: android.view.SurfaceHolder) {
                // Surface 被销毁，从 ExoPlayer 解绑
                player.clearSurface()
            }
        })
    }

    override fun getView(): android.view.View {
        return rootView
    }

    override fun dispose() {
        // ExoPlayer 生命周期由 ExoFFmpegPlayer 管理
    }
}

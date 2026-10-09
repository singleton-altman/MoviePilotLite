package com.lanplayer

import android.content.Context
import android.graphics.SurfaceTexture
import android.media.AudioManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Surface
import kotlin.math.roundToInt
import androidx.media3.common.*
import androidx.media3.common.text.CueGroup
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.SubtitleView
import androidx.media3.ui.CaptionStyleCompat
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

/**
 * ExoPlayer + FFmpeg 音频软解播放器
 *
 * 封装 AndroidX Media3 ExoPlayer，支持：
 * - HDR 视频输出（SurfaceView HDR 自动适配）
 * - HLS / DASH / 渐进式下载
 * - OkHttp 数据源（连接池复用）
 * - 音轨 / 字幕轨切换
 * - FFmpeg 音频解码器（当 .so 可用时自动启用）
 */
class ExoFFmpegPlayer(private val context: Context) {

    /**
     * 状态推送回调（EventChannel）：ExoPlayer 事件触发时把当前状态快照推给 Dart 层，
     * 替代 Dart 侧 200ms 轮询 getState()，消除延迟与多余 MethodChannel 开销。
     */
    var onStateUpdate: ((Map<String, Any?>) -> Unit)? = null

    /** 构造状态快照 Map（与 getState() 字段一致，供 EventChannel 推送） */
    fun stateSnapshotMap(): Map<String, Any?> {
        val s = getState() ?: return emptyMap()
        return mapOf(
            "isPlaying" to s.isPlaying,
            "isBuffering" to s.isBuffering,
            "positionMs" to s.positionMs,
            "durationMs" to s.durationMs,
            "bufferedMs" to s.bufferedMs,
            "speed" to s.speed,
            "volume" to s.volume,
            "isHdr" to s.isHdr,
            "videoWidth" to s.videoWidth,
            "videoHeight" to s.videoHeight,
            "error" to s.error
        )
    }

    /** 触发一次状态推送（播放器事件回调中调用） */
    private fun emitState() {
        onStateUpdate?.invoke(stateSnapshotMap())
    }

    data class PlayerStateSnapshot(
        val textureId: Int,
        val durationMs: Long,
        val isPlaying: Boolean,
        val isBuffering: Boolean = false,
        val positionMs: Long = 0,
        val bufferedMs: Long = 0,
        val speed: Float = 1.0f,
        val volume: Float = 1.0f,
        val isHdr: Boolean = false,
        val videoWidth: Int = 0,
        val videoHeight: Int = 0,
        val error: String? = null
    )

    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var surfaceTexture: SurfaceTexture? = null
    private var surface: Surface? = null
    private var pendingSurfaceTexture: SurfaceTexture? = null  // TextureView 先于 open() 就绪时缓存
    private var subtitleView: SubtitleView? = null
    // 用户是否显式启用了原生字幕轨。onCues 防御：仅在此为 true 时才把 cue 转发给
    // SubtitleView，任何默认状态/残留事件都不会渲染原生字幕 → 从渲染端杜绝双层字幕。
    private var textTracksEnabled: Boolean = false
    // 最近一次 Dart 层推送的字幕样式。SubtitleView 由 PlatformView 创建，晚于
    // open()/applySubtitleStyle() 的调用时机（首次调用时 view 尚未创建会直接返回），
    // 这里暂存参数，待 view 就绪后由 setSubtitleView 补应用，避免原生字幕用默认小字号。
    private var pendingSubtitleFontColor: Int = android.graphics.Color.WHITE
    private var pendingSubtitleBorderColor: Int = android.graphics.Color.BLACK
    private var pendingSubtitleBorderWidth: Double = 3.0
    private var pendingSubtitleBackgroundColor: Int = android.graphics.Color.TRANSPARENT
    private var pendingSubtitleFontSizeScale: Double = 1.0
    private var pendingSubtitleBold: Boolean = false
    private var hasPendingSubtitleStyle: Boolean = false
    private var textureId: Int = -1
    private var detectedHdr: Boolean = false
    private var videoWidth: Int = 0
    private var videoHeight: Int = 0
    private var videoFrameRate: Float = 0f
    // ── "有声无画"检测（设备缺 HEVC Main10 等解码器时 ExoPlayer 静默只播音频）──
    private var firstFrameRendered: Boolean = false   // 是否已渲染首帧
    private var playerError: String? = null           // onPlayerError 捕获的致命错误
    private var hasVideoTrack: Boolean = false        // 媒体是否包含视频轨
    private var videoTrackSelected: Boolean = false   // 视频轨是否被选中（编码不支持时为 false）
    private var playbackStartMs: Long = 0L            // 开始播放(READY+playWhenReady)的时间戳
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager: AudioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    // 定时推送进度（250ms），替代 Dart 侧轮询 getState；mainHandler 已在上方声明
    private val positionRunnable = object : Runnable {
        override fun run() {
            if (exoPlayer != null) {
                emitState()
                mainHandler.postDelayed(this, POSITION_PUSH_INTERVAL_MS)
            }
        }
    }

    companion object {
        // "有声无画"判定阈值：
        // 视频轨存在但未被选中（编码不受支持）→ 播放 2.5s 后即可快速判定
        private const val NO_VIDEO_TRACK_TIMEOUT_MS = 5000L
        // 视频轨已选中且 Surface 就绪，但首帧迟迟未渲染 → 8s 兜底判定
        private const val NO_FIRST_FRAME_TIMEOUT_MS = 8000L
        // EventChannel 状态推送间隔
        private const val POSITION_PUSH_INTERVAL_MS = 250L

        private val okHttpClient: OkHttpClient by lazy {
            OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .build()
        }
    }

    /**
     * 检查 FFmpeg 扩展是否已加载
     */
    fun isFFmpegAvailable(): Boolean {
        return try {
            Class.forName("org.jellyfin.media3.ffmpeg.FFmpegAudioRenderer")
            true
        } catch (e: ClassNotFoundException) {
            try {
                Class.forName("androidx.media3.decoder.ffmpeg.FfmpegAudioRenderer")
                true
            } catch (e2: ClassNotFoundException) {
                false
            }
        }
    }

    fun getSupportedCodecs(): List<String> {
        return listOf("aac", "ac3", "eac3", "dts", "dts-hd", "truehd", "mlp",
                      "alac", "flac", "opus", "vorbis", "mp3")
    }

    /**
     * 打开媒体并创建 ExoPlayer 实例
     */
    fun open(
        url: String,
        headers: Map<String, String>,
        autoPlay: Boolean,
        enableFFmpeg: Boolean
    ): PlayerStateSnapshot? {
        try {
            // 释放旧实例
            release()

            // 创建 OkHttp 数据源工厂
            val dataSourceFactory = OkHttpDataSource.Factory(okHttpClient).apply {
                if (headers.isNotEmpty()) {
                    setDefaultRequestProperties(headers)
                }
            }

            // 创建 TrackSelector
            trackSelector = DefaultTrackSelector(context)
            // 注意：这里不再 setTrackTypeDisabled(TEXT)。禁用文本轨会让文本轨组从
            // player.currentTracks 消失（getSubtitleTracks 返回空），内嵌字幕轨永远
            // 进不了面板——而 FNNAS/Emby 对 mkv 内嵌字幕的提取端点实测挂起，
            // 原生轨（直接从视频流读取）是唯一可用路径。
            // 双层字幕由 onCues 防御（textTracksEnabled 门控）保证：即使 Exo 自动选中
            // 内嵌轨，textTracksEnabled=false 时 cue 也不会渲染；再加上下方清空
            // SubtitleView 残留帧，渲染端不会出现任何非用户主动选择的字幕层。
            textTracksEnabled = false
            subtitleView?.setCues(emptyList())

            // 创建 ExoPlayer
            // FFmpeg 音频软解兜底：enableFFmpeg=true（扩展类存在）时用
            // EXTENSION_RENDERER_MODE_ON_DEMAND —— 平台 MediaCodec 支持的格式
            // （AAC/MP3 等）仍走硬解省电，只有平台不支持的（TrueHD/DTS-HD 等）
            // 才落到 FFmpeg 扩展渲染器软解；扩展缺失时该模式等效默认行为。
            // setEnableDecoderFallback 允许 MediaCodec 初始化失败时自动换解码器。
            val renderersFactory = DefaultRenderersFactory(context)
                .setExtensionRendererMode(
                    if (enableFFmpeg) DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON
                    else DefaultRenderersFactory.EXTENSION_RENDERER_MODE_OFF
                )
                .setEnableDecoderFallback(true)
            exoPlayer = ExoPlayer.Builder(context)
                .setRenderersFactory(renderersFactory)
                .setTrackSelector(trackSelector!!)
                .setMediaSourceFactory(DefaultMediaSourceFactory(dataSourceFactory))
                .setHandleAudioBecomingNoisy(true)
                .build()

            // 监听播放器事件
            exoPlayer!!.addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    maybeMarkPlaybackStart()
                    emitState()
                }

                override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
                    maybeMarkPlaybackStart()
                    emitState()
                }

                override fun onRenderedFirstFrame() {
                    // 首帧渲染成功 → 排除"有声无画"
                    firstFrameRendered = true
                    emitState()
                }

                override fun onPlayerError(error: PlaybackException) {
                    // 致命播放错误（此前完全静默，有声黑屏无任何报错）
                    playerError = "播放错误: ${error.errorCodeName}"
                    emitState()
                }

                override fun onTracksChanged(tracks: Tracks) {
                    // 检测 HDR、视频分辨率，以及视频轨是否被选中
                    hasVideoTrack = false
                    videoTrackSelected = false
                    var selW = 0
                    var selH = 0
                    var hdr = false
                    for (group in tracks.groups) {
                        if (group.type != C.TRACK_TYPE_VIDEO) continue
                        // 媒体包含视频轨（即使因编码不受支持而未被选中）
                        hasVideoTrack = true
                        for (i in 0 until group.length) {
                            if (!group.isTrackSelected(i)) continue
                            videoTrackSelected = true
                            val format: Format = group.getTrackFormat(i)
                            selW = format.width
                            selH = format.height
                            // HDR10 (PQ/ST2084) 或 HLG — 使用反射以兼容不同 media3 版本
                            hdr = try {
                                val ctField = format.javaClass.getField("colorTransfer")
                                val ct = ctField.getInt(format)
                                ct == C.COLOR_TRANSFER_ST2084 || ct == C.COLOR_TRANSFER_HLG
                            } catch (_: Exception) {
                                false
                            }
                        }
                    }
                    videoWidth = selW
                    videoHeight = selH
                    detectedHdr = hdr
                    emitState()
                    // 帧率匹配：检测视频帧率并通知显示器切换刷新率
                    if (selW > 0) {
                        var fps = 0f
                        for (group in tracks.groups) {
                            if (group.type != C.TRACK_TYPE_VIDEO) continue
                            for (i in 0 until group.length) {
                                if (!group.isTrackSelected(i)) continue
                                fps = group.getTrackFormat(i).frameRate
                            }
                        }
                        if (fps > 0f && fps != videoFrameRate) {
                            videoFrameRate = fps
                            applyFrameRateMatching(fps)
                        }
                    }
                }
            })

            // 不创建虚拟 SurfaceTexture，由 ExoFFmpegView 的 TextureView 提供真实 Surface
            // ExoPlayer 在没有 Surface 时会播放音频并缓冲视频，Surface 到来后自动渲染第一帧

            // 绑定 SubtitleView 到 ExoPlayer（如果已由 ExoFFmpegView 创建）
            subtitleView?.let { exoPlayer!!.addListener(subtitleCueListener) }

            // 启动定时状态推送（EventChannel）
            mainHandler.postDelayed(positionRunnable, POSITION_PUSH_INTERVAL_MS)

            // 检查是否有 TextureView 在 open() 之前已就绪的 SurfaceTexture
            val pendingST = pendingSurfaceTexture
            if (pendingST != null) {
                pendingSurfaceTexture = null
                surface?.release()
                surfaceTexture = pendingST
                surface = Surface(pendingST)
                exoPlayer!!.setVideoSurface(surface)
            }

            // 设置 MediaItem
            val uri = Uri.parse(url)
            val mediaItem = MediaItem.fromUri(uri)
            exoPlayer!!.setMediaItem(mediaItem)
            exoPlayer!!.prepare()

            if (autoPlay) {
                exoPlayer!!.playWhenReady = true
            }

            return getState()
        } catch (e: Exception) {
            release()
            return null
        }
    }

    fun play() {
        exoPlayer?.playWhenReady = true
    }

    fun pause() {
        exoPlayer?.playWhenReady = false
    }

    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }

    fun setSpeed(speed: Float) {
        exoPlayer?.setPlaybackParameters(PlaybackParameters(speed))
    }

    fun setVolume(volume: Float) {
        // 应用内音量与系统媒体音量联动：播放器自身音量固定 1.0，实际响度由
        // 系统音量（STREAM_MUSIC）控制，硬件音量键/系统音量条与 App 内 HUD 完全对应。
        try {
            exoPlayer?.volume = 1.0f
        } catch (_: Exception) {}
        setSystemVolume(volume)
    }

    /** 读取系统媒体音量（0-1） */
    fun getSystemVolume(): Float {
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (max <= 0) return 0f
        return audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toFloat() / max
    }

    /** 设置系统媒体音量（0-1） */
    fun setSystemVolume(volume: Float) {
        try {
            val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val v = (volume.coerceIn(0f, 1f) * max).roundToInt()
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, v, 0)
        } catch (_: Exception) {}
    }

    fun stop() {
        exoPlayer?.stop()
    }

    fun release() {
        mainHandler.removeCallbacks(positionRunnable)
        try {
            exoPlayer?.removeListener(subtitleCueListener)
            exoPlayer?.release()
        } catch (_: Exception) {}
        // 释放播放器时清掉 SubtitleView 最后一帧：SubtitleView 生命周期长于 ExoPlayer
        // （由 View 持有，切集/重开只换 Player），不清理则旧字幕帧会残留到下一个会话。
        textTracksEnabled = false
        subtitleView?.setCues(emptyList())
        try {
            surface?.release()
        } catch (_: Exception) {}
        try {
            surfaceTexture?.release()
        } catch (_: Exception) {}
        exoPlayer = null
        surface = null
        surfaceTexture = null
        pendingSurfaceTexture = null
        trackSelector = null
        textureId = -1
        detectedHdr = false
        videoWidth = 0
        videoHeight = 0
        firstFrameRendered = false
        playerError = null
        hasVideoTrack = false
        videoTrackSelected = false
        playbackStartMs = 0L
    }

    /**
     * 由 ExoFFmpegView 调用：SurfaceView 的 SurfaceHolder 就绪时直接传入 Surface。
     * SurfaceView 支持 HDR 直通（TextureView 不支持）。
     */
    fun setSurface(s: Surface) {
        try {
            surface = s
            exoPlayer?.setVideoSurface(surface)
            if (videoFrameRate > 0f) applyFrameRateMatching(videoFrameRate)
            // Surface 就绪后重置"有声无画"检测计时器，避免 Surface 延迟创建导致误判
            if (playbackStartMs != 0L) {
                playbackStartMs = SystemClock.elapsedRealtime()
                firstFrameRendered = false
            }
        } catch (_: Exception) {}
    }

    /**
     * 由 ExoFFmpegView 调用：当 TextureView 的 SurfaceTexture 就绪时，
     * 创建 Surface 并绑定到 ExoPlayer。ExoPlayer 会自动开始渲染视频帧。
     * 如果 ExoPlayer 尚未创建（open() 未调用），缓存 SurfaceTexture 稍后绑定。
     */
    fun setSurfaceTexture(st: SurfaceTexture, width: Int, height: Int) {
        try {
            if (exoPlayer == null) {
                // ExoPlayer 尚未创建，缓存 SurfaceTexture 等 open() 时绑定
                pendingSurfaceTexture = st
                return
            }
            // 释放旧的 Surface（如果有）
            surface?.release()
            surfaceTexture = st
            surface = Surface(st)
            exoPlayer?.setVideoSurface(surface)
        } catch (e: Exception) {
            // 绑定失败不影响音频播放
        }
    }

    /**
     * 由 ExoFFmpegView 调用：当 TextureView 的 SurfaceTexture 被销毁时，
     * 移除 ExoPlayer 的视频 Surface，避免崩溃。
     */
    fun clearSurfaceTexture() {
        try {
            exoPlayer?.setVideoSurface(null)
            surface?.release()
            surface = null
            surfaceTexture = null
        } catch (_: Exception) {}
    }

    /** SurfaceView 模式：解绑 Surface */
    fun clearSurface() {
        try {
            exoPlayer?.setVideoSurface(null)
            surface = null
        } catch (_: Exception) {}
    }

    fun getState(): PlayerStateSnapshot? {
        val player = exoPlayer ?: return null
        val isPlaying = player.playWhenReady && player.playbackState == Player.STATE_READY

        // "有声无画"检测：设备缺少对应解码器（如 HEVC Main10）时，
        // ExoPlayer 会静默地只播音频、不渲染视频且不抛错，必须主动识别：
        // 1) onPlayerError 捕获的致命错误优先上报
        // 2) 媒体含视频轨但未被选中（编码不受支持）→ 播放 2.5s 后快速判定
        // 3) 视频轨已选中且 Surface 就绪，但首帧 8s 仍未渲染 → 兜底判定
        var error = playerError
        if (error == null && hasVideoTrack && isPlaying && playbackStartMs != 0L) {
            val elapsed = SystemClock.elapsedRealtime() - playbackStartMs
            if (!videoTrackSelected && elapsed > NO_VIDEO_TRACK_TIMEOUT_MS) {
                error = "视频编码不受支持，无视频输出"
            } else if (videoTrackSelected && surface != null && !firstFrameRendered &&
                elapsed > NO_FIRST_FRAME_TIMEOUT_MS) {
                error = "视频解码失败，无画面输出"
            }
        }

        return PlayerStateSnapshot(
            textureId = textureId,
            durationMs = runCatching { player.duration }.getOrDefault(0L).coerceAtLeast(0L),
            isPlaying = isPlaying,
            isBuffering = player.playbackState == Player.STATE_BUFFERING,
            positionMs = runCatching { player.currentPosition }.getOrDefault(0L).coerceAtLeast(0L),
            bufferedMs = runCatching { player.bufferedPosition }.getOrDefault(0L).coerceAtLeast(0L),
            speed = player.playbackParameters.speed,
            volume = getSystemVolume(),
            isHdr = detectedHdr,
            videoWidth = videoWidth,
            videoHeight = videoHeight,
            error = error
        )
    }

    /// 记录播放起始时间（READY 且 playWhenReady 时），用于"有声无画"超时判定
    private fun maybeMarkPlaybackStart() {
        val p = exoPlayer ?: return
        if (p.playWhenReady && p.playbackState == Player.STATE_READY && playbackStartMs == 0L) {
            playbackStartMs = SystemClock.elapsedRealtime()
        }
    }

    fun getAudioTracks(): List<Map<String, Any>> {
        val player = exoPlayer ?: return emptyList()
        val tracks = player.currentTracks
        val result = mutableListOf<Map<String, Any>>()
        var index = 0

        for (group in tracks.groups) {
            if (group.type != C.TRACK_TYPE_AUDIO) continue
            for (i in 0 until group.length) {
                val format = group.getTrackFormat(i)
                result.add(mapOf(
                    "index" to index,
                    "label" to (format.label ?: "Audio ${index + 1}"),
                    "language" to (format.language ?: "unknown"),
                    "codec" to (format.sampleMimeType ?: "unknown"),
                    "channels" to format.channelCount,
                    "sampleRate" to format.sampleRate,
                    "isSelected" to group.isTrackSelected(i)
                ))
                index++
            }
        }
        return result
    }

    fun getSubtitleTracks(): List<Map<String, Any>> {
        val player = exoPlayer ?: return emptyList()
        val tracks = player.currentTracks
        val result = mutableListOf<Map<String, Any>>()
        var index = 0

        for (group in tracks.groups) {
            if (group.type != C.TRACK_TYPE_TEXT) continue
            for (i in 0 until group.length) {
                val format = group.getTrackFormat(i)
                result.add(mapOf(
                    "index" to index,
                    "label" to (format.label ?: "Subtitle ${index + 1}"),
                    "language" to (format.language ?: "unknown"),
                    "codec" to (format.sampleMimeType ?: "unknown"),
                    // 必须与 textTracksEnabled 取与。open() 刻意不禁用 TEXT 轨
                    // （否则文本轨组会从 currentTracks 消失，内嵌字幕进不了面板），
                    // 所以 Exo 可能自动选中一条内嵌轨 —— 那条轨的 isTrackSelected
                    // 为 true，但 onCues 门控会把它的 cue 丢掉，屏幕上什么都没有。
                    // 只报 isTrackSelected 就等于对外宣称一条并未渲染的轨是"当前轨"。
                    "isSelected" to (textTracksEnabled && group.isTrackSelected(i))
                ))
                index++
            }
        }
        return result
    }

    fun setAudioTrack(index: Int) {
        val player = exoPlayer ?: return
        val selector = trackSelector ?: return
        val tracks = player.currentTracks
        var currentIndex = 0

        for (group in tracks.groups) {
            if (group.type != C.TRACK_TYPE_AUDIO) continue
            for (i in 0 until group.length) {
                if (currentIndex == index) {
                    // 使用 TrackSelectionOverride 选择指定音轨
                    val override = TrackSelectionOverride(group.mediaTrackGroup, listOf(i))
                    selector.setParameters(
                        selector.buildUponParameters()
                            .clearOverridesOfType(C.TRACK_TYPE_AUDIO)
                            .addOverride(override)
                    )
                    return
                }
                currentIndex++
            }
        }
    }

    fun setSubtitleTrack(index: Int) {
        val player = exoPlayer ?: return
        val selector = trackSelector ?: return

        if (index < 0) {
            // 关闭字幕
            selector.setParameters(
                selector.buildUponParameters()
                    .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
            )
            // 清除 SubtitleView 上最后一帧残留文字
            textTracksEnabled = false
            subtitleView?.setCues(emptyList())
            return
        }

        val tracks = player.currentTracks
        var currentIndex = 0

        for (group in tracks.groups) {
            if (group.type != C.TRACK_TYPE_TEXT) continue
            for (i in 0 until group.length) {
                if (currentIndex == index) {
                    selector.setParameters(
                        selector.buildUponParameters()
                            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                            .addOverride(TrackSelectionOverride(group.mediaTrackGroup, listOf(i)))
                    )
                    textTracksEnabled = true
                    return
                }
                currentIndex++
            }
        }
    }

    fun captureFrame(): ByteArray? {
        // 帧截取需要 GL 渲染管线，暂不支持
        return null
    }

    /**
     * 绑定 SubtitleView 到 ExoPlayer，由 ExoFFmpegView 在创建布局时调用。
     * 通过 Player.Listener.onCues 将字幕 cues 转发给 SubtitleView 渲染。
     */
    fun setSubtitleView(view: SubtitleView) {
        subtitleView = view
        // view 就绪：先应用默认样式兜底，若 Dart 层已推送过用户样式（applySubtitleStyle
        // 在 view 创建前调用会暂存），则用用户样式覆盖默认值——修复原生字幕字号过小。
        if (hasPendingSubtitleStyle) {
            applySubtitleStyle(
                pendingSubtitleFontColor,
                pendingSubtitleBorderColor,
                pendingSubtitleBorderWidth,
                pendingSubtitleBackgroundColor,
                pendingSubtitleFontSizeScale,
                pendingSubtitleBold
            )
        } else {
            applyDefaultSubtitleStyle()
        }
        // 如果 ExoPlayer 已创建，立即注册 cue 监听
        exoPlayer?.addListener(subtitleCueListener)
    }

    /**
     * SubtitleView cue 转发监听器：将 ExoPlayer 产生的字幕 cues 渲染到 SubtitleView
     */
    private val subtitleCueListener = object : Player.Listener {
        override fun onCues(cueGroup: CueGroup) {
            // 防御：仅当用户显式选中原生字幕轨后才渲染。即使 TrackSelector 的
            // 禁用因某些媒体路径失效、Exo 自动选中了内嵌轨，这里也会把 cue 丢弃，
            // 原生 SubtitleView 不会出现任何非用户主动选择的字幕层。
            if (textTracksEnabled) subtitleView?.setCues(cueGroup.cues)
        }
    }

    /**
     * 应用默认字幕样式：白字 + 黑色描边，字号为屏幕短边的 7%
     */
    private fun applyDefaultSubtitleStyle() {
        val sv = subtitleView ?: return
        sv.setStyle(
            CaptionStyleCompat(
                android.graphics.Color.WHITE,          // 前景色
                android.graphics.Color.TRANSPARENT,    // 背景色（透明）
                android.graphics.Color.TRANSPARENT,    // 窗口色（透明）
                CaptionStyleCompat.EDGE_TYPE_OUTLINE,  // 描边类型
                android.graphics.Color.BLACK,          // 描边色
                null                                   // 字体
            )
        )
        // 字号：屏幕短边 6% 原始像素（不用 SP，避免 Flutter PlatformView 密度转换偏差），
        // 与 Flutter 层 SubtitleOverlay 的 6% 基准一致，保证原生轨/外挂轨字大小统一。
        val dm = context.resources.displayMetrics
        val screenShortPx = minOf(dm.heightPixels, dm.widthPixels)
        sv.setFixedTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, screenShortPx * 0.06f)
        sv.setApplyEmbeddedStyles(false) // 不使用内嵌样式，统一使用自定义样式
        sv.setApplyEmbeddedFontSizes(false)
    }

    /**
     * 从 Dart 层应用字幕样式设置
     */
    fun applySubtitleStyle(
        fontColor: Int,
        borderColor: Int,
        borderWidth: Double,
        backgroundColor: Int,
        fontSizeScale: Double,
        bold: Boolean
    ) {
        // 暂存样式：SubtitleView 可能尚未创建（PlatformView 晚于 open() 构建），
        // view 就绪后由 setSubtitleView 补应用，保证原生字幕始终用用户设置的样式。
        pendingSubtitleFontColor = fontColor
        pendingSubtitleBorderColor = borderColor
        pendingSubtitleBorderWidth = borderWidth
        pendingSubtitleBackgroundColor = backgroundColor
        pendingSubtitleFontSizeScale = fontSizeScale
        pendingSubtitleBold = bold
        hasPendingSubtitleStyle = true
        val sv = subtitleView ?: return
        val edgeType = if (borderWidth > 0) {
            CaptionStyleCompat.EDGE_TYPE_OUTLINE
        } else {
            CaptionStyleCompat.EDGE_TYPE_NONE
        }
        sv.setStyle(
            CaptionStyleCompat(
                fontColor,
                backgroundColor,
                android.graphics.Color.TRANSPARENT,
                edgeType,
                borderColor,
                if (bold) android.graphics.Typeface.DEFAULT_BOLD else null
            )
        )
        // 字号：屏幕短边 6% × 用户缩放（原始像素，避免 SP 密度转换偏差），
        // 与 Flutter 层 SubtitleOverlay 的 6% 基准一致。
        val dm = context.resources.displayMetrics
        val screenShortPx = minOf(dm.heightPixels, dm.widthPixels)
        val finalFontSizePx = screenShortPx * 0.06f * fontSizeScale.toFloat()
        android.util.Log.i(
            "ExoFFmpeg",
            "字幕样式: screen=${dm.widthPixels}x${dm.heightPixels}, shortPx=$screenShortPx, " +
                "baseRatio=0.06, scale=$fontSizeScale, finalFontSizePx=$finalFontSizePx, " +
                "bold=$bold, borderWidth=$borderWidth"
        )
        sv.setFixedTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, finalFontSizePx)
        sv.setApplyEmbeddedStyles(false)
        sv.setApplyEmbeddedFontSizes(false)
        android.util.Log.i(
            "ExoFFmpeg",
            "字幕样式应用完成: embeddedStyles=false, embeddedFontSizes=false"
        )
    }

    /**
     * 帧率匹配：请求显示器切换刷新率以匹配视频帧率。
     * 25fps 视频在 60Hz 电视上会产生 3:2 pulldown 抖动，
     * 切换到 50Hz 后每帧显示 2 次，完全消除 judder。
     * 需要 API 30+（Android 11），低版本静默跳过。
     */
    private fun applyFrameRateMatching(fps: Float) {
        if (android.os.Build.VERSION.SDK_INT < 30) return
        val s = surface ?: return
        try {
            s.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ALWAYS
            )
            android.util.Log.i("ExoFFmpeg", "帧率匹配: 请求显示器切换到 ${fps}Hz")
        } catch (e: Exception) {
            android.util.Log.w("ExoFFmpeg", "帧率匹配失败: ${e.message}")
        }
    }
}

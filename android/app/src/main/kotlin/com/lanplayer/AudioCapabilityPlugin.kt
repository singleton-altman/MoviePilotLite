package com.lanplayer

import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/**
 * 音频输出能力探测:设备上是否存在环绕声输出(HDMI 系)。
 *
 * 用途:MPV 的 audio-channels=stereo + ad-lavc-downmix=yes 能让 TrueHD 等
 * 多声道直连出声,但对 HDMI 环绕声系统是降级(5.1 被压成立体声)。
 * Dart 侧据此决定是否强制下混:有环绕输出 → 不强制(原生多声道直出)。
 */
class AudioCapabilityPlugin : FlutterPlugin {
    companion object {
        private const val CHANNEL = "com.lanplayer/audio_caps"
    }

    private var channel: MethodChannel? = null
    private var audioManager: AudioManager? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        audioManager = binding.applicationContext.getSystemService(AudioManager::class.java)
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasSurroundOutput" -> result.success(hasSurroundOutput())
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** HDMI / HDMI_ARC 存在即认定环绕声输出(USB DAC 常为立体声,不列入)。 */
    private fun hasSurroundOutput(): Boolean {
        val am = audioManager ?: return false
        val devices = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        for (d in devices) {
            when (d.type) {
                AudioDeviceInfo.TYPE_HDMI, AudioDeviceInfo.TYPE_HDMI_ARC -> return true
            }
            // TYPE_HDMI_EARC = 29 仅 API 34+,常量在老编译目标上不存在,用数值判断
            if (android.os.Build.VERSION.SDK_INT >= 34 && d.type == 29) return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        audioManager = null
    }
}

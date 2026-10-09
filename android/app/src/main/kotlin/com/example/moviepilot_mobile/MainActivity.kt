package com.example.moviepilot_mobile

import android.content.Intent
import android.content.ComponentName
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.lanplayer.AudioCapabilityPlugin
import com.lanplayer.ExoFFmpegPlugin
import com.lanplayer.IsoPlugin
import com.lanplayer.LibassPlugin
import com.lanplayer.MpvSurfacePlatformViewFactory
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val appUpdateChannel = "org.moviepilot/app_update"
    private val appIconChannel = "org.moviepilot/app_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // ── 内嵌播放器(lanplayer_player)原生插件 ──
        // ExoPlayer + FFmpeg 音频扩展(视频渲染/音频软解兜底)
        flutterEngine.plugins.add(ExoFFmpegPlugin())
        // libass ASS/SSA 特效字幕渲染
        flutterEngine.plugins.add(LibassPlugin())
        // 音频输出能力探测(环绕声检测)
        flutterEngine.plugins.add(AudioCapabilityPlugin())
        // ISO 原盘原生直连(libudfread)
        flutterEngine.plugins.add(IsoPlugin())
        // 定制 libmpv 原生 Surface 视频视图(NativeSurfaceEngine 直渲,
        // vo=gpu-next + SurfaceView,绕开 Flutter 纹理管线)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "lanplayer/mpv_surface",
            MpvSurfacePlatformViewFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
        // ── 应用更新热更新通道 ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appUpdateChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path").orEmpty()
                    result.success(installApk(path))
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appIconChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAppIcon" -> result.success(setAppIcon(call.argument<String>("iconId").orEmpty()))
                else -> result.notImplemented()
            }
        }
    }

    private fun setAppIcon(iconId: String): Boolean {
        val aliases = mapOf(
            "default" to "MainActivityDefault",
            "midnight" to "MainActivityMidnight",
            "sunset" to "MainActivitySunset",
            "mint" to "MainActivityMint",
            "neon" to "MainActivityNeon",
            "aurora" to "MainActivityAurora",
            "sunset_pop" to "MainActivitySunsetPop",
            "mono" to "MainActivityMono",
        )
        val selected = aliases[iconId] ?: return false
        aliases.values.forEach { alias ->
            packageManager.setComponentEnabledSetting(
                ComponentName(this, "$packageName.$alias"),
                if (alias == selected) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
        return true
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun installApk(path: String): String {
        val apkFile = File(path)
        if (!apkFile.exists() || !apkFile.isFile) {
            return "missingFile"
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            )
            startActivity(intent)
            return "permissionRequired"
        }

        val apkUri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            apkFile,
        )
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(installIntent)
        return "launched"
    }
}

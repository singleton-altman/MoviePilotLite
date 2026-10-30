package com.example.moviepilot_mobile.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * 小组件海报缓存。
 *
 * 海报在后台刷新时下载到应用私有目录，渲染阶段只读本地文件：
 * RemoteViews 里直接联网加载图片很容易超时或被系统回收，广播回调里更不能做网络请求。
 */
internal object WidgetPosterCache {
    private const val DIR_NAME = "widget_posters"
    private const val MAX_BYTES = 1_500_000
    private const val CONNECT_TIMEOUT_MS = 8_000
    private const val READ_TIMEOUT_MS = 12_000

    fun fileFor(context: Context, url: String): File? {
        val name = fileNameFor(url) ?: return null
        val file = File(dir(context), name)
        return if (file.isFile && file.length() > 0L) file else null
    }

    /**
     * 解码出可直接放进 RemoteViews 的小图。
     *
     * 私有目录里的文件桌面进程读不到（setImageViewUri 会静默失败），所以这里解码成
     * Bitmap 交给小组件；只按行高降采样，单张几十 KB，远低于 RemoteViews 的传输上限。
     */
    fun loadBitmap(context: Context, url: String, maxWidthPx: Int): Bitmap? {
        val file = fileFor(context, url) ?: return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.absolutePath, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            var sample = 1
            val limit = maxWidthPx.coerceAtLeast(1)
            while (bounds.outWidth / (sample * 2) >= limit) {
                sample *= 2
            }
            BitmapFactory.decodeFile(
                file.absolutePath,
                BitmapFactory.Options().apply { inSampleSize = sample },
            )
        } catch (_: Exception) {
            null
        }
    }

    fun prune(context: Context, keepUrls: Collection<String>) {
        val keep = keepUrls.mapNotNull { fileNameFor(it) }.toSet()
        val dir = dir(context)
        dir.listFiles()?.forEach { file ->
            if (file.name !in keep) file.delete()
        }
    }

    /** 下载 [url] 到本地缓存；已存在则跳过。返回可读取的文件或 null。 */
    fun download(context: Context, url: String): File? {
        val name = fileNameFor(url) ?: return null
        val dir = dir(context)
        val file = File(dir, name)
        if (file.isFile && file.length() > 0L) return file

        val temp = File(dir, "$name.tmp")
        return try {
            val connection = (URL(url).openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
                instanceFollowRedirects = true
                setRequestProperty("accept", "image/*")
            }
            try {
                if (connection.responseCode !in 200..299) return null
                connection.inputStream.use { input ->
                    temp.outputStream().use { output ->
                        val buffer = ByteArray(16 * 1024)
                        var total = 0L
                        while (true) {
                            val read = input.read(buffer)
                            if (read <= 0) break
                            total += read
                            if (total > MAX_BYTES) return null
                            output.write(buffer, 0, read)
                        }
                    }
                }
            } finally {
                connection.disconnect()
            }
            if (temp.length() > 0L) {
                if (file.exists()) file.delete()
                if (temp.renameTo(file)) file else null
            } else {
                null
            }
        } catch (_: Exception) {
            null
        } finally {
            if (temp.exists()) temp.delete()
        }
    }

    private fun dir(context: Context): File =
        File(context.filesDir, DIR_NAME).apply { if (!isDirectory) mkdirs() }

    /** 用 URL 的哈希做文件名，避免路径字符直接落盘。 */
    private fun fileNameFor(url: String): String? {
        val trimmed = url.trim()
        if (trimmed.isEmpty()) return null
        if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) return null
        return "${Integer.toHexString(trimmed.hashCode())}-${trimmed.length}.img"
    }
}

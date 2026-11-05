package com.example.moviepilot_mobile.widget

import android.content.Context

internal data class WidgetSession(
    val server: String,
    val accessToken: String,
)

internal data class CalendarCache(
    val payload: String,
    val cachedAt: Long,
)

/**
 * 小组件与 App 进程共享的本地存储。
 *
 * 登录凭证由 Flutter 侧通过 MethodChannel 写入，小组件在后台刷新时直接读取，
 * 因此不依赖 App 处于前台。
 */
internal object WidgetSessionStore {
    private const val PREFS_NAME = "moviepilot_widget"
    private const val KEY_SERVER = "shared_server_url"
    private const val KEY_TOKEN = "shared_access_token"
    private const val KEY_CACHE = "subscribe_calendar_cache"
    private const val KEY_CACHED_AT = "subscribe_calendar_cached_at"
    private const val KEY_LAST_ERROR = "subscribe_calendar_last_error"

    fun saveSession(context: Context, server: String, accessToken: String) {
        val normalizedServer = server.trim()
        val normalizedToken = accessToken.trim()
        if (normalizedServer.isEmpty() || normalizedToken.isEmpty()) return
        val prefs = prefs(context)
        val editor = prefs.edit()
        val changed = prefs.getString(KEY_SERVER, null) != normalizedServer ||
            prefs.getString(KEY_TOKEN, null) != normalizedToken
        if (changed) {
            // 换服/换号时先丢弃旧账号的缓存，避免新会话短暂显示他人订阅
            editor.remove(KEY_CACHE).remove(KEY_CACHED_AT).remove(KEY_LAST_ERROR)
        }
        editor
            .putString(KEY_SERVER, normalizedServer)
            .putString(KEY_TOKEN, normalizedToken)
            .apply()
    }

    fun clearSession(context: Context) {
        prefs(context)
            .edit()
            .remove(KEY_SERVER)
            .remove(KEY_TOKEN)
            .remove(KEY_CACHE)
            .remove(KEY_CACHED_AT)
            .remove(KEY_LAST_ERROR)
            .apply()
    }

    fun loadSession(context: Context): WidgetSession? {
        val prefs = prefs(context)
        val server = prefs.getString(KEY_SERVER, null)?.trim().orEmpty()
        val token = prefs.getString(KEY_TOKEN, null)?.trim().orEmpty()
        if (server.isEmpty() || token.isEmpty()) return null
        return WidgetSession(server = server, accessToken = token)
    }

    fun saveCache(context: Context, payload: String, cachedAt: Long) {
        prefs(context)
            .edit()
            .putString(KEY_CACHE, payload)
            .putLong(KEY_CACHED_AT, cachedAt)
            .apply()
    }

    fun loadCache(context: Context): CalendarCache? {
        val prefs = prefs(context)
        val payload = prefs.getString(KEY_CACHE, null).orEmpty()
        val cachedAt = prefs.getLong(KEY_CACHED_AT, 0L)
        if (payload.isBlank() || cachedAt <= 0L) return null
        return CalendarCache(payload = payload, cachedAt = cachedAt)
    }

    fun setLastError(context: Context, hasError: Boolean) {
        prefs(context).edit().putBoolean(KEY_LAST_ERROR, hasError).apply()
    }

    fun hasLastError(context: Context): Boolean =
        prefs(context).getBoolean(KEY_LAST_ERROR, false)

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}

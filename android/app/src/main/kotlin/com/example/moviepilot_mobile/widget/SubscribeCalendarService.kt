package com.example.moviepilot_mobile.widget

import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.time.LocalDate
import java.time.ZoneOffset

internal data class CalendarEpisode(
    val date: String,
    val showName: String,
    val seasonNumber: Int,
    val episodeNumber: Int,
    val episodeTitle: String,
    val posterUrl: String = "",
)

/**
 * 订阅日历数据抓取：与 iOS 小组件保持同一契约。
 *
 * 1. `GET /api/v1/subscribe/` 取用户订阅，只保留电视剧；
 * 2. `GET /api/v1/tmdb/{tmdbid}/{season}` 取分集，筛掉已播出的日期；
 * 3. 按播出日期升序返回最近的若干条。
 */
internal class SubscribeCalendarService {
    fun fetch(server: String, accessToken: String): List<CalendarEpisode> {
        val base = normalizeBase(server)
        val subscribes = requestArray(base, "/api/v1/subscribe/", accessToken)
        val today = LocalDate.now(ZoneOffset.UTC)
        val items = mutableListOf<CalendarEpisode>()
        var fetchedShows = 0
        val deadline = System.currentTimeMillis() + MAX_FETCH_MILLIS

        for (index in 0 until subscribes.length()) {
            if (fetchedShows >= MAX_SUBSCRIPTIONS) break
            if (System.currentTimeMillis() > deadline) break
            val subscribe = subscribes.optJSONObject(index) ?: continue
            if (!isTv(subscribe.optString("type"))) continue
            val tmdbId = resolveTmdbId(subscribe) ?: continue
            if (tmdbId <= 0) continue

            val season = (readInt(subscribe, "season") ?: 1).coerceAtLeast(1)
            fetchedShows += 1
            val episodes = try {
                requestArray(base, "/api/v1/tmdb/$tmdbId/$season", accessToken)
            } catch (_: Exception) {
                continue
            }

            val showName = subscribe.optString("name").trim().ifEmpty { "剧集 $tmdbId" }
            val posterUrl = subscribe.optString("poster").trim()
            for (episodeIndex in 0 until episodes.length()) {
                val episode = episodes.optJSONObject(episodeIndex) ?: continue
                val airDate = episode.optString("air_date").trim()
                // 小组件只排「近期上映」，没有播出日期的分集无法排序，直接跳过
                if (airDate.isEmpty()) continue
                val parsedDate = runCatching { LocalDate.parse(airDate) }.getOrNull() ?: continue
                if (parsedDate.isBefore(today)) continue
                items.add(
                    CalendarEpisode(
                        date = airDate,
                        showName = showName,
                        seasonNumber = season,
                        episodeNumber = readInt(episode, "episode_number") ?: 0,
                        episodeTitle = episode.optString("name").trim().ifEmpty { "待播出" },
                        posterUrl = posterUrl,
                    ),
                )
            }
        }

        items.sortWith(compareBy({ it.date }, { it.showName }, { it.episodeNumber }))
        return items.take(MAX_ITEMS)
    }

    private fun requestArray(base: String, path: String, accessToken: String): JSONArray {
        val connection = (URL(base + path).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = CONNECT_TIMEOUT_MS
            readTimeout = READ_TIMEOUT_MS
            setRequestProperty("accept", "application/json")
            setRequestProperty("authorization", "Bearer $accessToken")
        }
        try {
            val code = connection.responseCode
            if (code !in 200..299) throw IOException("HTTP $code")
            val body = connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            if (body.isBlank()) return JSONArray()
            return when (val parsed = JSONTokener(body).nextValue()) {
                is JSONArray -> parsed
                is JSONObject -> parsed.optJSONArray("data") ?: JSONArray()
                else -> JSONArray()
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun normalizeBase(server: String): String {
        val trimmed = server.trim().trimEnd('/')
        if (trimmed.isEmpty()) throw IOException("empty server")
        return if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
            trimmed
        } else {
            "https://$trimmed"
        }
    }

    private fun isTv(type: String): Boolean {
        val value = type.trim().lowercase()
        return value == "tv" || value.contains("tv") || value.contains("电视剧")
    }

    /**
     * v3 服务端的订阅只带 `media_source` + `media_id`，旧版才直接给 `tmdbid`。
     * 这里按与 App 相同的规则还原 TMDB 标识，否则整个订阅列表都会被跳过。
     */
    private fun resolveTmdbId(subscribe: JSONObject): Int? {
        readInt(subscribe, "tmdbid")?.takeIf { it > 0 }?.let { return it }

        val source = subscribe.optString("media_source").trim().lowercase()
        if (source != "tmdb" && source != "themoviedb") return null

        val rawMediaId = when (val value = subscribe.opt("media_id")) {
            is Number -> value.toString()
            is String -> value.trim()
            else -> ""
        }
        // media_id 可能是 "tv:12345" 这类带前缀的形态
        val digits = rawMediaId.substringAfterLast(':').trim()
        return digits.toIntOrNull()?.takeIf { it > 0 }
    }

    private fun readInt(source: JSONObject, key: String): Int? {
        if (!source.has(key) || source.isNull(key)) return null
        return when (val value = source.opt(key)) {
            is Number -> value.toInt()
            is String -> value.trim().toIntOrNull()
            else -> null
        }
    }

    private companion object {
        const val CONNECT_TIMEOUT_MS = 10_000
        const val READ_TIMEOUT_MS = 15_000
        const val MAX_SUBSCRIPTIONS = 80
        const val MAX_FETCH_MILLIS = 240_000L
        const val MAX_ITEMS = 10
    }
}

internal object SubscribeCalendarCodec {
    fun encode(items: List<CalendarEpisode>): String {
        val array = JSONArray()
        items.forEach { item ->
            array.put(
                JSONObject().apply {
                    put("date", item.date)
                    put("showName", item.showName)
                    put("seasonNumber", item.seasonNumber)
                    put("episodeNumber", item.episodeNumber)
                    put("episodeTitle", item.episodeTitle)
                    put("posterUrl", item.posterUrl)
                },
            )
        }
        return array.toString()
    }

    fun decode(payload: String): List<CalendarEpisode> {
        if (payload.isBlank()) return emptyList()
        val array = runCatching { JSONArray(payload) }.getOrNull() ?: return emptyList()
        val items = mutableListOf<CalendarEpisode>()
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            val date = item.optString("date")
            if (date.isBlank()) continue
            items.add(
                CalendarEpisode(
                    date = date,
                    showName = item.optString("showName"),
                    seasonNumber = item.optInt("seasonNumber", 1),
                    episodeNumber = item.optInt("episodeNumber", 0),
                    episodeTitle = item.optString("episodeTitle"),
                    posterUrl = item.optString("posterUrl"),
                ),
            )
        }
        return items
    }
}

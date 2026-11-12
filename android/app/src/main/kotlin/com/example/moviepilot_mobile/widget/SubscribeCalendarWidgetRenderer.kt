package com.example.moviepilot_mobile.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.res.Configuration
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.example.moviepilot_mobile.MainActivity
import com.example.moviepilot_mobile.R
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

internal object SubscribeCalendarWidgetRenderer {
    private const val TAG = "SubscribeWidget"
    private const val DEEP_LINK = "moviepilot://subscribe-calendar"
    private const val MAX_ROWS = 14

    // 上下内边距（8 + 7）与标题行高度（12sp 文本 + 4dp 间距）
    private const val VERTICAL_PADDING_DP = 15f
    private const val HEADER_DP = 20f

    // 行高由权重均分，这里只用来估算能放几行，避免行被压得过矮
    // 双行内容（剧名 + 单集副标题）最低约 27dp
    private const val MIN_ROW_DP = 28f
    private const val POSTER_WIDTH_DP = 21f

    // 低于该宽度（dp）时隐藏海报与标题旁的统计副标题，保证剧名可读
    private const val POSTER_MIN_WIDTH_DP = 200f
    private const val SUBTITLE_MIN_WIDTH_DP = 150f

    // 窄宽度（约 2 列，如 2x2）走紧凑行：隐藏单集副标题，单行只留剧名 + 日期
    private const val COMPACT_MAX_WIDTH_DP = 170f
    private const val COMPACT_ROW_DP = 26f

    // 形态阈值：1 格高走横条，其余一律走列表（2x2 也显示剧集列表）
    // ColorOS 单格高约 84dp，AOSP 约 40-64dp
    private const val BAR_MAX_HEIGHT_DP = 96f

    private const val DEFAULT_WIDTH_DP = 250f
    private const val DEFAULT_HEIGHT_DP = 110f

    internal val providerClasses: List<Class<out AppWidgetProvider>> = listOf(
        SubscribeCalendarWidgetProvider::class.java,
        SubscribeCalendarWidgetSmallProvider::class.java,
        SubscribeCalendarWidgetTallProvider::class.java,
        SubscribeCalendarWidgetLargeProvider::class.java,
        SubscribeCalendarWidgetBarProvider::class.java,
    )

    /** 刷新全部尺寸档位的小组件（后台刷新、日期变化时用）。 */
    fun renderAll(context: Context) {
        val state = loadState(context)
        providerClasses.forEach { providerClass ->
            renderProvider(context, providerClass, state)
        }
    }

    /** 只刷新某个 Provider 自己的实例，避免系统广播时重复渲染所有档位。 */
    fun renderProvider(context: Context, providerClass: Class<out AppWidgetProvider>) {
        renderProvider(context, providerClass, loadState(context))
    }

    private fun renderProvider(
        context: Context,
        providerClass: Class<out AppWidgetProvider>,
        state: WidgetState,
    ) {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, providerClass)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return
        ids.forEach { renderWidget(context, manager, it, state) }
    }

    private fun renderWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        state: WidgetState,
    ) {
        val options = manager.getAppWidgetOptions(widgetId)
        val widthDp = widthDp(context, options)
        val heightDp = heightDp(context, options)
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            Log.d(
                TAG,
                "widget=$widgetId size=${widthDp}x${heightDp}dp " +
                    "options=${options.keySet().joinToString { "$it=${options.get(it)}" }}",
            )
        }

        val views = when {
            heightDp < BAR_MAX_HEIGHT_DP -> buildBar(context, state)
            else -> buildList(context, state, widthDp, heightDp)
        }
        views.setOnClickPendingIntent(R.id.widget_root, contentIntent(context))
        manager.updateAppWidget(widgetId, views)
    }

    /** 4x1 横条：一行摘要，最适合极扁的格子。 */
    private fun buildBar(context: Context, state: WidgetState): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.subscribe_calendar_widget_bar)
        val nearest = state.items.firstOrNull()
        val summary = if (nearest == null) {
            state.emptyMessage ?: context.getString(R.string.widget_subscribe_calendar_empty)
        } else {
            context.getString(
                R.string.widget_subscribe_calendar_bar_summary,
                state.items.size,
                nearestLabel(context, nearest),
            )
        }
        views.setTextViewText(
            R.id.widget_bar_summary,
            if (state.stale && nearest != null) {
                summary + " · " + context.getString(R.string.widget_subscribe_calendar_offline)
            } else {
                summary
            },
        )
        return views
    }

    /** 列表形态：行高由 LinearLayout 权重均分，任意高度都不会溢出被裁。 */
    private fun buildList(
        context: Context,
        state: WidgetState,
        widthDp: Float,
        heightDp: Float,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.subscribe_calendar_widget)
        val hasItems = state.items.isNotEmpty()

        views.setViewVisibility(R.id.calendar_rows, if (hasItems) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_empty, if (hasItems) View.GONE else View.VISIBLE)
        if (hasItems) {
            val subtitle = context.getString(
                R.string.widget_subscribe_calendar_count,
                state.items.size,
            )
            views.setTextViewText(
                R.id.widget_subtitle,
                if (state.stale) {
                    subtitle + " · " + context.getString(R.string.widget_subscribe_calendar_offline)
                } else {
                    subtitle
                },
            )
        } else {
            views.setTextViewText(
                R.id.widget_subtitle,
                context.getString(R.string.widget_subscribe_calendar_subtitle),
            )
            views.setTextViewText(
                R.id.widget_empty,
                state.emptyMessage
                    ?: context.getString(R.string.widget_subscribe_calendar_empty),
            )
        }

        views.removeAllViews(R.id.calendar_rows)
        val showPoster = widthDp >= POSTER_MIN_WIDTH_DP
        val compact = widthDp < COMPACT_MAX_WIDTH_DP
        val rows = rowCount(heightDp, compact)
        state.items.take(rows).forEach { episode ->
            views.addView(R.id.calendar_rows, buildRow(context, episode, showPoster, compact))
        }
        views.setViewVisibility(
            R.id.widget_subtitle,
            if (widthDp >= SUBTITLE_MIN_WIDTH_DP) View.VISIBLE else View.GONE,
        )
        return views
    }

    private fun buildRow(
        context: Context,
        episode: CalendarEpisode,
        showPoster: Boolean,
        compact: Boolean,
    ): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.subscribe_calendar_widget_row)
        val daysAway = daysAway(episode)

        row.setTextViewText(R.id.row_date, badgeText(context, episode, daysAway))
        row.setInt(R.id.row_date, "setBackgroundResource", badgeBackground(daysAway))
        row.setTextColor(R.id.row_date, badgeColor(daysAway))
        row.setTextViewText(R.id.row_title, episode.showName)
        row.setTextViewText(R.id.row_subtitle, episodeSubtitle(episode))
        row.setViewVisibility(
            R.id.row_subtitle,
            if (compact) View.GONE else View.VISIBLE,
        )
        if (showPoster) {
            bindPoster(context, row, episode)
        } else {
            row.setViewVisibility(R.id.row_poster, View.GONE)
        }
        return row
    }

    /** 只读本地已缓存的海报；没有素材时保留占位底色，行内容照常可读。 */
    private fun bindPoster(context: Context, row: RemoteViews, episode: CalendarEpisode) {
        val poster = if (episode.posterUrl.isEmpty()) {
            null
        } else {
            val widthPx = (POSTER_WIDTH_DP * context.resources.displayMetrics.density).toInt()
            WidgetPosterCache.loadBitmap(context, episode.posterUrl, widthPx * 2)
        }
        if (poster != null) {
            row.setImageViewBitmap(R.id.row_poster, poster)
        } else {
            row.setImageViewResource(R.id.row_poster, R.drawable.widget_poster_placeholder)
        }
    }

    private fun parseDate(episode: CalendarEpisode): LocalDate? =
        runCatching { LocalDate.parse(episode.date) }.getOrNull()

    private fun daysAway(episode: CalendarEpisode): Long? {
        val date = parseDate(episode) ?: return null
        return ChronoUnit.DAYS.between(LocalDate.now(ZoneOffset.UTC), date)
    }

    private fun badgeText(context: Context, episode: CalendarEpisode, daysAway: Long?): String =
        when {
            daysAway == null -> context.getString(R.string.widget_subscribe_calendar_undated)
            daysAway <= 0L -> context.getString(R.string.widget_subscribe_calendar_today)
            daysAway == 1L -> context.getString(R.string.widget_subscribe_calendar_tomorrow)
            else -> parseDate(episode)?.format(
                DateTimeFormatter.ofPattern("MM-dd", Locale.getDefault()),
            ) ?: context.getString(R.string.widget_subscribe_calendar_undated)
        }

    private fun badgeBackground(daysAway: Long?): Int = when {
        daysAway != null && daysAway <= 0L -> R.drawable.widget_date_badge_today
        daysAway == 1L -> R.drawable.widget_date_badge_tomorrow
        else -> R.drawable.widget_date_badge_default
    }

    private fun badgeColor(daysAway: Long?): Int = when {
        daysAway != null && daysAway <= 0L -> 0xFF4ADE80.toInt()
        daysAway == 1L -> 0xFF_FBBF24.toInt()
        else -> 0xFF7DD3FC.toInt()
    }

    /** 小卡/横条里的“剧名 · 今天”摘要。 */
    private fun nearestLabel(context: Context, episode: CalendarEpisode): String =
        episode.showName + " · " + badgeText(context, episode, daysAway(episode))

    private fun episodeSubtitle(episode: CalendarEpisode): String {
        val prefix = if (episode.episodeNumber > 0) {
            String.format(Locale.US, "S%02dE%02d", episode.seasonNumber, episode.episodeNumber)
        } else {
            String.format(Locale.US, "S%02d", episode.seasonNumber)
        }
        val title = episode.episodeTitle.trim()
        return if (title.isEmpty()) prefix else "$prefix · $title"
    }

    /**
     * 能放下的行数。行高最终由权重均分，这里按最小行高估算，
     * 既避免行被压扁，也不会因为估多了把内容顶出边界。
     * 紧凑行（窄宽度、单行文本）按更小的行高估算，2x2 也能多放几条。
     */
    private fun rowCount(heightDp: Float, compact: Boolean = false): Int {
        val minRow = if (compact) COMPACT_ROW_DP else MIN_ROW_DP
        val available = (heightDp - VERTICAL_PADDING_DP - HEADER_DP).coerceAtLeast(minRow)
        return (available / minRow).toInt().coerceIn(1, MAX_ROWS)
    }

    private fun heightDp(context: Context, options: Bundle): Float {
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0).toFloat()
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0).toFloat()
        // min/max 是横竖屏两个方向的高度边界：竖屏用 minHeight，横屏用 maxHeight
        val landscape =
            context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        return when {
            landscape && maxHeight > 0f -> maxHeight
            !landscape && minHeight > 0f -> minHeight
            maxHeight > 0f -> maxHeight
            minHeight > 0f -> minHeight
            else -> DEFAULT_HEIGHT_DP
        }
    }

    /** 当前显示宽度（dp），与 heightDp 同理：竖屏取较小值，横屏取较大值。 */
    private fun widthDp(context: Context, options: Bundle): Float {
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0).toFloat()
        val maxWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0).toFloat()
        val landscape =
            context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        return when {
            landscape && maxWidth > 0f -> maxWidth
            !landscape && minWidth > 0f -> minWidth
            maxWidth > 0f -> maxWidth
            minWidth > 0f -> minWidth
            else -> DEFAULT_WIDTH_DP
        }
    }

    private fun loadState(context: Context): WidgetState {
        val session = WidgetSessionStore.loadSession(context)
        val cache = WidgetSessionStore.loadCache(context)
        val hasError = WidgetSessionStore.hasLastError(context)
        return when {
            session == null -> WidgetState(
                emptyMessage = context.getString(R.string.widget_subscribe_calendar_login_required),
                items = emptyList(),
                stale = false,
            )
            cache == null && hasError -> WidgetState(
                emptyMessage = context.getString(R.string.widget_subscribe_calendar_error),
                items = emptyList(),
                stale = true,
            )
            cache == null -> WidgetState(
                emptyMessage = context.getString(R.string.widget_subscribe_calendar_loading),
                items = emptyList(),
                stale = false,
            )
            else -> WidgetState(
                emptyMessage = null,
                items = SubscribeCalendarCodec.decode(cache.payload),
                stale = hasError,
            )
        }
    }

    private fun contentIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(DEEP_LINK)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private data class WidgetState(
        val emptyMessage: String?,
        val items: List<CalendarEpisode>,
        val stale: Boolean,
    )
}

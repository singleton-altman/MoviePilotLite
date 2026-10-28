package com.example.moviepilot_mobile.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Bundle
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
    private const val DEEP_LINK = "moviepilot://subscribe-calendar"
    private const val MAX_ROWS = 6
    private const val FIXED_CHROME_DP = 42f
    private const val ROW_HEIGHT_DP = 40f

    fun renderAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, SubscribeCalendarWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return

        val session = WidgetSessionStore.loadSession(context)
        val cache = WidgetSessionStore.loadCache(context)
        val hasError = WidgetSessionStore.hasLastError(context)
        val state = when {
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

        ids.forEach { renderWidget(context, manager, it, state) }
    }

    private fun renderWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        state: WidgetState,
    ) {
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
        val maxRows = maxRows(context, manager.getAppWidgetOptions(widgetId))
        state.items.take(maxRows).forEach { episode ->
            views.addView(R.id.calendar_rows, buildRow(context, episode))
        }

        views.setOnClickPendingIntent(R.id.widget_root, contentIntent(context))
        manager.updateAppWidget(widgetId, views)
    }

    private fun buildRow(context: Context, episode: CalendarEpisode): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.subscribe_calendar_widget_row)
        val today = LocalDate.now(ZoneOffset.UTC)
        val date = runCatching { LocalDate.parse(episode.date) }.getOrNull()
        val daysAway = date?.let { ChronoUnit.DAYS.between(today, it) }

        val badgeText = when {
            date == null -> context.getString(R.string.widget_subscribe_calendar_undated)
            daysAway != null && daysAway <= 0L ->
                context.getString(R.string.widget_subscribe_calendar_today)
            daysAway == 1L -> context.getString(R.string.widget_subscribe_calendar_tomorrow)
            else -> date.format(DateTimeFormatter.ofPattern("MM-dd", Locale.getDefault()))
        }
        val badgeBackground = when {
            daysAway != null && daysAway <= 0L -> R.drawable.widget_date_badge_today
            daysAway == 1L -> R.drawable.widget_date_badge_tomorrow
            else -> R.drawable.widget_date_badge_default
        }
        val countdown = when {
            date == null -> ""
            daysAway != null && daysAway <= 0L ->
                context.getString(R.string.widget_subscribe_calendar_today)
            daysAway == 1L -> context.getString(R.string.widget_subscribe_calendar_tomorrow)
            daysAway != null ->
                context.getString(R.string.widget_subscribe_calendar_days_away, daysAway)
            else -> ""
        }

        row.setTextViewText(R.id.row_date, badgeText)
        row.setInt(R.id.row_date, "setBackgroundResource", badgeBackground)
        row.setTextViewText(R.id.row_title, episode.showName)
        row.setTextViewText(R.id.row_subtitle, episodeSubtitle(episode))
        row.setTextViewText(R.id.row_countdown, countdown)
        row.setTextColor(
            R.id.row_countdown,
            if (daysAway != null && daysAway <= 1L) 0xFF4ADE80.toInt() else 0xFF7DD3FC.toInt(),
        )
        return row
    }

    private fun episodeSubtitle(episode: CalendarEpisode): String {
        val prefix = if (episode.episodeNumber > 0) {
            String.format(Locale.US, "S%02dE%02d", episode.seasonNumber, episode.episodeNumber)
        } else {
            String.format(Locale.US, "S%02d", episode.seasonNumber)
        }
        val title = episode.episodeTitle.trim()
        return if (title.isEmpty()) prefix else "$prefix · $title"
    }

    private fun maxRows(context: Context, options: Bundle): Int {
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0).toFloat()
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0).toFloat()
        // min/max 是横竖屏两个方向上的高度边界：竖屏取较高值，横屏取较低值
        val landscape =
            context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val heightDp = when {
            landscape && minHeight > 0f -> minHeight
            !landscape && maxHeight > 0f -> maxHeight
            minHeight > 0f -> minHeight
            else -> 130f
        }
        val available = heightDp - FIXED_CHROME_DP
        return (available / ROW_HEIGHT_DP).toInt().coerceIn(1, MAX_ROWS)
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

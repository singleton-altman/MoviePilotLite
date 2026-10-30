package com.example.moviepilot_mobile.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * 订阅日历桌面小组件。系统触发的更新只做本地渲染 + 排一次后台刷新，
 * 不在广播回调里做网络请求，避免 ANR。
 */
class SubscribeCalendarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        SubscribeCalendarWidgetRenderer.renderAll(context)
        SubscribeCalendarRefreshScheduler.ensurePeriodic(context)
        SubscribeCalendarRefreshScheduler.requestImmediateRefresh(context)
    }

    override fun onEnabled(context: Context) {
        SubscribeCalendarRefreshScheduler.ensurePeriodic(context)
        SubscribeCalendarRefreshScheduler.requestImmediateRefresh(context)
    }

    override fun onDisabled(context: Context) {
        SubscribeCalendarRefreshScheduler.cancel(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        SubscribeCalendarWidgetRenderer.renderAll(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                SubscribeCalendarWidgetRenderer.renderAll(context)
                SubscribeCalendarRefreshScheduler.requestImmediateRefresh(context)
            }
        }
    }
}

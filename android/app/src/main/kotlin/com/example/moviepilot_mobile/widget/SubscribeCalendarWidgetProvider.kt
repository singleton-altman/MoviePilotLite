package com.example.moviepilot_mobile.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * 订阅日历桌面小组件。系统触发的更新只做本地渲染 + 排一次后台刷新，
 * 不在广播回调里做网络请求，避免 ANR。
 *
 * 子类只用来给选择器提供不同的默认格数，渲染逻辑完全共用。
 */
open class SubscribeCalendarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        SubscribeCalendarWidgetRenderer.renderProvider(context, this.javaClass)
        SubscribeCalendarRefreshScheduler.ensurePeriodic(context)
        SubscribeCalendarRefreshScheduler.requestImmediateRefresh(context)
    }

    override fun onEnabled(context: Context) {
        SubscribeCalendarRefreshScheduler.ensurePeriodic(context)
        SubscribeCalendarRefreshScheduler.requestImmediateRefresh(context)
    }

    override fun onDisabled(context: Context) {
        // 只有最后一档小组件被移除时才取消后台刷新
        if (!SubscribeCalendarRefreshScheduler.hasWidgets(context)) {
            SubscribeCalendarRefreshScheduler.cancel(context)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        SubscribeCalendarWidgetRenderer.renderProvider(context, this.javaClass)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            // 只有基类声明了这些系统广播，收到时统一重绘所有尺寸档位
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                SubscribeCalendarWidgetRenderer.renderAll(context)
                SubscribeCalendarRefreshScheduler.requestImmediateRefresh(context)
            }
        }
    }
}

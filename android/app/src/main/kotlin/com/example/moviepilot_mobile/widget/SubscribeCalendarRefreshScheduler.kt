package com.example.moviepilot_mobile.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * 小组件刷新调度：系统周期性唤醒之外，登录、回到 App、日期变化时立即拉一次。
 */
internal object SubscribeCalendarRefreshScheduler {
    private const val PERIODIC_WORK_NAME = "subscribe_calendar_periodic"
    private const val IMMEDIATE_WORK_NAME = "subscribe_calendar_immediate"
    private const val REFRESH_INTERVAL_HOURS = 6L

    fun hasWidgets(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, SubscribeCalendarWidgetProvider::class.java)
        return manager.getAppWidgetIds(component).isNotEmpty()
    }

    fun ensurePeriodic(context: Context) {
        if (!hasWidgets(context)) return
        val request = PeriodicWorkRequestBuilder<SubscribeCalendarRefreshWorker>(
            REFRESH_INTERVAL_HOURS,
            TimeUnit.HOURS,
        )
            .setConstraints(networkConstraints())
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            PERIODIC_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun requestImmediateRefresh(context: Context) {
        if (!hasWidgets(context)) return
        val request = OneTimeWorkRequestBuilder<SubscribeCalendarRefreshWorker>()
            .setConstraints(networkConstraints())
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            IMMEDIATE_WORK_NAME,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(IMMEDIATE_WORK_NAME)
        WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_WORK_NAME)
    }

    private fun networkConstraints(): Constraints =
        Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
}

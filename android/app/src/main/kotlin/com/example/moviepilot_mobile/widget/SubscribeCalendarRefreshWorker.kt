package com.example.moviepilot_mobile.widget

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * 后台拉取订阅日历并刷新全部小组件实例。
 *
 * 拉取失败时保留旧缓存（渲染层会标注离线），并按 WorkManager 退避重试，
 * 连续失败两次后放弃，等待下一次周期任务或 App 主动触发。
 */
class SubscribeCalendarRefreshWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {

    override fun doWork(): Result {
        val context = applicationContext
        if (!SubscribeCalendarRefreshScheduler.hasWidgets(context)) return Result.success()

        val session = WidgetSessionStore.loadSession(context)
        if (session == null) {
            WidgetSessionStore.setLastError(context, false)
            SubscribeCalendarWidgetRenderer.renderAll(context)
            return Result.success()
        }

        return try {
            val items = SubscribeCalendarService().fetch(session.server, session.accessToken)
            WidgetSessionStore.saveCache(
                context = context,
                payload = SubscribeCalendarCodec.encode(items),
                cachedAt = System.currentTimeMillis(),
            )
            WidgetSessionStore.setLastError(context, false)
            SubscribeCalendarWidgetRenderer.renderAll(context)
            Result.success()
        } catch (_: Exception) {
            WidgetSessionStore.setLastError(context, true)
            SubscribeCalendarWidgetRenderer.renderAll(context)
            if (runAttemptCount < MAX_ATTEMPTS) Result.retry() else Result.success()
        }
    }

    private companion object {
        const val MAX_ATTEMPTS = 2
    }
}

package com.byteflow.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import com.byteflow.MainActivity
import com.byteflow.R

/**
 * Material 3 Home Screen AppWidget provider presenting real-time carrier,
 * daily cellular usage, quota progress bar, and Wi-Fi data totals.
 */
class ByteFlowWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREF_NAME = "byteflow_widget_prefs"
        const val KEY_CARRIER = "widget_carrier"
        const val KEY_SIM_BADGE = "widget_sim_badge"
        const val KEY_MOBILE_BYTES = "widget_mobile_bytes"
        const val KEY_WIFI_BYTES = "widget_wifi_bytes"
        const val KEY_QUOTA_BYTES = "widget_quota_bytes"
        const val KEY_QUOTA_TEXT = "widget_quota_text"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, ByteFlowWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                val intent = Intent(context, ByteFlowWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                }
                context.sendBroadcast(intent)
            }
        }

        fun saveAndRefresh(
            context: Context,
            carrier: String,
            simBadge: String,
            mobileBytes: Long,
            wifiBytes: Long,
            quotaBytes: Long,
            quotaText: String
        ) {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString(KEY_CARRIER, carrier)
                putString(KEY_SIM_BADGE, simBadge)
                putLong(KEY_MOBILE_BYTES, mobileBytes)
                putLong(KEY_WIFI_BYTES, wifiBytes)
                putLong(KEY_QUOTA_BYTES, quotaBytes)
                putString(KEY_QUOTA_TEXT, quotaText)
                apply()
            }
            updateAllWidgets(context)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val carrier = prefs.getString(KEY_CARRIER, context.getString(R.string.widget_default_carrier))
            ?: context.getString(R.string.widget_default_carrier)
        val simBadge = prefs.getString(KEY_SIM_BADGE, "SIM 1") ?: "SIM 1"
        val mobileBytes = prefs.getLong(KEY_MOBILE_BYTES, 0L)
        val wifiBytes = prefs.getLong(KEY_WIFI_BYTES, 0L)
        val quotaBytes = prefs.getLong(KEY_QUOTA_BYTES, 0L)
        val quotaText = prefs.getString(KEY_QUOTA_TEXT, context.getString(R.string.widget_quota_default))
            ?: context.getString(R.string.widget_quota_default)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_byteflow)

            // 1. Header
            views.setTextViewText(R.id.widget_carrier, carrier)
            views.setTextViewText(R.id.widget_sim_badge, simBadge)

            // 2. Mobile usage & quota bar
            views.setTextViewText(R.id.widget_mobile_used, formatBytes(mobileBytes))
            if (quotaBytes > 0) {
                val percent = ((mobileBytes.toDouble() / quotaBytes.toDouble()) * 100).toInt().coerceIn(0, 100)
                views.setProgressBar(R.id.widget_progress_bar, 100, percent, false)
                views.setTextViewText(R.id.widget_quota_text, quotaText)
            } else {
                views.setProgressBar(R.id.widget_progress_bar, 100, 0, false)
                views.setTextViewText(R.id.widget_quota_text, quotaText)
            }

            // 3. Wi-Fi usage
            views.setTextViewText(R.id.widget_wifi_used, "Wi-Fi: ${formatBytes(wifiBytes)}")

            // 4. Click Intent launching MainActivity
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(context, appWidgetId, launchIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun formatBytes(bytes: Long): String {
        return when {
            bytes >= 1024L * 1024 * 1024 * 1024 -> String.format("%.2f TB", bytes / (1024.0 * 1024 * 1024 * 1024))
            bytes >= 1024L * 1024 * 1024 -> String.format("%.2f GB", bytes / (1024.0 * 1024 * 1024))
            bytes >= 1024L * 1024 -> String.format("%.1f MB", bytes / (1024.0 * 1024))
            bytes >= 1024L -> String.format("%d KB", bytes / 1024)
            else -> "$bytes B"
        }
    }
}

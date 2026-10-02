package com.byteflow.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.byteflow.widget.ByteFlowWidgetProvider

/**
 * BroadcastReceiver triggered on system boot (BOOT_COMPLETED / QUICKBOOT_POWERON).
 * Restores LiveSpeedService if user previously enabled it and refreshes AppWidgets.
 */
class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON") {

            // 1. Refresh Home Screen AppWidgets
            ByteFlowWidgetProvider.updateAllWidgets(context)

            // 2. Check if LiveSpeedService was enabled in SharedPreferences
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isLiveSpeedEnabled = flutterPrefs.getBoolean("flutter.byteflow_live_speed_enabled", false)
            val intervalMs = try {
                flutterPrefs.getLong("flutter.byteflow_live_speed_interval_ms", 1000L)
            } catch (e: Exception) {
                1000L
            }

            if (isLiveSpeedEnabled) {
                LiveSpeedService.start(context, intervalMs)
            }
        }
    }
}

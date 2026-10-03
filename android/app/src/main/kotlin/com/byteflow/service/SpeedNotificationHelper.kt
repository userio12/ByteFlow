package com.byteflow.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.byteflow.MainActivity
import com.byteflow.R
import kotlin.math.sqrt

/**
 * Builds and updates modern Material 3 ongoing status bar notifications for real-time throughput.
 * Features:
 * - Dynamic 2-tier numeric status bar speed icon (e.g. "14M", "250K")
 * - Collapsed RemoteViews with fixed-width tabular download/upload speed pills
 * - Expanded RemoteViews with dual throughput cards, mini activity meters, quota progress, and quick action buttons
 * - Dynamic bits (bps) vs bytes (B/s) unit formatting
 */
object SpeedNotificationHelper {
    const val CHANNEL_ID = "byteflow_live_speed"
    const val NOTIFICATION_ID = 1001

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = context.getString(R.string.speed_channel_name)
            val desc = context.getString(R.string.speed_channel_desc)
            // IMPORTANCE_DEFAULT prevents Android 12+ from classifying the speed meter
            // as 'Silent' and hiding the status bar icon or minimizing it to the bottom.
            val importance = NotificationManager.IMPORTANCE_DEFAULT

            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = desc
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }

            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    fun buildNotification(
        context: Context,
        downloadBps: Long,
        uploadBps: Long,
        todayMobileBytes: Long = 0L,
        todayWifiBytes: Long = 0L,
        carrierName: String? = null,
        networkType: String = "Wi-Fi",
        quotaBytes: Long = 0L,
        isPaused: Boolean = false,
        useBits: Boolean = false,
        useDynamicIcon: Boolean = true
    ): Notification {
        val totalBps = (downloadBps + uploadBps).coerceAtLeast(0L)

        // 1. PendingIntent to launch ByteFlow Main App
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, piFlags)

        // 2. Formatted Speed Strings
        val dlSpeedStr = formatSpeed(downloadBps, useBits)
        val ulSpeedStr = formatSpeed(uploadBps, useBits)
        val speedTitle = "↓ $dlSpeedStr   ↑ $ulSpeedStr"
        val todayStr = "Today: ${formatBytes(todayMobileBytes)} Cell • ${formatBytes(todayWifiBytes)} Wi-Fi"

        // 3. Collapsed RemoteViews (64dp)
        val viewsCollapsed = RemoteViews(context.packageName, R.layout.notification_speed_collapsed).apply {
            setTextViewText(R.id.notif_collapsed_download, dlSpeedStr)
            setTextViewText(R.id.notif_collapsed_upload, ulSpeedStr)
            setTextViewText(R.id.notif_collapsed_today, "Today: ${formatBytes(todayMobileBytes + todayWifiBytes)}")
        }

        // 4. Expanded RemoteViews (Material 3 Card)
        val viewsExpanded = RemoteViews(context.packageName, R.layout.notification_speed_expanded).apply {
            // Header
            setTextViewText(R.id.notif_live_status, if (isPaused) "● Paused" else "● Live")
            val statusColor = if (isPaused) {
                ContextCompat.getColor(context, R.color.notif_text_secondary)
            } else {
                ContextCompat.getColor(context, R.color.notif_accent_green)
            }
            setTextColor(R.id.notif_live_status, statusColor)

            val badgeText = if (!carrierName.isNullOrEmpty()) carrierName else networkType
            setTextViewText(R.id.notif_network_badge, badgeText)

            // Speeds
            setTextViewText(R.id.notif_expanded_download, dlSpeedStr)
            setTextViewText(R.id.notif_expanded_upload, ulSpeedStr)

            // Mini throughput activity indicators (dynamic curve up to 50 MB/s for responsive visual feedback)
            val dlPercent = calculateThroughputPercent(downloadBps)
            val ulPercent = calculateThroughputPercent(uploadBps)
            setProgressBar(R.id.notif_download_bar, 100, dlPercent, false)
            setProgressBar(R.id.notif_upload_bar, 100, ulPercent, false)

            // Today's Usage Breakdown
            if (quotaBytes > 0) {
                val percent = ((todayMobileBytes.toDouble() / quotaBytes.toDouble()) * 100).toInt().coerceIn(0, 100)
                setTextViewText(R.id.notif_quota_percent, "$percent%")
                setProgressBar(R.id.notif_quota_bar, 100, percent, false)
                setTextViewText(
                    R.id.notif_today_details,
                    "Cell: ${formatBytes(todayMobileBytes)} / ${formatBytes(quotaBytes)} • Wi-Fi: ${formatBytes(todayWifiBytes)}"
                )
            } else {
                setTextViewText(R.id.notif_quota_percent, "Active")
                setProgressBar(R.id.notif_quota_bar, 100, 0, false)
                setTextViewText(
                    R.id.notif_today_details,
                    "Cell: ${formatBytes(todayMobileBytes)} • Wi-Fi: ${formatBytes(todayWifiBytes)}"
                )
            }

            // Quick Action 1: Open Dashboard
            val dashboardIntent = Intent(context, MainActivity::class.java).apply {
                this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "dashboard")
            }
            val piDashboard = PendingIntent.getActivity(context, 101, dashboardIntent, piFlags)
            setOnClickPendingIntent(R.id.notif_btn_dashboard, piDashboard)

            // Quick Action 2: Open Data Plan
            val planIntent = Intent(context, MainActivity::class.java).apply {
                this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "plan")
            }
            val piPlan = PendingIntent.getActivity(context, 102, planIntent, piFlags)
            setOnClickPendingIntent(R.id.notif_btn_plan, piPlan)

            // Quick Action 3: Pause / Resume sampling
            // Using separate request codes (103 for pause, 104 for resume) ensures FLAG_IMMUTABLE
            // does not prevent the intent action from switching properly.
            val actionIntent = Intent(context, SpeedActionReceiver::class.java).apply {
                action = if (isPaused) SpeedActionReceiver.ACTION_RESUME_SPEED else SpeedActionReceiver.ACTION_PAUSE_SPEED
            }
            val actionRequestCode = if (isPaused) 104 else 103
            val piAction = PendingIntent.getBroadcast(context, actionRequestCode, actionIntent, piFlags)
            setTextViewText(R.id.notif_btn_pause, if (isPaused) "▶ Resume" else "⏸ Pause")
            setOnClickPendingIntent(R.id.notif_btn_pause, piAction)
        }

        // 5. Construct NotificationCompat.Builder
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(speedTitle)
            .setContentText(todayStr)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(viewsCollapsed)
            .setCustomBigContentView(viewsExpanded)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        }

        // 6. Status Bar Small Icon & Dynamic Large Icon
        // Small icon MUST be a static drawable resource (TYPE_RESOURCE) for Android & Samsung One UI status bar compatibility.
        builder.setSmallIcon(R.drawable.ic_stat_speed)

        if (useDynamicIcon) {
            try {
                val speedBitmap = SpeedIconGenerator.getSpeedBitmap(totalBps, useBits)
                builder.setLargeIcon(speedBitmap)
            } catch (_: Exception) {
                // Fallback gracefully without large icon
            }
        }

        if (!carrierName.isNullOrEmpty()) {
            builder.setSubText(carrierName)
        }

        return builder.build()
    }

    /**
     * Calculates responsive visual activity percentage (0-100) using a dynamic curve
     * so that low/medium speeds (e.g. 500 KB/s - 10 MB/s) produce visible indicator activity.
     */
    private fun calculateThroughputPercent(bytesPerSec: Long): Int {
        if (bytesPerSec <= 0) return 0
        val maxTargetBps = 50.0 * 1024.0 * 1024.0 // 50 MB/s full scale
        val ratio = (bytesPerSec.toDouble() / maxTargetBps).coerceIn(0.0, 1.0)
        return (sqrt(ratio) * 100).toInt().coerceIn(1, 100)
    }

    fun formatSpeed(bytesPerSec: Long, useBits: Boolean = false): String {
        if (bytesPerSec <= 0) {
            return if (useBits) "0 b/s" else "0 B/s"
        }

        return if (useBits) {
            val bits = (bytesPerSec * 8).toDouble()
            when {
                bits >= 1_000_000_000.0 -> String.format("%.1f Gbps", bits / 1_000_000_000.0)
                bits >= 1_000_000.0 -> String.format("%.1f Mbps", bits / 1_000_000.0)
                bits >= 1_000.0 -> String.format("%d Kbps", (bits / 1_000.0).toLong())
                else -> "${bits.toLong()} bps"
            }
        } else {
            when {
                bytesPerSec >= 1024L * 1024 * 1024 -> String.format("%.2f GB/s", bytesPerSec / (1024.0 * 1024 * 1024))
                bytesPerSec >= 1024L * 1024 -> String.format("%.1f MB/s", bytesPerSec / (1024.0 * 1024))
                bytesPerSec >= 1024L -> String.format("%d KB/s", bytesPerSec / 1024)
                else -> "$bytesPerSec B/s"
            }
        }
    }

    fun formatBytes(bytes: Long): String {
        return when {
            bytes >= 1024L * 1024 * 1024 * 1024 -> String.format("%.2f TB", bytes / (1024.0 * 1024 * 1024 * 1024))
            bytes >= 1024L * 1024 * 1024 -> String.format("%.2f GB", bytes / (1024.0 * 1024 * 1024))
            bytes >= 1024L * 1024 -> String.format("%.1f MB", bytes / (1024.0 * 1024))
            bytes >= 1024L -> String.format("%d KB", bytes / 1024)
            else -> "$bytes B"
        }
    }
}

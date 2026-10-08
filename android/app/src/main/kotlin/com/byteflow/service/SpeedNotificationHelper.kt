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

        // 2. Formatted Speed and Traffic Strings
        val dlSpeedStr = formatSpeed(downloadBps, useBits)
        val ulSpeedStr = formatSpeed(uploadBps, useBits)
        val (dlVal, dlUnit) = splitSpeed(downloadBps, useBits)
        val speedsLine = "Down: $dlSpeedStr   Up: $ulSpeedStr"
        val trafficLine = "Mobile: ${formatBytes(todayMobileBytes)}   WiFi: ${formatBytes(todayWifiBytes)}"

        // 3. Collapsed RemoteViews (Samsung One UI compact card)
        val viewsCollapsed = RemoteViews(context.packageName, R.layout.notification_speed_collapsed).apply {
            setTextViewText(R.id.notif_speed_val, dlVal)
            setTextViewText(R.id.notif_speed_unit, dlUnit)
            setTextViewText(R.id.notif_line_speeds, speedsLine)
            setTextViewText(R.id.notif_line_traffic, trafficLine)
        }

        // 4. Expanded RemoteViews (Samsung One UI expanded card with header)
        val viewsExpanded = RemoteViews(context.packageName, R.layout.notification_speed_expanded).apply {
            setTextViewText(R.id.notif_expanded_speed_val, dlVal)
            setTextViewText(R.id.notif_expanded_speed_unit, dlUnit)
            setTextViewText(R.id.notif_expanded_line_speeds, speedsLine)
            setTextViewText(R.id.notif_expanded_line_traffic, trafficLine)
        }

        // 5. Construct NotificationCompat.Builder
        // Omit DecoratedCustomViewStyle to prevent Android 12+ SystemUI from injecting a decorated header row in collapsed view
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_speed)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setCustomContentView(viewsCollapsed)
            .setCustomBigContentView(viewsExpanded)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        }

        return builder.build()
    }

    /**
     * Splits [bytesPerSec] into a (numeric value, unit) pair for the left indicator.
     */
    fun splitSpeed(bytesPerSec: Long, useBits: Boolean = false): Pair<String, String> {
        if (bytesPerSec <= 0) {
            return Pair("0", if (useBits) "Kbps" else "KB/s")
        }

        return if (useBits) {
            val bits = (bytesPerSec * 8).toDouble()
            when {
                bits >= 1_000_000_000.0 -> Pair(String.format("%.1f", bits / 1_000_000_000.0), "Gbps")
                bits >= 1_000_000.0 -> Pair(String.format("%.1f", bits / 1_000_000.0), "Mbps")
                bits >= 1_000.0 -> Pair(String.format("%d", (bits / 1_000.0).toLong()), "Kbps")
                else -> Pair(bits.toLong().toString(), "bps")
            }
        } else {
            when {
                bytesPerSec >= 1024L * 1024 * 1024 -> Pair(String.format("%.2f", bytesPerSec / (1024.0 * 1024 * 1024)), "GB/s")
                bytesPerSec >= 1024L * 1024 -> Pair(String.format("%.1f", bytesPerSec / (1024.0 * 1024)), "MB/s")
                bytesPerSec >= 1024L -> Pair(String.format("%d", bytesPerSec / 1024), "KB/s")
                else -> Pair(bytesPerSec.toString(), "B/s")
            }
        }
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

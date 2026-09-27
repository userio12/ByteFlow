package com.byteflow.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.byteflow.MainActivity
import com.byteflow.R

/**
 * Builds and updates ongoing silent status bar notifications for real-time throughput.
 */
object SpeedNotificationHelper {
    const val CHANNEL_ID = "byteflow_live_speed"
    const val NOTIFICATION_ID = 1001

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = context.getString(R.string.speed_channel_name)
            val desc = context.getString(R.string.speed_channel_desc)
            val importance = NotificationManager.IMPORTANCE_LOW

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
        carrierName: String? = null
    ): Notification {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, flags)

        val speedTitle = "↓ ${formatSpeed(downloadBps)}   ↑ ${formatSpeed(uploadBps)}"
        val contentText = if (todayMobileBytes > 0 || todayWifiBytes > 0) {
            "Today: ${formatBytes(todayMobileBytes)} Cell • ${formatBytes(todayWifiBytes)} Wi-Fi"
        } else {
            "ByteFlow Live Throughput Active"
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(speedTitle)
            .setContentText(contentText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (!carrierName.isNullOrEmpty()) {
            builder.setSubText(carrierName)
        }

        return builder.build()
    }

    private fun formatSpeed(bytesPerSec: Long): String {
        return when {
            bytesPerSec >= 1024 * 1024 * 1024 -> String.format("%.2f GB/s", bytesPerSec / (1024.0 * 1024 * 1024))
            bytesPerSec >= 1024 * 1024 -> String.format("%.1f MB/s", bytesPerSec / (1024.0 * 1024))
            bytesPerSec >= 1024 -> String.format("%d KB/s", bytesPerSec / 1024)
            else -> "$bytesPerSec B/s"
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

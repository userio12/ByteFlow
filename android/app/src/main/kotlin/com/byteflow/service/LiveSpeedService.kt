package com.byteflow.service

import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.os.Build
import android.os.IBinder
import androidx.core.content.ContextCompat
import com.byteflow.widget.ByteFlowWidgetProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Android Foreground Service computing real-time download/upload throughput
 * via TrafficStats delta, updating modern status bar notification, and broadcasting to EventChannel.
 * Pauses during screen off for 0.0% CPU overhead.
 */
class LiveSpeedService : Service() {

    companion object {
        const val EXTRA_INTERVAL_MS = "extra_interval_ms"
        const val DEFAULT_INTERVAL_MS = 1000L

        @Volatile
        var isServiceRunning = false
            private set

        @Volatile
        var isPaused = false
            private set

        @Volatile
        private var instance: LiveSpeedService? = null

        @Volatile
        var speedListener: ((downloadBps: Long, uploadBps: Long) -> Unit)? = null

        fun start(context: Context, intervalMs: Long = DEFAULT_INTERVAL_MS) {
            val intent = Intent(context, LiveSpeedService::class.java).apply {
                putExtra(EXTRA_INTERVAL_MS, intervalMs)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, LiveSpeedService::class.java)
            context.stopService(intent)
        }

        fun pauseSampling(context: Context) {
            isPaused = true
            instance?.handlePause()
        }

        fun resumeSampling(context: Context) {
            isPaused = false
            instance?.handleResume()
        }

        fun refreshNotification(context: Context) {
            instance?.updateNotification(instance?.lastRxSpeed ?: 0L, instance?.lastTxSpeed ?: 0L)
        }
    }

    private var samplingIntervalMs: Long = DEFAULT_INTERVAL_MS
    private var samplingJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.Default)

    private var lastRxBytes = 0L
    private var lastTxBytes = 0L
    private var lastTimestampMs = 0L

    var lastRxSpeed = 0L
        private set
    var lastTxSpeed = 0L
        private set

    private lateinit var screenReceiver: ScreenReceiver
    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        instance = this
        isServiceRunning = true
        isPaused = false
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        SpeedNotificationHelper.createNotificationChannel(this)

        try {
            val initialNotification = buildCurrentNotification(0L, 0L)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    SpeedNotificationHelper.NOTIFICATION_ID,
                    initialNotification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(SpeedNotificationHelper.NOTIFICATION_ID, initialNotification)
            }
        } catch (e: Exception) {
            android.util.Log.e("LiveSpeedService", "Error during startForeground: ${e.message}", e)
        }

        try {
            screenReceiver = ScreenReceiver(
                onScreenOff = { stopSampling() },
                onScreenOn = {
                    if (!isPaused) {
                        resetBaseline()
                        startSampling()
                    }
                }
            )
            screenReceiver.register(this)
        } catch (e: Exception) {
            android.util.Log.e("LiveSpeedService", "Error registering screenReceiver: ${e.message}", e)
        }

        resetBaseline()
        startSampling()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        samplingIntervalMs = intent?.getLongExtra(EXTRA_INTERVAL_MS, DEFAULT_INTERVAL_MS) ?: DEFAULT_INTERVAL_MS
        return START_STICKY
    }

    private fun handlePause() {
        stopSampling()
        speedListener?.invoke(0L, 0L)
        updateNotification(0L, 0L)
    }

    private fun handleResume() {
        resetBaseline()
        startSampling()
        updateNotification(lastRxSpeed, lastTxSpeed)
    }

    private fun resetBaseline() {
        lastRxBytes = TrafficStats.getTotalRxBytes()
        lastTxBytes = TrafficStats.getTotalTxBytes()
        lastTimestampMs = System.currentTimeMillis()
    }

    private fun startSampling() {
        if (isPaused) return
        samplingJob?.cancel()
        samplingJob = scope.launch {
            while (isActive) {
                delay(samplingIntervalMs)

                val currentRx = TrafficStats.getTotalRxBytes()
                val currentTx = TrafficStats.getTotalTxBytes()
                val currentTimestamp = System.currentTimeMillis()

                val timeDeltaMs = currentTimestamp - lastTimestampMs
                if (timeDeltaMs > 0 && lastRxBytes >= 0 && lastTxBytes >= 0) {
                    val rxDelta = (currentRx - lastRxBytes).coerceAtLeast(0L)
                    val txDelta = (currentTx - lastTxBytes).coerceAtLeast(0L)

                    val rxSpeedBps = (rxDelta * 1000) / timeDeltaMs
                    val txSpeedBps = (txDelta * 1000) / timeDeltaMs

                    lastRxSpeed = rxSpeedBps
                    lastTxSpeed = txSpeedBps

                    // Broadcast to Flutter EventChannel sink
                    speedListener?.invoke(rxSpeedBps, txSpeedBps)

                    // Update Ongoing Notification
                    updateNotification(rxSpeedBps, txSpeedBps)
                }

                lastRxBytes = currentRx
                lastTxBytes = currentTx
                lastTimestampMs = currentTimestamp
            }
        }
    }

    private fun updateNotification(downloadBps: Long, uploadBps: Long) {
        try {
            val notification = buildCurrentNotification(downloadBps, uploadBps)
            notificationManager.notify(SpeedNotificationHelper.NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            android.util.Log.e("LiveSpeedService", "Failed to update notification: ${e.message}", e)
        }
    }

    private fun buildCurrentNotification(downloadBps: Long, uploadBps: Long): android.app.Notification {
        val widgetPrefs = applicationContext.getSharedPreferences(ByteFlowWidgetProvider.PREF_NAME, Context.MODE_PRIVATE)
        val todayMobile = widgetPrefs.getLong(ByteFlowWidgetProvider.KEY_MOBILE_BYTES, 0L)
        val todayWifi = widgetPrefs.getLong(ByteFlowWidgetProvider.KEY_WIFI_BYTES, 0L)
        val quotaBytes = widgetPrefs.getLong(ByteFlowWidgetProvider.KEY_QUOTA_BYTES, 0L)
        val carrier = widgetPrefs.getString(ByteFlowWidgetProvider.KEY_CARRIER, null)

        val flutterPrefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val useBits = flutterPrefs.getBoolean("flutter.byteflow_speed_unit_bits", false)
        val useDynamicIcon = flutterPrefs.getBoolean("flutter.byteflow_status_bar_speed_icon", true)

        val (networkType, activeCarrier) = getActiveNetworkInfo()

        return SpeedNotificationHelper.buildNotification(
            context = applicationContext,
            downloadBps = downloadBps,
            uploadBps = uploadBps,
            todayMobileBytes = todayMobile,
            todayWifiBytes = todayWifi,
            carrierName = activeCarrier ?: carrier,
            networkType = networkType,
            quotaBytes = quotaBytes,
            isPaused = isPaused,
            useBits = useBits,
            useDynamicIcon = useDynamicIcon
        )
    }

    private fun getActiveNetworkInfo(): Pair<String, String?> {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            val activeNet = cm?.activeNetwork
            val caps = cm?.getNetworkCapabilities(activeNet)
            val isWifi = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            val isCell = caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true

            val widgetPrefs = applicationContext.getSharedPreferences(ByteFlowWidgetProvider.PREF_NAME, Context.MODE_PRIVATE)
            val carrier = widgetPrefs.getString(ByteFlowWidgetProvider.KEY_CARRIER, null)

            val type = when {
                isWifi -> "Wi-Fi"
                isCell -> "Cellular"
                else -> "Active"
            }
            Pair(type, carrier)
        } catch (_: Exception) {
            Pair("Active", null)
        }
    }

    private fun stopSampling() {
        samplingJob?.cancel()
        samplingJob = null
    }

    override fun onDestroy() {
        stopSampling()
        screenReceiver.unregister(this)
        isServiceRunning = false
        isPaused = false
        instance = null
        stopForeground(true)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

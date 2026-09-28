package com.byteflow.network

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import com.byteflow.service.AlertNotificationHelper
import com.byteflow.service.LiveSpeedService
import com.byteflow.widget.ByteFlowWidgetProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Asynchronous Coroutine-backed Platform Channel bridge connecting Flutter to
 * native Android NetworkStatsManager, SubscriptionManager, LiveSpeedService, and AppWidgets.
 * Hardened with complete try/catch error boundaries to guarantee that Flutter MethodChannel
 * futures never hang indefinitely.
 */
class NetworkChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL_NAME = "com.byteflow/network_v1"
        const val SPEED_STREAM_CHANNEL_NAME = "com.byteflow/speed_stream_v1"
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME)
    private val speedEventChannel = EventChannel(messenger, SPEED_STREAM_CHANNEL_NAME)
    private val ioScope = CoroutineScope(Dispatchers.IO)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null

    init {
        methodChannel.setMethodCallHandler(this)
        speedEventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "hasUsagePermission" -> {
                    try {
                        val hasPerm = NetworkStatsHelper.hasUsageStatsPermission(context)
                        result.success(hasPerm)
                    } catch (e: Exception) {
                        result.error("PERMISSION_CHECK_ERROR", e.localizedMessage ?: e.message, null)
                    }
                }
                "requestUsagePermission", "openUsageSettings" -> {
                    try {
                        NetworkStatsHelper.openUsageAccessSettings(context)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_SETTINGS_ERROR", e.localizedMessage ?: e.message, null)
                    }
                }
                "hasPhoneStatePermission" -> {
                    try {
                        val hasPerm = NetworkStatsHelper.hasPhoneStatePermission(context)
                        result.success(hasPerm)
                    } catch (e: Exception) {
                        result.error("PHONE_STATE_ERROR", e.localizedMessage ?: e.message, null)
                    }
                }
                "getSimCards" -> {
                    ioScope.launch {
                        try {
                            val sims = NetworkStatsHelper.getActiveSimCards(context)
                            val serialized = sims.map { it.toMap() }
                            withContext(Dispatchers.Main) {
                                result.success(serialized)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("SIM_QUERY_ERROR", e.localizedMessage ?: e.message, null)
                            }
                        }
                    }
                }
                "getDeviceTotal" -> {
                    val startMs = (call.argument<Number>("startTimeMs"))?.toLong() ?: 0L
                    val endMs = (call.argument<Number>("endTimeMs"))?.toLong() ?: System.currentTimeMillis()

                    ioScope.launch {
                        try {
                            val totals = NetworkStatsHelper.queryDeviceTotal(context, startMs, endMs)
                            withContext(Dispatchers.Main) {
                                result.success(totals.toMap())
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("DEVICE_TOTAL_ERROR", e.localizedMessage ?: e.message, null)
                            }
                        }
                    }
                }
                "getAppsUsage" -> {
                    val networkType = call.argument<Int>("networkType") ?: -1
                    val startMs = (call.argument<Number>("startTimeMs"))?.toLong() ?: 0L
                    val endMs = (call.argument<Number>("endTimeMs"))?.toLong() ?: System.currentTimeMillis()
                    val includeIcons = call.argument<Boolean>("includeIcons") ?: true

                    ioScope.launch {
                        try {
                            val apps = NetworkStatsHelper.queryAppsUsage(
                                context,
                                networkType,
                                startMs,
                                endMs,
                                includeIcons
                            )
                            val serialized = apps.map { it.toMap() }
                            withContext(Dispatchers.Main) {
                                result.success(serialized)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("APPS_USAGE_ERROR", e.localizedMessage ?: e.message, null)
                            }
                        }
                    }
                }
                "getTimeBuckets" -> {
                    val networkType = call.argument<Int>("networkType") ?: 0
                    val startMs = (call.argument<Number>("startTimeMs"))?.toLong() ?: 0L
                    val endMs = (call.argument<Number>("endTimeMs"))?.toLong() ?: System.currentTimeMillis()
                    val stepIntervalMs = (call.argument<Number>("stepIntervalMs"))?.toLong() ?: (3600 * 1000L)

                    ioScope.launch {
                        try {
                            val buckets = NetworkStatsHelper.queryTimeBuckets(
                                context,
                                networkType,
                                startMs,
                                endMs,
                                stepIntervalMs
                            )
                            val serialized = buckets.map { it.toMap() }
                            withContext(Dispatchers.Main) {
                                result.success(serialized)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("TIME_BUCKETS_ERROR", e.localizedMessage ?: e.message, null)
                            }
                        }
                    }
                }
                "startLiveSpeedService" -> {
                    try {
                        val intervalMs = (call.argument<Number>("intervalMs"))?.toLong() ?: 1000L
                        LiveSpeedService.start(context, intervalMs)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_ERROR", e.localizedMessage ?: e.message, null)
                    }
                }
                "stopLiveSpeedService" -> {
                    try {
                        LiveSpeedService.stop(context)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_STOP_ERROR", e.localizedMessage ?: e.message, null)
                    }
                }
                "isLiveSpeedServiceRunning" -> {
                    result.success(LiveSpeedService.isServiceRunning)
                }
                "updateWidgetData" -> {
                    try {
                        val carrier = call.argument<String>("carrier") ?: "ByteFlow"
                        val simBadge = call.argument<String>("simBadge") ?: "SIM 1"
                        val mobileBytes = (call.argument<Number>("mobileBytes"))?.toLong() ?: 0L
                        val wifiBytes = (call.argument<Number>("wifiBytes"))?.toLong() ?: 0L
                        val quotaBytes = (call.argument<Number>("quotaBytes"))?.toLong() ?: 0L
                        val quotaText = call.argument<String>("quotaText") ?: ""

                        ByteFlowWidgetProvider.saveAndRefresh(
                            context,
                            carrier,
                            simBadge,
                            mobileBytes,
                            wifiBytes,
                            quotaBytes,
                            quotaText
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_UPDATE_ERROR", e.localizedMessage ?: e.message, null)
                    }
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (!packageName.isNullOrEmpty()) {
                        try {
                            val intent = context.packageManager.getLaunchIntentForPackage(packageName)
                            if (intent != null) {
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("LAUNCH_APP_ERROR", e.localizedMessage ?: e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "openAppDetails" -> {
                    val packageName = call.argument<String>("packageName")
                    if (!packageName.isNullOrEmpty()) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INTENT_FAILED", e.localizedMessage ?: e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "isIgnoringBatteryOptimizations" -> {
                    try {
                        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && powerManager != null) {
                            powerManager.isIgnoringBatteryOptimizations(context.packageName)
                        } else {
                            true
                        }
                        result.success(isIgnoring)
                    } catch (e: Exception) {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:${context.packageName}")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val fallback = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(fallback)
                                result.success(true)
                            } catch (err: Exception) {
                                result.error("INTENT_FAILED", err.localizedMessage ?: err.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "sendQuotaNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "Data Plan Alert"
                        val body = call.argument<String>("body") ?: ""
                        val isWarning = call.argument<Boolean>("isWarning") ?: true
                        AlertNotificationHelper.sendAlert(context, title, body, isWarning)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.localizedMessage ?: e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("CHANNEL_EXCEPTION", e.localizedMessage ?: e.message, null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        LiveSpeedService.speedListener = { rxSpeed, txSpeed ->
            mainHandler.post {
                eventSink?.success(
                    mapOf(
                        "downloadBps" to rxSpeed,
                        "uploadBps" to txSpeed,
                        "timestampMs" to System.currentTimeMillis()
                    )
                )
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        LiveSpeedService.speedListener = null
        eventSink = null
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        speedEventChannel.setStreamHandler(null)
        LiveSpeedService.speedListener = null
        eventSink = null
    }
}
